import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:messaging_app/router/app_router.dart';
import '../../firebase_options.dart';
import '../../logic/cubits/auth/auth_cubit.dart';
import '../../logic/cubits/chat/chat_cubit.dart';
import '../repositories/auth_repository.dart';
import '../repositories/chat_repository.dart';
import '../repositories/contact_repository.dart';

final getIt = GetIt.instance;  //global variable

Future<void> setupServiceLocator() async{   //global function
  WidgetsFlutterBinding.ensureInitialized(); //necessary line as it ensure initialization with flutter otherwise it will not show any screen of your project
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  getIt.registerLazySingleton(() => AppRouter());
  getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton(() => AuthRepository());
  getIt.registerLazySingleton(() => ContactRepository());
  getIt.registerLazySingleton(() => ChatRepository());   // to register ChatRepository
  getIt.registerLazySingleton(
          () => AuthCubit(
            authRepository: AuthRepository(),
          ),   //means it is not immediately call
  );

  getIt.registerFactory(
        () => ChatCubit(
              currentUserId:getIt<FirebaseAuth>().currentUser!.uid,
              chatRepository: ChatRepository(),
    ),   //means it is not immediately call
  );

}