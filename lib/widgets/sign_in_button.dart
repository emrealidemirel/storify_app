import 'package:flutter/material.dart';

class SignInButton extends StatelessWidget {
  final String buttonText;
  final Color? buttonColor;
  final Color? textColor;
  final Widget? buttonIcon;
  final VoidCallback onPressed;
  const SignInButton({
    super.key,
    required this.buttonText,
    this.buttonColor,
    this.textColor,
    this.buttonIcon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: textColor ?? Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (buttonIcon != null) ...[
            SizedBox(width: 24, height: 24, child: buttonIcon),
            const SizedBox(width: 12),
          ],
          Flexible(child: Text(buttonText, textAlign: TextAlign.center)),
        ],
      ),
    ),
  );
}
