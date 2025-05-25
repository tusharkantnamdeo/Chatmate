import 'package:flutter/material.dart';
import 'package:messaging_app/data/models/chat_room_model.dart';
import 'package:messaging_app/data/repositories/chat_repository.dart';
import 'package:messaging_app/data/services/service_locator.dart';

class ChatListTile extends StatelessWidget{
  final ChatRoomModel chat;
  final String currentUserId;
  final VoidCallback onTap;

  const ChatListTile({
    super.key,
    required this.chat,     //creted constructor for above fields
    required this.currentUserId,
    required this.onTap});

  String _getOtherUsername(){
    final otherUserId=chat.participants.firstWhere((id)=>id!=currentUserId); //that will give other user id which we are wanted in our bove folder
    return chat.participantsName?[otherUserId] ?? "Unknown User";
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),   //here we need to show that persons listile who have sent message recently
        child: Text(_getOtherUsername()[0].toUpperCase())
      ),
      title: Text(
        _getOtherUsername(), style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Row(
        children: [
          Expanded(
              child: Text(
                  chat.lastMessage ?? "",
                  maxLines: 1,  //message can be big and if overflow
                  overflow: TextOverflow.ellipsis, // so it will do what it shows  ' ....' if message is big
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
              ),
          ),
        ],
      ),
      trailing: StreamBuilder<int>(stream: getIt<ChatRepository>().getUnreadMessageCount(chat.id, currentUserId), builder: (context, snapshot){
        if(!snapshot.hasData || snapshot.data==0){
          return const SizedBox();
        }
        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          child: Text(
            snapshot.data.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        );
      },),
    );

  }

}