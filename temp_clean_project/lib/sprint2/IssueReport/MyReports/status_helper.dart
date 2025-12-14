// ============================================
// FILE 5: lib/utils/status_helper.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';

class StatusHelper {
  static Color getColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in progress':
      case 'in-progress':
        return Colors.blue;
      case 'resolved':
        return AppColors.successColor;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}