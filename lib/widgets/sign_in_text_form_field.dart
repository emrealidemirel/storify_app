import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class SignInTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String labelText;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;

  const SignInTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 85.w,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: Theme.of(context).textTheme.bodyMedium,
          filled: true,
          fillColor: Theme.of(context).primaryColor.withAlpha(25),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 3.w,
            vertical: 1.8.h,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4.w),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 0.2.w,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4.w),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 0.2.w,
            ),
          ),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
