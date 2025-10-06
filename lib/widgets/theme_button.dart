import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class ThemeButton extends StatelessWidget {
  final String selectedValue;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const ThemeButton({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 1.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(6.w),
        ),
        height: 5.h,
        width: 60.w,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedValue.isNotEmpty ? selectedValue : null,
            hint: Text(
              "select_option".tr(),
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: Colors.white70),
            ),
            dropdownColor: Theme.of(context).primaryColor,
            iconEnabledColor: Colors.white,
            isExpanded: true,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: Colors.white),
            items: options
                .map(
                  (option) => DropdownMenuItem<String>(
                    value: option,
                    child: Text(option, textAlign: TextAlign.center),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}