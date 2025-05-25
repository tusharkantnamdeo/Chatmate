import 'package:flutter/material.dart';
import 'package:messaging_app/data/repositories/auth_repository.dart';
import 'package:messaging_app/data/repositories/chat_repository.dart';
import 'package:messaging_app/logic/cubits/auth/auth_cubit.dart';
import 'package:messaging_app/presentation/chat/chat_message_screen.dart';
import 'package:messaging_app/presentation/widgets/chat_list_tile.dart';
import '../../data/repositories/contact_repository.dart';
import '../../data/services/service_locator.dart';
import '../../router/app_router.dart';
import '../screens/auth/login_screen.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class HomeScreen extends StatefulWidget{
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
  }
class _HomeScreenState extends State<HomeScreen>{
  late final ContactRepository _contactRepository;
  late final ChatRepository _chatRepository;
  late final _currentUserId;
  @override
  void initState() {
    _contactRepository=getIt<ContactRepository>();
    _chatRepository=getIt<ChatRepository>();
    _currentUserId=getIt<AuthRepository>().currentUser?.uid ?? "";
    super.initState();
  }
  void _showContactsList(BuildContext context){
    showModalBottomSheet(context: context, builder: (context){
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Contacts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _contactRepository.getRegisteredContacts(),
                  builder: (context, snapshot) {
                    if(snapshot.hasError){
                      return Center(
                        child: Text("Error: ${snapshot.error}"),
                      );
                    }
                    if(!snapshot.hasData){
                      return Center(child: const CircularProgressIndicator());
                    }
                    final contacts=snapshot.data!;
                    if(contacts.isEmpty){
                      return Center(child: const Text('No contacts found'));
                    }
                    return ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (context, index){
                        final contact=contacts[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor.withAlpha((0.5*255).toInt()),
                            child: Text(contact["name"][0].toUpperCase()),
                          ),
                          title: Text(contact["name"]),
                          onTap: (){
                            getIt<AppRouter>().push(ChatMessageScreen(receiverId: contact['id'], receiverName: contact['name']));
                          }
                        );
                      }
                    );
                  }
              ),
            )
          ],
        ),
      );  //to show the list of registered user
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
        actions: [
          InkWell(
            onTap: () async{
              await getIt<AuthCubit>().signOut();
              getIt<AppRouter>().pushAndRemoveUntil(const LoginScreen());
            },
            child: const Icon(
                Icons.logout
            ),
          ),
        ],
      ),
      body: StreamBuilder(stream: _chatRepository.getChatRooms(_currentUserId), builder: (context, snapshot) {
        if (_currentUserId.isEmpty) {
          return const Center(child: Text("User not logged in"));
        }
        if(snapshot.hasError){
          print("Firestore Query Error: ${snapshot.error}");  // it check if any chat has appear or not also check
          return Center(child: Text("Error:${snapshot.error}"),);
        }
        if(!snapshot.hasData){   // it means it loading the chat
          return const Center(child: CircularProgressIndicator());
        }
        final chats = snapshot.data!
            .where((chat) =>
        chat.participants.any((id) => id != _currentUserId) &&
            chat.participantsName != null)
            .toList();
        print("Chats Loaded: ${chats.length}");
        if(chats.isEmpty){
          return const Center(
            child: Text("No recent chats"),    //we did this if anything is good but no one yet do chat with you
          );
        }
        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index){
            final chat=chats[index];
            print("Chat: ${chat.toString()}");
            return ChatListTile(
                chat: chat,        //also we need to register ChatRepository in service_locator file
                currentUserId: _currentUserId,
                onTap: (){
                  final otherUserId = chat.participants.firstWhere(
                        (id) => id != _currentUserId,
                    orElse: () => "", // Prevents crashes if no other user is found
                  );

                  final otherUserName=chat.participantsName![otherUserId] ?? "Unknown user";
                  getIt<AppRouter>().push(ChatMessageScreen(receiverId: otherUserId, receiverName: otherUserName));
                },
            );
          }
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showContactsList(context),
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

}


// in app it can be give an error, error:[cloud_firestore-precondition] The query requires an index.
//You can create it here: so we need to go to our firbase account which configured with this and then once we got
// Then we have to create there index, why this need as let say 1000 user but we have only need with those user where our id is present
// so we need to create index. Index is useful method as it use to find user with present our id.