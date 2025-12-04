// ============================================
// FILE 3: lib/accounts/profile/widgets/empty_states.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? AppColors.darkHintColor : AppColors.lightHintColor;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: hintColor.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: hintColor,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginRequiredState extends StatelessWidget {
  final VoidCallback onRetry;

  const LoginRequiredState({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextColor : AppColors.lightTextColor;
    final hintColor = isDark ? AppColors.darkHintColor : AppColors.lightHintColor;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.login,
            size: 80,
            color: hintColor.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Login Required',
            style: TextStyle(
              fontSize: 18,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please log in to view your reports',
            style: TextStyle(
              fontSize: 14,
              color: hintColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyReportsState extends StatelessWidget {
  final VoidCallback onCreateReport;

  const EmptyReportsState({
    super.key,
    required this.onCreateReport,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkTextColor : AppColors.lightTextColor;
    final hintColor = isDark ? AppColors.darkHintColor : AppColors.lightHintColor;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: hintColor.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'No reports yet',
            style: TextStyle(
              fontSize: 18,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your submitted reports will appear here',
            style: TextStyle(
              fontSize: 14,
              color: hintColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onCreateReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Submit Your First Report',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}