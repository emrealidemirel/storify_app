import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

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
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.symmetric(horizontal: 10.w, vertical: 1.h),
      child: SizedBox(
        height: 6.h,
        width: 60.w,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor ?? Theme.of(context).primaryColor,
            padding: EdgeInsets.symmetric(vertical: 1.4.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.w),
            ),
          ),
          child: Text(buttonText, style: Theme.of(context).textTheme.labelLarge),
        ),
      ),
    );
  }
}
