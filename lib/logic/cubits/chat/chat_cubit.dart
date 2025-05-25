import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messaging_app/data/models/chat_message.dart';
import 'package:messaging_app/logic/cubits/auth/auth_cubit.dart';
import '../../../data/repositories/chat_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState>{
  final ChatRepository _chatRepository;
  final String currentUserId;
  bool _isInChat=false;
  StreamSubscription? _messageSubscription; //messages will stream of subscription cause it will come real time and it will give new messages
  StreamSubscription? _onlineStatusSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _blockStatusSubscription;
  StreamSubscription? _isMeBlockStatusSubscription;
  Timer? typingTimer;  //for showing typing status to receiver now we make function which will then call in chat_message_screen file
  ChatCubit({
    required ChatRepository chatRepository,
    required this.currentUserId
  }) : _chatRepository = chatRepository,
        super(const ChatState());
  void enterChat(String receiverId,) async{
    _isInChat: true;
    emit(state.copyWith(status: ChatStatus.loading));
    try{
      final chatRoom=await _chatRepository.getOrCreateChatRoom(currentUserId, receiverId);
      emit(state.copyWith(
        chatRoomId: chatRoom.id,
        receiverId: receiverId,
        status: ChatStatus.loaded,
      ));
      //subscribe to all updates
      _subscribeToMessages(chatRoom.id);
      _subscribeToOnlineStatus(receiverId);
      _subscribeToTypingStatus(chatRoom.id); //we also need 1 simulator and 1 emulator
      _subscribeToBlockStatus(receiverId);

      await _chatRepository.updateOnlineStatus(currentUserId, true);
    }catch(e){
      emit(state.copyWith(status: ChatStatus.error, error: "Failed to create chat room $e"));
    }
  }
  Future<void> sendMessage(
      {required String content, required String receiverId}
  ) async{
    if(state.chatRoomId==null) return;
    try{
      await _chatRepository.sendMessage(
          chatRoomId: state.chatRoomId!,
          senderId: currentUserId,
          receiverId: receiverId,
          content: content
      );
    }catch(e){
      log(e.toString()); //for this we have to import one library called dart:developer
      emit(state.copyWith(error: "Failed to send message"));
    }
  }

  Future<void> loadMoreMessages() async{  // we need to bing this function so we then go to chat_message_screen file
    if(state.status!=ChatStatus.loaded ||
        state.messages.isEmpty ||
        !(state.hasMoreMessages ?? false) ||
        state.isLoadingMore) return;
    try{
      emit(state.copyWith(isLoadingMore: true));

      final lastMessage=state.messages.last; // by this i'll get my last message
      final lastDoc = await _chatRepository
          .getChatRoomMessage(state.chatRoomId!)
          .doc(lastMessage.id)
          .get();
      final moreMessages=await _chatRepository
          .getMoreMessages(state
          .chatRoomId!,
          lastDocument: lastDoc); //to get more messages
      if(moreMessages.isEmpty){
        emit(state.copyWith(hasMoreMessages: false, isLoadingMore: false));
        return;
      }
      emit(state.copyWith(
        messages: [...state.messages, ...moreMessages],  //combine new messages and  already exists messages.
        hasMoreMessages: moreMessages.length>=20,
        isLoadingMore: false,
      ));
    } catch(e){
      emit(state.copyWith(
        error: "Failed to load more messages", isLoadingMore: false,
      ));
    }
  }
  void _subscribeToMessages(String chatRoomId){
    _messageSubscription?.cancel();  //if it running so cancel it
    _messageSubscription=_chatRepository.getMessages(chatRoomId).listen((messages){
      if(_isInChat){
        _markMessageAsRead(chatRoomId);
      }
      emit(state.copyWith(
          messages: messages, error: null
      ));
    }, onError: (error){
      emit(state.copyWith(status: ChatStatus.error, error: "Failed to load messages"));
    }); //do fill message from where so it is defined in this line
  }

  void _subscribeToOnlineStatus(String userId){
    _onlineStatusSubscription?.cancel();
    _onlineStatusSubscription =
        _chatRepository.getUserOnlineStatus(userId).listen((status){
          final isOnline=status["isOnline"] as bool;
          final lastSeen=status["lastSeen"] as Timestamp?;
          emit(state.copyWith(
            isReceiverOnline: isOnline,
            receiverLastSeen: lastSeen,
          ),);   //we want here receiver isOnline and receiver lastSeen so go to chat_state.dart
        },
        onError: (error){
          print("Error getting online status");
        },
    );
  }
  void _subscribeToTypingStatus(String chatRoomId){
    _typingSubscription?.cancel();
    _typingSubscription =
        _chatRepository.getTypingStatus(chatRoomId).listen((status){
          final isTyping=status["isTyping"] as bool;
          final typingUserId=status["typingUserId"] as String?;
          emit(state.copyWith(
            isReceiverTyping: isTyping && typingUserId!=currentUserId,),

          );   //we want here receiver isOnline and receiver lastSeen so go to chat_state.dart
        },
          onError: (error){
            print("Error getting online status");
          },
        );
  }
  void _subscribeToBlockStatus(String otherUserId) {
    _blockStatusSubscription?.cancel();
    _blockStatusSubscription = _chatRepository
        .isUserBlocked(currentUserId, otherUserId)
        .listen((isBlocked) {
      emit(
        state.copyWith(isUserBlocked: isBlocked),
      );

      _isMeBlockStatusSubscription?.cancel();
      _blockStatusSubscription = _chatRepository
          .isMeBlocked(currentUserId, otherUserId)
          .listen((isBlocked) {
        emit(
          state.copyWith(isMeBlocked: isBlocked),
        );
      });
    }, onError: (error) {
      print("error getting online status");
    });
  }


  void startTyping(){ // then we have put this where chat_message_screen
    if(state.chatRoomId==null) return;
    typingTimer?.cancel(); //we need to create a function for updating typing message
    _updateTypingStatus(true);
    typingTimer = Timer(Duration(seconds: 3), (){
      _updateTypingStatus(false);
    });
  }
  Future<void> _updateTypingStatus(bool isTyping) async{
    if(state.chatRoomId ==  null) return;
    //we need to create function or updateTypingStatus so we need to go to chat_repository file
    // and there we will create updateOnlineStatus like function for updateTypingStatus
    try {
      await _chatRepository.updateTypingStatus(state.chatRoomId!, currentUserId, isTyping);
    }
    catch(e){
      print("error updating typing status$e");
    }
  }

  Future<void> blockUser(String userId) async{
    try{
      await _chatRepository.blockUser(currentUserId, userId);
    }catch(e){
      emit(state.copyWith(error: 'failed to block user $e',));
    }
  }
  Future<void> unBlockUser(String userId) async{
    try{
      await _chatRepository.unBlockUser(currentUserId, userId);
    }catch(e){
      emit(state.copyWith(error: 'failed to unblock user $e',));
    }
  }

  Future<void> _markMessageAsRead(String chatRoomId) async{
    try{
      await _chatRepository.markedMessagesAsRead(chatRoomId, currentUserId);
    }catch(e){
      print('error marking messages as read $e');
    }
  }
  Future<void> leaveChat() async{
    if (state.chatRoomId != null) {
      await _markMessageAsRead(state.chatRoomId!);
    }
    _isInChat=false;
  }
} //also we need to add one more library i.e. intl which is done by flutter pub add intl which is used for dateformatting