import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import '.../../theme_helper.dart';

class UserTypeSelector extends StatelessWidget {
  final String? userType;
  final ValueChanged<String> onChanged;
  final ThemeHelper theme;

  const UserTypeSelector({
    super.key,
    required this.userType,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reporting as',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textColor,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _UserTypeOption(
                  label: 'Rentee',
                  isSelected: userType == 'Rentee',
                  onTap: () => onChanged('Rentee'),
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _UserTypeOption(
                  label: 'Renter',
                  isSelected: userType == 'Renter',
                  onTap: () => onChanged('Renter'),
                  theme: theme,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UserTypeOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeHelper theme;

  const _UserTypeOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accentColor : theme.borderColor,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.accentColor : theme.hintColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}