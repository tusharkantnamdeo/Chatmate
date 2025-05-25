import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget{
  final TextEditingController controller; //userid or password
  final String hintText; // can be used for hint
  final bool? obscureText; //for email input
  final TextInputType? keyboardType; //for email input
  final Widget? prefixIcon; //for email input
  final Widget? suffixIcon; //for password input
  final FocusNode? focusNode;
  final String? Function(String?)? validator; //for email input
  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.obscureText = true,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
    this.validator
  });
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText?? true,
      keyboardType: keyboardType,
      focusNode: focusNode,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }

}