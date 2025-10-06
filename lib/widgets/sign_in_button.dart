import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

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
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 1.h),
      child: SizedBox(
        height: 5.h,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(6.w)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buttonIcon ?? const SizedBox(),
              Text(
                buttonText,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium!.copyWith(color: textColor),
              ),
              const SizedBox(),
            ],
          ),
        ),
      ),
    );
  }
}
