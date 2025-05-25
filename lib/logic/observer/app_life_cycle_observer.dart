import 'package:flutter/cupertino.dart';

import '../../data/repositories/chat_repository.dart';

class AppLifeCycleObserver extends WidgetsBindingObserver{ // for everytime i close app i need to do data online and offline
  final String userId;
  final ChatRepository chatRepository;

  AppLifeCycleObserver({required this.userId, required this.chatRepository});
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState
    super.didChangeAppLifecycleState(state);
    switch(state){
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        chatRepository.updateOnlineStatus(userId, false);
        break;
      case AppLifecycleState.resumed:
        chatRepository.updateOnlineStatus(userId, true);
      default:
        break;
    }
  }
}
//we need to wrap this in main.dart file