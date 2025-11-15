import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Password strength data model
class PasswordStrengthData {
  final double strength;
  final String label;
  final Color color;

  const PasswordStrengthData({
    required this.strength,
    required this.label,
    required this.color,
  });
}

/// Calculates password strength
class PasswordStrengthCalculator {
  static PasswordStrengthData calculate(String password) {
    int strength = 0;

    if (password.length >= 8) strength++;
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) strength++;

    final normalizedStrength = strength / 5;

    if (strength == 0) {
      return const PasswordStrengthData(
        strength: 0,
        label: 'Password strength',
        color: Colors.transparent,
      );
    } else if (strength <= 2) {
      return PasswordStrengthData(
        strength: normalizedStrength,
        label: 'Weak password',
        color: AppColors.weakPassword,
      );
    } else if (strength == 3) {
      return PasswordStrengthData(
        strength: normalizedStrength,
        label: 'Fair password',
        color: AppColors.fairPassword,
      );
    } else if (strength == 4) {
      return PasswordStrengthData(
        strength: normalizedStrength,
        label: 'Good password',
        color: AppColors.goodPassword,
      );
    } else {
      return PasswordStrengthData(
        strength: normalizedStrength,
        label: 'Strong password',
        color: AppColors.strongPassword,
      );
    }
  }
}