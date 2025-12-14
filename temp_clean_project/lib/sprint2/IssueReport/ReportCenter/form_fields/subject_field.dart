import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';

class SubjectField extends StatelessWidget {
  final TextEditingController controller;
  final bool hasError;

  const SubjectField({
    super.key,
    required this.controller,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCardBackground : Colors.white;
    final textColor = isDark ? AppColors.darkTextColor : AppColors.lightTextColor;
    final hintColor = isDark ? AppColors.darkHintColor : AppColors.lightHintColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject *',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: hasError
                ? Border.all(color: AppColors.errorColor, width: 1)
                : null,
          ),
          child: TextField(
            controller: controller,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Briefly describe the issue',
              hintStyle: TextStyle(color: hintColor),
              filled: true,
              fillColor: cardBg,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(
                  color: AppColors.accentColor,
                  width: 2,
                ),
              ),
              errorText: hasError ? 'Subject is required' : null,
              errorStyle: const TextStyle(height: 0.8),
              errorMaxLines: 1,
            ),
          ),
        ),
      ],
    );
  }
}