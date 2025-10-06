import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class CustomDialog extends StatelessWidget {
  final Widget title;
  final List<Widget> content;
  final List<Widget> actions;

  const CustomDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.w)),
      title: DefaultTextStyle(
        style: Theme.of(context).textTheme.headlineSmall!.copyWith(
          color: Theme.of(context).primaryColor,
        ),
        child: title,
      ),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: content),
      ),
      actionsPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      actions:
          actions
              .map(
                (e) => Padding(
                  padding: EdgeInsets.only(left: 2.w),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    child: e,
                  ),
                ),
              )
              .toList(),
    );
  }
}

Future<T?> showCustomDialog<T>({
  required BuildContext context,
  required Widget title,
  List<Widget>? content,
  List<Widget>? actions,
  Widget Function(BuildContext)? contentBuilder,
  List<Widget> Function(BuildContext)? actionsBuilder,
}) {
  final builtContent =
      content ?? (contentBuilder != null ? [contentBuilder(context)] : []);
  final builtActions =
      actions ?? (actionsBuilder != null ? actionsBuilder(context) : []);

  return showDialog<T>(
    context: context,
    builder:
        (_) => CustomDialog(
          title: title,
          content: builtContent,
          actions: builtActions,
        ),
  );
}

InputDecoration customInputDecoration(String labelText, BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final labelColor =
      isDark ? Colors.white.withAlpha(180) : Colors.black.withAlpha(140);

  return InputDecoration(
    labelText: labelText,
    labelStyle: Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: labelColor),
    filled: true,
    fillColor: Theme.of(context).primaryColor.withAlpha(25),
    contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.8.h),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4.w),
      borderSide: BorderSide(
        color: Theme.of(context).primaryColor,
        width: 0.2.w,
      ),
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
    hintStyle: Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: labelColor),
  );
}
