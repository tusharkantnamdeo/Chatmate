import 'package:intl/intl.dart'; // Import at the top
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:messaging_app/data/models/chat_message.dart';
import 'package:messaging_app/data/services/base_repository.dart';
import '../models/user_model.dart';
import '../models/chat_room_model.dart';

class ChatRepository extends BaseRepository{
  CollectionReference get  _chatRooms=> firestore.collection("chatRooms");
  CollectionReference getChatRoomMessage(String chatRoomId){
    return _chatRooms.doc(chatRoomId).collection("messages");
  }

  Future<ChatRoomModel> getOrCreateChatRoom(
     String currentUserId, String otherUserId
      ) async{
       final users = [currentUserId, otherUserId]..sort();
       //currentUserId may be abcd or something and otherUserId may be unique from current like xyz,
       // so by sorting it can be abcdxyz
       final roomId=users.join("_");
       final roomDoc= await _chatRooms.doc(roomId).get();
       if(roomDoc.exists){
         return ChatRoomModel.fromFirestore(roomDoc);
       }
       final currentUserData = (await firestore.collection("users").doc(currentUserId).get()).data() as Map<String, dynamic>;
       final otherUserData = (await firestore.collection("users").doc(otherUserId).get()).data() as Map<String, dynamic>;
       final participantsName = {
         currentUserId:currentUserData['fullName']?.toString()??"",
         otherUserId:otherUserData['fullName']?.toString()??"",
       };

       final newRoom = ChatRoomModel(
           id: roomId,
           participants: users,
           participantsName: participantsName,
           lastReadTime: {
             currentUserId: Timestamp.now(),
             otherUserId: Timestamp.now(),
           },
       );
       await _chatRooms.doc(roomId).set(newRoom.toMap());
       return newRoom;
  }
  Future<void> sendMessage({
       required String chatRoomId,
       required String senderId,
       required String receiverId,
       required String content,
       MessageType type=MessageType.text,
  }) async{
       final batch = firestore.batch();
       //get message subcollection
       final messageRef = getChatRoomMessage(chatRoomId);
       final messageDoc=messageRef.doc();
       final message=ChatMessage(     //chatMessage
           id: messageDoc.id,
           chatRoomId: chatRoomId,
           senderId: senderId,
           receiverId: receiverId,
           content: content,
           type: type,
           timestamp: Timestamp.now(),
           readBy: [senderId],
       );
       batch.set(messageDoc, message.toMap());  // to make a subcollection and want to use ToMap
       batch.update(_chatRooms.doc(chatRoomId), {    //update chatRoom
         "lastMessage":content,
         "lastMessageSenderId":senderId,
         "lastMessageTime":message.timestamp,
       });
       await batch.commit();
  }
  // This is  {DocumentSnapshot? lastDocument} used for showing what is the last document i've already used like seen message
  Stream <List<ChatMessage>> getMessages(String chatRoomId, {DocumentSnapshot? lastDocument}){  //we are creating this as we want data immediately
    var query=getChatRoomMessage(chatRoomId).orderBy('timestamp', descending: true).limit(20);
    if(lastDocument!=null){
      query=query.startAfterDocument(lastDocument);
    }
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList());
  }
