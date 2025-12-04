import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';

class ThemeHelper {
  final BuildContext context;
  late final bool isDark;
  late final Color cardBg;
  late final Color textColor;
  late final Color hintColor;
  late final Color borderColor;
  late final Color inputBg;
  late final Color backgroundColor;

  ThemeHelper(this.context) {
    isDark = Theme.of(context).brightness == Brightness.dark;
    cardBg = isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    textColor = isDark ? AppColors.darkTextColor : AppColors.lightTextColor;
    hintColor = isDark ? AppColors.darkHintColor : AppColors.lightHintColor;
    borderColor = isDark ? AppColors.darkBorderColor : AppColors.lightBorderColor;
    inputBg = isDark ? AppColors.darkInputFillColor : AppColors.lightInputFillColor;
    backgroundColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
  }
}