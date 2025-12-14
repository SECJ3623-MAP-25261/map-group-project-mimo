import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Custom text field widget
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.lightTextColor,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: AppColors.lightTextColor),
        ),
      ],
    );
  }
}

/// Email field with availability checking
class EmailField extends StatelessWidget {
  final TextEditingController controller;
  final String emailStatus;
  final String? Function(String?)? validator;

  const EmailField({
    super.key,
    required this.controller,
    required this.emailStatus,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email Address',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.lightTextColor,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppColors.lightTextColor),
          validator: validator,
        ),
        const SizedBox(height: 4),
        if (emailStatus.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Row(
              children: [
                if (emailStatus == 'checking')
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.accentColor,
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  emailStatus == 'checking'
                      ? 'Checking availability...'
                      : emailStatus == 'taken'
                          ? '✗ Email already exists'
                          : '✓ Email available',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: emailStatus == 'checking'
                        ? AppColors.accentColor
                        : emailStatus == 'taken'
                            ? AppColors.errorColor
                            : AppColors.successColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Password field with strength indicator
class PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool passwordVisible;
  final VoidCallback onToggleVisibility;
  final double passwordStrength;
  final String passwordStrengthLabel;
  final Color passwordStrengthColor;
  final String? Function(String?)? validator;

  const PasswordField({
    super.key,
    required this.controller,
    required this.passwordVisible,
    required this.onToggleVisibility,
    required this.passwordStrength,
    required this.passwordStrengthLabel,
    required this.passwordStrengthColor,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.lightTextColor,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !passwordVisible,
          style: const TextStyle(color: AppColors.lightTextColor),
          validator: validator,
          decoration: InputDecoration(
            suffixIcon: IconButton(
              icon: Text(
                passwordVisible ? 'Hide' : 'Show',
                style: const TextStyle(
                  color: AppColors.accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: onToggleVisibility,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          passwordStrengthLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: passwordStrength == 0 ? AppColors.lightHintColor : passwordStrengthColor,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: passwordStrength,
            backgroundColor: AppColors.lightBorderColor,
            valueColor: AlwaysStoppedAnimation<Color>(passwordStrengthColor),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

/// Terms and conditions checkbox
class TermsCheckbox extends StatelessWidget {
  final bool termsAccepted;
  final ValueChanged<bool> onChanged;

  const TermsCheckbox({
    super.key,
    required this.termsAccepted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: termsAccepted,
            onChanged: (value) => onChanged(value ?? false),
            activeColor: AppColors.accentColor,
            checkColor: AppColors.lightInputFillColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            side: const BorderSide(color: AppColors.darkHintColor, width: 1.5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!termsAccepted),
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.lightHintColor,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms & Conditions',
                      style: TextStyle(
                        color: AppColors.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: AppColors.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}