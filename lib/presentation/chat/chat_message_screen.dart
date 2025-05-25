import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:messaging_app/logic/cubits/chat/chat_state.dart';
import 'package:messaging_app/presentation/widgets/loading_dots.dart';
import '../../data/models/chat_message.dart';
import '../../data/services/service_locator.dart';
import '../../logic/cubits/chat/chat_cubit.dart';
import 'package:messaging_app/data/models/chat_message.dart';
class ChatMessageScreen extends StatefulWidget{
  final String receiverId;
  final String receiverName;

  const ChatMessageScreen({super.key, required this.receiverId, required this.receiverName});

  @override
  State<ChatMessageScreen> createState() => _ChatMessageScreenState();

}
class _ChatMessageScreenState extends State<ChatMessageScreen>{
  final TextEditingController messageController = TextEditingController();
  late final ChatCubit _chatCubit;
  final _scrollController=ScrollController();
  List<ChatMessage> _previousMessages = [];  //that will check previous messages
  bool _isComposing = false; //now what happened is when we will using typing controller so it will update
  // _iscomposing value from false to true and also update the status of typing to all users
  bool _showEmoji = false; //we go to send button and there we make changes for emoji picker as we already installed that package
  @override
  void initState(){
    _chatCubit = getIt<ChatCubit>();
    print("receiver id ${widget.receiverId}");
    _chatCubit.enterChat(widget.receiverId);
    messageController.addListener(_onTextChanged); //we need to show typing when text changed means user typing
    _scrollController.addListener(_onScroll);
    super.initState();
  }

  void _onScroll(){
    //load more messages when reaching to top
    if(_scrollController.position.pixels>=_scrollController.position.maxScrollExtent-200){
      _chatCubit.loadMoreMessages();
    }
  }

