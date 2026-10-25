import 'package:flutter/material.dart';

class ChoiceButton extends StatelessWidget {
  final String buttonText;
  final Color? buttonColor;
  final VoidCallback? onPressed;
  const ChoiceButton({
    super.key,
    required this.buttonText,
    required this.onPressed,
    this.buttonColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
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
