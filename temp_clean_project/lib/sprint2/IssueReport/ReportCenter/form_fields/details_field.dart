import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';

class DetailsField extends StatelessWidget {
  final TextEditingController controller;
  final bool hasError;

  const DetailsField({
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
          'Details *',
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
            borderRadius: BorderRadius.circular(16),
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
            maxLines: 6,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: 'Provide as much detail as possible...',
              hintStyle: TextStyle(color: hintColor),
              contentPadding: const EdgeInsets.all(16),
              filled: true,
              fillColor: cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.accentColor,
                  width: 2,
                ),
              ),
              errorText: hasError ? 'Details are required' : null,
              errorStyle: const TextStyle(height: 0.8),
              errorMaxLines: 1,
            ),
          ),
        ),
      ],
    );
  }
}