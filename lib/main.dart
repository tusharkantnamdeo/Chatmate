import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messaging_app/config/theme/app_theme.dart';
import 'package:messaging_app/data/repositories/auth_repository.dart';
import 'package:messaging_app/data/repositories/chat_repository.dart';
import 'package:messaging_app/data/services/service_locator.dart';
import 'package:messaging_app/logic/cubits/auth/auth_cubit.dart';
import 'package:messaging_app/logic/cubits/auth/auth_state.dart';
import 'package:messaging_app/logic/observer/app_life_cycle_observer.dart';
import 'package:messaging_app/presentation/home/home_screen.dart';
import 'package:messaging_app/presentation/screens/auth/login_screen.dart';
import 'package:messaging_app/router/app_router.dart';


void main() async {
  await setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLifeCycleObserver _lifeCycleObserver;
@override
   void initState(){  //here we are doing wrapping for ApplifeCycleObserver class
    getIt<AuthCubit>().stream.listen((state){
      if(state.status==AuthStatus.authenticated && state.user!=null){
        _lifeCycleObserver==AppLifeCycleObserver(userId: state.user!.uid, chatRepository: getIt<ChatRepository>());
      }
      WidgetsBinding.instance.addObserver(_lifeCycleObserver);
    });
    super.initState();
   }
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: getIt<AppRouter>().navigatorKey,
        title: 'Messanger App',
        theme: AppTheme.lightTheme,
        home: BlocBuilder<AuthCubit, AuthState>( //const LoginScreen(),
           bloc: getIt<AuthCubit>(),
           builder: (context, state){
             if(state.status==AuthStatus.initial){
               return Scaffold(
                 body: Center(child: CircularProgressIndicator()),
               );
             }
             if(state.status==AuthStatus.authenticated){
               return const HomeScreen();
             }
             return const LoginScreen();
           },
        ),
      ),
    );
  }
}

//base repository
//getit  it is a service locator
//difference in cubit and  bloc
//also when we click middle of the screen so the typing on Textfield must close so we do this task in main.dart
//so we warp MaterialApp with Gesture Detector