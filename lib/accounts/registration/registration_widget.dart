import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Header widget for registration screen
class RegistrationHeader extends StatelessWidget {
  const RegistrationHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Account Registration',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.lightTextColor,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Create your account to start renting and listing!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.lightHintColor,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

/// Role change information widget
class RoleChangeInfo extends StatelessWidget {
  const RoleChangeInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accentColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentColor.withOpacity(0.5),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info, size: 18, color: AppColors.accentColor),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flexible Role Selection',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentColor,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'You start as a renter, but can easily switch to a lister role anytime in your profile settings.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.lightHintColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Guest mode toggle widget
class GuestModeToggle extends StatelessWidget {
  final bool isGuestMode;
  final VoidCallback onToggle;

  const GuestModeToggle({
    super.key,
    required this.isGuestMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightBackground.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue as Guest',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightTextColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Limited features (viewing only) available.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.lightHintColor,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 48,
              height: 24,
              decoration: BoxDecoration(
                color: isGuestMode ? AppColors.accentColor : AppColors.lightBorderColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: isGuestMode ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.lightTextColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Success message widget
class SuccessMessage extends StatelessWidget {
  final String message;

  const SuccessMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.successColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.successColor.withOpacity(0.5)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.successColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}