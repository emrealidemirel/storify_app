import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String buttonText;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry? padding;
  final Color? buttonColor;
  const PrimaryButton({
    super.key,
    required this.buttonText,
    required this.onPressed,
    this.padding,
    this.buttonColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding ?? const EdgeInsets.symmetric(vertical: 6),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
        child: Text(buttonText, textAlign: TextAlign.center),
      ),
    ),
  );
}
