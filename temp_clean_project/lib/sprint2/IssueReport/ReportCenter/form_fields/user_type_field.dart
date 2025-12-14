import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';

class UserTypeField extends StatelessWidget {
  final String? selectedUserType;
  final Function(String?) onUserTypeChanged;
  final bool hasError;

  const UserTypeField({
    super.key,
    required this.selectedUserType,
    required this.onUserTypeChanged,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCardBackground : Colors.white;
    final textColor = isDark ? AppColors.darkTextColor : AppColors.lightTextColor;
    final hintColor = isDark ? AppColors.darkHintColor : AppColors.lightHintColor;
    final borderColor = isDark ? AppColors.darkBorderColor : AppColors.lightBorderColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am reporting as *',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
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
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => onUserTypeChanged('Rentee'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selectedUserType == 'Rentee'
                          ? AppColors.accentColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedUserType == 'Rentee'
                            ? AppColors.accentColor
                            : borderColor,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selectedUserType == 'Rentee'
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: selectedUserType == 'Rentee'
                              ? AppColors.accentColor
                              : hintColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rentee',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => onUserTypeChanged('Renter'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selectedUserType == 'Renter'
                          ? AppColors.accentColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selectedUserType == 'Renter'
                            ? AppColors.accentColor
                            : borderColor,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selectedUserType == 'Renter'
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: selectedUserType == 'Renter'
                              ? AppColors.accentColor
                              : hintColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Renter',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              'Please select how you are reporting',
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