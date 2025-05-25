import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messaging_app/core/common/custom_text_field.dart';
import 'package:messaging_app/core/common/custom_button.dart';
import 'package:flutter/gestures.dart';
import 'package:messaging_app/core/utils/ui_utils.dart';
import 'package:messaging_app/data/repositories/auth_repository.dart';
import 'package:messaging_app/logic/cubits/auth/auth_cubit.dart';
import 'package:messaging_app/presentation/screens/auth/login_screen.dart';
import '../../../data/services/service_locator.dart';
import '../../../logic/cubits/auth/auth_state.dart';
import '../../../router/app_router.dart';
import '../../home/home_screen.dart';

class SignupScreen extends StatefulWidget{
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>{
  final formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  final _nameFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose(){
    emailController.dispose();
    nameController.dispose();
    usernameController.dispose();
    phoneNumberController.dispose();
    passwordController.dispose();
    _nameFocus.dispose();
    _usernameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }
  String? _validateName(String? value){
    if(value == null || value.isEmpty){
      return 'Please enter your full name';
    }
    return null;
  }
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please Enter your username';
    }
    return null;
  }
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please Enter Your Phone Number';
    }
    final phoneRegex = RegExp(r'^\+?[\d\s-]{10,}$');
    if(!phoneRegex.hasMatch(value)){
      return 'please enter a valid phone number (e.g., +123456789)';
    }
    return null;

  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email cannot be empty';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if(!emailRegex.hasMatch(value)){
      return "Please Enter valid email address (e.g., example@gmail.com)";
    }
    return null;
  }
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password cannot be empty';
    }
    if(value.length<6){
      return "Placement must be at least 6 characters long";
    }
    return null;
  }

  Future<void> handleSignup() async{
    FocusScope.of(context).unfocus();
    if(formKey.currentState?.validate() ?? false){
      try{
        await getIt<AuthCubit>().signUp(
          fullName: nameController.text,
          username: usernameController.text,
          phoneNumber: phoneNumberController.text,
          email: emailController.text,
          password: passwordController.text,);
      } catch(e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString(),),
            )
        );
      }
    } else {
      print("Form Validation Failed");
    }
  }


  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      bloc: getIt<AuthCubit>(),
      listener: (context, state) {
        if(state.status == AuthStatus.authenticated){
          getIt<AppRouter>().pushAndRemoveUntil(
            const HomeScreen(),
          );
        }else if(state.status == AuthStatus.error && state.error != null){
          UiUtils.showSnackBar(context, message: state.error!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(

          ),
          body: SafeArea(
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text('Create Account',
                        style: Theme
                            .of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Text('Please fill the details to continue',
                      style: Theme
                          .of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.grey),),
                    const SizedBox(height: 30),
                    CustomTextField(
                      controller: nameController,
                      hintText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      focusNode: _nameFocus,
                      validator: _validateName,
                      keyboardType: TextInputType.name,
                      obscureText: false,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: usernameController,
                      hintText: 'Username',
                      prefixIcon: const Icon(Icons.alternate_email_outlined),
                      focusNode: _usernameFocus,
                      validator: _validateUsername,
                      keyboardType: TextInputType.name,
                      obscureText: false,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: phoneNumberController,
                      hintText: 'Phonenumber',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      focusNode: _phoneFocus,
                      validator: _validatePhoneNumber,
                      keyboardType: TextInputType.phone,
                      obscureText: false,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: emailController,
                      hintText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      obscureText: false,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: passwordController,
                      obscureText: !_isPasswordVisible,
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      focusNode: _passwordFocus,
                      keyboardType: TextInputType.visiblePassword,
                      validator: _validatePassword,
                      suffixIcon: IconButton(onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      }, icon: Icon(_isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility)),
                    ),
                    const SizedBox(height: 30),
                    CustomButton(onPressed: handleSignup,
                      text: 'Create Account',
                    ),
                    const SizedBox(height: 20),
                    Center(
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an Account?  ',
                            style: TextStyle(color: Colors.grey[600]),
                            children: <TextSpan>[
                              TextSpan(text: 'Login',
                                style: Theme
                                    .of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                    color: Theme
                                        .of(context)
                                        .primaryColor,
                                    fontWeight: FontWeight.bold),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pop(context);
                                  },
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }

}