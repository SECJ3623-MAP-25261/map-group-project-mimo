import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmNewPasswordVisible = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  void _submitPasswordChange() {
    if (_formKey.currentState!.validate()) {
      if (_newPasswordController.text != _confirmNewPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("New passwords do not match."),
            backgroundColor: AppColors.errorColor,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("✅ Password updated successfully!"),
          backgroundColor: AppColors.accentColor,
          duration: const Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelText,
    required bool isVisible,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      style: TextStyle(color: AppColors.lightTextColor), // dark gray text
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: AppColors.lightHintColor),
        filled: true,
        fillColor: AppColors.lightInputFillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.lightBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.lightBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.accentColor, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off : Icons.visibility,
            color: AppColors.lightHintColor,
          ),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground, // light gray bg
      appBar: AppBar(
        title: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextColor, // dark text for app bar
        elevation: 0,
        // Remove shadow and match background
        surfaceTintColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Banner (light version)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accentColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: AppColors.accentColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Use a strong, unique password to protect your account.",
                        style: TextStyle(
                          color: AppColors.lightHintColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              _buildPasswordField(
                controller: _currentPasswordController,
                labelText: "Current Password",
                isVisible: _currentPasswordVisible,
                onToggle: () => setState(() => _currentPasswordVisible = !_currentPasswordVisible),
                validator: (value) => value?.isEmpty ?? true
                    ? 'Please enter your current password.'
                    : null,
              ),
              const SizedBox(height: 20),

              _buildPasswordField(
                controller: _newPasswordController,
                labelText: "New Password",
                isVisible: _newPasswordVisible,
                onToggle: () => setState(() => _newPasswordVisible = !_newPasswordVisible),
                validator: (value) => (value == null || value.length < 8)
                    ? 'Password must be at least 8 characters.'
                    : null,
              ),
              const SizedBox(height: 20),

              _buildPasswordField(
                controller: _confirmNewPasswordController,
                labelText: "Confirm New Password",
                isVisible: _confirmNewPasswordVisible,
                onToggle: () => setState(() => _confirmNewPasswordVisible = !_confirmNewPasswordVisible),
                validator: (value) => value?.isEmpty ?? true
                    ? 'Please confirm your new password.'
                    : null,
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _submitPasswordChange,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                child: const Text(
                  "Update Password",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}