  Future<void> _handleSendMessage() async{
    final messageText = messageController.text.trim();
    if (messageText.isEmpty) return;

    await _chatCubit.sendMessage(content: messageText, receiverId: widget.receiverId);
    messageController.clear();
    setState(() {});
  }
  void _onTextChanged(){
    final isComposing = messageController.text.isNotEmpty;
    if(isComposing!=_isComposing){
      setState(() {
        _isComposing = isComposing; //before this we have done changes in chat_cubit file and chat_repository  file where i write function for _updateTypingStatus
        _chatCubit.startTyping();
      });

    }
  }
  void _scrollToBottom(){   //we have done this for whenever we put new message so it shows it below automatically
    if(_scrollController.hasClients){
      _scrollController.animateTo(0, duration: Duration(microseconds: 300), curve: Curves.easeOut);
    }
  }
  void hasNewMessages(List<ChatMessage> messages){
    if(messages.length!=_previousMessages.length){
      _scrollToBottom();
      _previousMessages=messages;
    }
  }
  @override
  void dispose() {
    messageController.dispose();
    _scrollController.dispose();
    _chatCubit.leaveChat();
    _chatCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.5),
              child: Text(widget.receiverName[0].toUpperCase()),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.receiverName),
                BlocBuilder<ChatCubit, ChatState>(
                  bloc: _chatCubit, //have made changes here before it was this getIt<ChatCubit>(),
                  // but we have already initialized above
                  //now for isTyping we need to go to chat_message_screen file and there we need to do composing
                  builder: (context, state) {
                    if(state.isReceiverTyping){
                      return Row(
                        children: [
                          Container(
                            margin: EdgeInsets.only(right: 4),
                            child: Text("Typing", style: TextStyle(color: Theme.of(context).primaryColor)),
                          ),
                          LoadingDots(),
                        ],
                      );
                    }
                    if(state.isReceiverOnline){
                      return Text("Online", style: TextStyle(fontSize: 14, color: Colors.green),);
                    }
                    if(state.receiverLastSeen!=null){
                      final lastSeen=state.receiverLastSeen!.toDate();
                      return Text("last seen at ${DateFormat('h:mm a').format(lastSeen)}", style: TextStyle(color: Colors.grey[600]),);
                    }
                    return const SizedBox();
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          BlocBuilder<ChatCubit, ChatState>(
            bloc: _chatCubit,
            builder: (context, state) {
              if(state.isUserBlocked){
                return TextButton.icon(
                    onPressed: () => _chatCubit.unBlockUser(widget.receiverId),
                    label: const Text('Unblock'),
                    icon: Icon(Icons.block),
                );
              }
              return PopupMenuButton<String>(
                icon: Icon(Icons.more_vert),
                onSelected: (value)async{
                  if(value=="block"){
                    final bool? confirm = await showDialog<bool>(context: context, builder: (context)=>AlertDialog(
                      title: Text("Are you sure you want to block ${widget.receiverName}"), //here i make ui for block any other user by current user
                      actions: [
                        TextButton(
                          onPressed: (){
                            Navigator.pop(context);  //we used here Navigator as we have here context that's why
                            // i don't use here the method to moving to other page like what i did for other pages
                            //as i used getIt for this purpose
                          },
                          child: Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: ()=>Navigator.pop(context, true),
                          child: Text('Block',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),);
                    if(confirm==true){
                      await _chatCubit.blockUser(widget.receiverId);
                    }
                  }
                },
                itemBuilder: (context)=><PopupMenuEntry<String>>[
                  const PopupMenuItem(
                    value: 'block',
                    child: Text("Block User")
                  ),  //all i have done here for block any user
                 //from here now i need to check is otheruser is blocked currentuser(isMeBlocked) for which  i make ui above listview.builder
                ]);
            }
          )
        ],
      ),
      body: BlocConsumer<ChatCubit, ChatState>(  //i have assign BlockConsumer in place of BlocBuilder for assign hasNewMessages
        listener: (context, state){
          hasNewMessages(state.messages); //we need to make hasMoreMessages in chat_state file
          //now last thing for make emoji icon working it is done by doing some changes in chat_message_screen
          //for that we need to install one package which is called emoji_picker_flutter in our system by command flutter pub add emoji_picker_flutter file
        },
        bloc: _chatCubit,
        builder: (context, state){
          print("Chat State Updated: ${state.messages.length} messages found");
          if(state.status==ChatStatus.loading){
            return Center(child: const CircularProgressIndicator());
          }
          if(state.status==ChatStatus.error){
            return Center(
              child: Text(state.error??"Something Went wrong"), // here is the error as it not returning this
            );
          }
          //  Sorting messages by timestamp before displaying
          List<ChatMessage> sortedMessages = List.from(state.messages);
          sortedMessages.sort((a, b) => (b.timestamp ?? Timestamp.now()).compareTo(a.timestamp ?? Timestamp.now()));

          return Column(
            children: [
              if(state.isMeBlocked)
              Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.withOpacity(0.1),
                  child: Text('You have been blocked by this ${widget.receiverName}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red)
              )),
              // i have done this above for showing that isMeblocked by this user(receiver)
              Expanded(
                child: ListView.builder(   //we here show message bubble means we will show here real time data
                    controller: _scrollController, //for doing scrolling in the screen
                    reverse: true,
                    itemCount: sortedMessages.length,//state.messages.length,
                    // i got it the error is in this line itemcount as the comment above has previous written
                    // line which cause an error as it is not showing messages also
                    itemBuilder: (context, index){
                      final message = sortedMessages[index];  //state.messages[index]; //what messages will be come
                      //error is here which causing an error as in this line the error is the
                      // above written line in comment which not updating messages and print also in
                      final isMe = message.senderId == _chatCubit.currentUserId;
                      return MessageBubble(message: message, isMe: isMe,);
                    }
                ),
              ),
              if(!state.isMeBlocked && !state.isUserBlocked)       //means is user is blocked than can't user TextField
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: (){
                            setState(() {
                              _showEmoji=!_showEmoji;
                              if(_showEmoji){
                                FocusScope.of(context).unfocus();
                              }
                            });
                          },
                          icon: const Icon(Icons.emoji_emotions),
                        ),

                        SizedBox(width: 8),

                        Expanded(
                          child : TextField(
                              onTap: (){
                                if(_showEmoji){  //we have doing this as emoji opened before and user want to write so it simply touch the textfield it will unfocus
                                  setState(() {
                                    _showEmoji = false;
                                  });
                                } // now after this i make this it's Ui
                                setState(() {
                                  _showEmoji=!_showEmoji;
                                  if(_showEmoji){
                                    FocusScope.of(context).unfocus();
                                  }
                                });
                              },
                              controller: messageController,
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,

                              decoration: InputDecoration(
                                hintText: "Type a Message",
                                filled: true,
                                fillColor: Theme.of(context).cardColor,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8,),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),

                              )
                          ),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                            onPressed: _isComposing? _handleSendMessage: null, // it send message only when anyone have anyone have written something.
                            icon: Icon(
                              Icons.send,
                              color: _isComposing? Theme.of(context).primaryColor: Colors.grey,
                            )
                        ),
                      ],
                    ),
                    if (_showEmoji) // i add some line for emoji picker ui from this line : 294 to line no. - 345
                      SizedBox(
                        height: 250,
                        child: EmojiPicker(
                          textEditingController: messageController,
                          onEmojiSelected: (category, emoji) {
                            messageController
                              ..text += emoji.emoji
                              ..selection = TextSelection.fromPosition(
                                TextPosition(
                                    offset: messageController.text.length),
                              );
                            setState(() {
                              _isComposing =
                                  messageController.text.isNotEmpty;
                            });
                          },
                          config: Config(
                            height: 250,
                            emojiViewConfig: EmojiViewConfig(
                              columns: 7,
                              emojiSizeMax:
                              32.0 * (Platform.isIOS ? 1.30 : 1.0),
                              verticalSpacing: 0,
                              horizontalSpacing: 0,
                              gridPadding: EdgeInsets.zero,
                              backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                              loadingIndicator: const SizedBox.shrink(),
                            ),
                            categoryViewConfig: const CategoryViewConfig(
                              initCategory: Category.RECENT,
                            ),
                            bottomActionBarConfig: BottomActionBarConfig(
                              enabled: true,
                              backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                              buttonColor: Theme.of(context).primaryColor,
                            ),
                            skinToneConfig: const SkinToneConfig(
                              enabled: true,
                              dialogBackgroundColor: Colors.white,
                              indicatorColor: Colors.grey,
                            ),
                            searchViewConfig: SearchViewConfig(
                              backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                              buttonIconColor: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
class MessageBubble extends StatelessWidget{
  final ChatMessage message;
  final bool isMe;  //to find this is me
  //final bool showTime;
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    //required this.showTime
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(left: isMe?64:8, right: isMe?8:64, bottom: isMe?4:0),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).primaryColor
              : Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),

        ),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(message.content, style: TextStyle(color: isMe ? Colors.white : Colors.black)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(DateFormat('h:mm a').format(message.timestamp!.toDate()),
                    style: TextStyle(color: isMe ? Colors.white : Colors.black)),
                //till this stage user can send message after signup and login and recieve message
                // and also we see msg status change in UI as well as in firebase and also it also we are created firestore
                // and index also created now after this move to emoji section
                if(isMe)
                  ...[ //at  this point of stage all things done now do for showing user is online or not and
                    // last seen also and so for that we need to go to chat_repository file
                    SizedBox(width: 4,),
                    Icon(Icons.done_all,
                      size: 12,
                      color: message.status==MessageStatus.read
                          ? Colors.blue : Colors.white70,
                    ),
                  ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}