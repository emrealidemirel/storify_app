import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class ChoiceButton extends StatelessWidget {
  final String buttonText;
  final Color? buttonColor;
  final VoidCallback onPressed;
  const ChoiceButton({
    super.key,
    required this.buttonText,
    required this.onPressed,
    this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 1.h),
      child: SizedBox(
        height: 5.h,
        width: 60.w,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor ?? Theme.of(context).primaryColor,
            padding: EdgeInsets.symmetric(vertical: 0.4.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6.w),
            ),
          ),
          child: Text(
            buttonText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ),
    );
  }
}