//below for this we already have messages but we just need to reload messages
  Future <List<ChatMessage>> getMoreMessages(String chatRoomId, {required DocumentSnapshot lastDocument}) async{  //we are creating this as we want data immediately
    final query=getChatRoomMessage(chatRoomId).orderBy('timestamp', descending: true).startAfterDocument(lastDocument );

    final snapshot = await query.get();
    return snapshot.docs.map((doc)=>ChatMessage.fromFirestore(doc)).toList();
  }//now we here show how to show number of chats in one screen and also who send message recently will show to above
  //for this we have lastMessageTime
  //chatRoom----> participants---> userId---->get---->lastMessageTime
  Stream<List<ChatRoomModel>> getChatRooms(String userId){
    return _chatRooms.where("participants",
        arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots().map((snapshot)=>snapshot
        .docs.map((doc)=>ChatRoomModel.fromFirestore(doc)).toList());
  }
  Stream<int> getUnreadMessageCount(String chatRoomId, String userId){   //to show how many messages no. of unread messages
    return getChatRoomMessage(chatRoomId)
        .where("receiverId", isEqualTo: userId)
        .where('status', isEqualTo: MessageStatus.sent.toString())
        .snapshots()
        .map((snapshot)=>snapshot.docs.length);//We are doing this as we want to change the status in firestore database as any chatroom the status should be changed dynamically as message set then recieved and then seen
  }//this function gives if messages status is not read yet so return number of unread messages
  Future<void> markedMessagesAsRead(String chatRoomId, String userId) async{
    try{ //we need to update our message collection in firebase firestore where it is may status is sent but we need to update to read when user read it
      final batch = firestore.batch();  //is strictly for write operation in firebase
      //get all unread messages where user is reciever

      final unreadMessages = await getChatRoomMessage(chatRoomId)
          .where("receiverId", isEqualTo: userId)
          .where('status', isEqualTo: MessageStatus
          .sent.toString())
          .get();
      //this above line will give how many unreadmessages and once reciever get messages and read than the it updated that no unread messages and update the value for it
      print("found${unreadMessages.docs.length} unread messages");//after getting unread message count
      for(final doc in unreadMessages.docs){
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([userId]),
          'status':MessageStatus.read.toString(),
        }); //and after batch complete than we need to commit
        await batch.commit();
        print("Marked messages as read $userId");  // when click chatlist tile so user read msg so we need to go to chat_cubit.dart and do necess ary changes there
      }
    }catch(e){
      
    }
  }
  Stream<Map<String,dynamic>> getUserOnlineStatus(String userId){
    return firestore.collection("users").doc(userId).snapshots().map((snapshot) {
      final data = snapshot.data();
      return {
        'isOnline':data?['isOnline']??false,
        'lastSeen':data?['lastSeen'],
      };
    });
  }
  Future<void> updateOnlineStatus(String userId, bool isOnline) async{
    await firestore.collection("users").doc(userId).update({
      'isOnline':isOnline,
      'lastSeen':Timestamp.now(), //after this state go to chat_cubit file
    },);
  }
  Future<void> updateTypingStatus(String chatRoomId, String userId, bool isTyping) async{  //now we need to update this in chat_cubit file and create a function _updateTypingStatus
    try{
      final doc=await _chatRooms.doc(chatRoomId).get();
      if(!doc.exists){
        print("chat room does not exists");
        return;
      }
      await _chatRooms.doc(chatRoomId).update({
        'isTyping': isTyping,
        'typingUserId': isTyping?userId:null,
      });
    } catch(e){
      print("error updating typing status");
    }
  }
  Stream<Map<String,dynamic>> getTypingStatus(String userId){
    return _chatRooms.doc(userId).snapshots().map((snapshot) {
      if(!snapshot.exists) {
        return {
          'isTyping':false,
          'isTypingUserId': null,
        };
      }
      final data=snapshot.data() as Map<String, dynamic>;
      return {
        'isTyping': data['isTyping']??false,
        'isTypingUserId':data['isTypingUserId'],
        //at this point we write a code for if once touch any chatListTile it automatically show to oter user
        //to that currentUser and also for currentUser now we need to create function
      };
    });
  }
  Future<void> blockUser(String currentUserId, String blockedUserId) async{ // so for blockedUser we need to go collection and then doc in our firestore database in firebase for blockedUser updation
    final userRef=firestore.collection("users").doc(currentUserId); //we take currentUserId as in the currentUserId there will be blockedUsers list show
    await userRef.update({
      'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
    });
  }
  Future<void> unBlockUser(String currentUserId, String blockedUserId) async{ // so for blockedUser we need to go collection and then doc in our firestore database in firebase for blockedUser updation
    final userRef=firestore.collection("users").doc(currentUserId); //we take currentUserId as in the currentUserId there will be blockedUsers list show
    await userRef.update({
      'blockedUsers': FieldValue.arrayRemove([blockedUserId]),
    });
  }
  Stream<bool> isUserBlocked(String currentUserId, String otherUserId){  //we are using Stream as we want immediate change
    return firestore.collection("users").doc(currentUserId).snapshots().map((doc){
      final userData=UserModel.fromFirestore(doc);
      return userData.blockedUsers.contains(otherUserId);
    });
  }
  Stream<bool> isMeBlocked(String currentUserId, String otherUserId){  //we are using Stream as we want immediate change
    return firestore.collection("users").doc(otherUserId).snapshots().map((doc){
      final userData=UserModel.fromFirestore(doc);
      return userData.blockedUsers.contains(currentUserId );  //Then we go to chat_cubit file and write all these functions
    });
  }
}