import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:easy_localization/easy_localization.dart';

class PasswordTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final bool? autoValidate;
  final String? Function(String?)? customValidator;

  const PasswordTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.autoValidate,
    this.customValidator,
  });

  @override
  State<PasswordTextFormField> createState() => _PasswordTextFormFieldState();
}

class _PasswordTextFormFieldState extends State<PasswordTextFormField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 85.w,
      child: TextFormField(
        controller: widget.controller,
        obscureText: _obscure,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: widget.labelText,
          labelStyle: Theme.of(context).textTheme.bodyMedium,
          filled: true,
          fillColor: Theme.of(context).primaryColor.withAlpha(25),
          contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.8.h),
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
          suffixIcon: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey.shade600,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        validator: widget.customValidator ??
            (value) {
              if (value == null || value.isEmpty) {
                return 'password_empty_error'.tr();
              }
              if (value.length < 6) {
                return 'password_length_error'.tr();
              }
              return null;
            },
        autovalidateMode: widget.autoValidate == true
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
      ),
    );
  }
}