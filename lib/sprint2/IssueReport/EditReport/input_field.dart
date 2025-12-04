import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import '.../../theme_helper.dart';

class InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final ThemeHelper theme;

  const InputField({
    super.key,
    required this.label,
    required this.controller,
    this.maxLines = 1,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = maxLines > 1 ? 16.0 : 25.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textColor,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(color: theme.textColor),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: TextStyle(color: theme.hintColor),
              filled: true,
              fillColor: theme.inputBg,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(
                  color: AppColors.accentColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}