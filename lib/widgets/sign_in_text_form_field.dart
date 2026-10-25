import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      textInputAction: TextInputAction.next,
      autofillHints:
          keyboardType == TextInputType.emailAddress
              ? const [AutofillHints.email]
              : null,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon:
            keyboardType == TextInputType.emailAddress
                ? const Icon(Icons.mail_outline_rounded, size: 20)
                : null,
        suffixIcon: suffixIcon,
      ),
    ),
  );
}
