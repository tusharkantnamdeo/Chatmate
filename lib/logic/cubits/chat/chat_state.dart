import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:messaging_app/data/models/chat_message.dart';

enum ChatStatus{
  initial,
  loading,
  loaded,
  error,
}
class ChatState extends Equatable{
  final ChatStatus status;
  final String? error;
  final String? receiverId;
  final String? chatRoomId;
  final List<ChatMessage> messages;
  final bool isReceiverTyping;
  final bool isReceiverOnline;
  final bool? hasMoreMessages;
  final Timestamp? receiverLastSeen;
  final bool isLoadingMore;
  final bool isUserBlocked;
  final bool isMeBlocked;

  const ChatState(
      {
        this.status=ChatStatus.initial,
        this.error,
        this.receiverId,
        this.chatRoomId,
        this.messages = const [],
        this.isReceiverTyping = false,
        this.isReceiverOnline = false,
        this.hasMoreMessages = true,
        this.receiverLastSeen,
        this.isLoadingMore = false,
        this.isUserBlocked = false,
        this.isMeBlocked = false,
      });
  ChatState copyWith({
    ChatStatus? status,
    String? error,
    String? receiverId,
    String? chatRoomId,
    List<ChatMessage>? messages,
    bool? isReceiverTyping,
    bool? isReceiverOnline,
    bool? hasMoreMessages,
    Timestamp? receiverLastSeen,
    bool? isLoadingMore,
    bool? isUserBlocked,
    bool? isMeBlocked,
  }) {
    return ChatState(
      status: status ?? this.status,
      error: error ?? this.error,
      receiverId: receiverId ?? this.receiverId,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      messages: messages ?? this.messages,
      isReceiverOnline: isReceiverOnline ?? this.isReceiverOnline,
      isReceiverTyping: isReceiverTyping ?? this.isReceiverTyping,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      receiverLastSeen: receiverLastSeen ?? this.receiverLastSeen,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isUserBlocked: isUserBlocked ?? this.isUserBlocked,
      isMeBlocked: isMeBlocked ?? this.isMeBlocked,
    );
  }
  @override
  List<Object?> get props => [
    status,
    error,
    receiverId,
    chatRoomId,
    messages,
    isReceiverTyping,
    isReceiverOnline,
    hasMoreMessages,
    receiverLastSeen,
    isLoadingMore,
    isUserBlocked,
    isMeBlocked,
  ];
}
