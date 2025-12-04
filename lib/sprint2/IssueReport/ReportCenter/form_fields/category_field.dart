import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';

class CategoryField extends StatelessWidget {
  final String? selectedCategory;
  final Function(String?) onCategoryChanged;
  final bool hasError;

  const CategoryField({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCardBackground : Colors.white;
    final textColor = isDark ? AppColors.darkTextColor : AppColors.lightTextColor;
    final hintColor = isDark ? AppColors.darkHintColor : AppColors.lightHintColor;

    final List<String> categories = [
      'Bug or Technical Issue',
      'Inappropriate Content',
      'Item Misrepresentation',
      'Account or Security Concern',
      'Feature Suggestion',
      'Other',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category *',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            value: selectedCategory,
            hint: Text(
              'Select a category',
              style: TextStyle(color: hintColor),
            ),
            items: categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(
                  category,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                  ),
                ),
              );
            }).toList(),
            onChanged: onCategoryChanged,
            borderRadius: BorderRadius.circular(25),
            isExpanded: true,
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              'Please select a category',
              style: TextStyle(
                color: AppColors.errorColor,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}