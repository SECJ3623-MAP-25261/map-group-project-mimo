// lib/sprint2/Booking/widgets/date_selection_field.dart

import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';

class DateSelectionField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final bool isStart;
  final Function(bool isStart) onDateSelected;

  const DateSelectionField({
    super.key,
    required this.label,
    required this.date,
    required this.isStart,
    required this.onDateSelected,
  });

  String get _formattedDate {
    if (date == null) return 'dd/mm/yyyy';
    return '${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.lightTextColor,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => onDateSelected(isStart),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.lightInputFillColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.lightBorderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formattedDate,
                  style: TextStyle(
                    color: date == null
                        ? AppColors.lightHintColor
                        : AppColors.lightTextColor,
                    fontSize: 16,
                  ),
                ),
                const Icon(Icons.calendar_today,
                    size: 20, color: AppColors.lightHintColor),
              ],
            ),
          ),
        ),
      ],
    );
  }
}