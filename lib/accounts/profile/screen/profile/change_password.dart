import 'package:flutter/material.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  // Global key to manage the form state for validation
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  // State variables for password visibility
  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmNewPasswordVisible = false;

  // Define a vibrant accent color for the dark theme
  static const Color _accentColor = Color(0xFF3B82F6); // Professional Blue
  static const Color _cardColor = Color(0xFF374151); // Input/Card background
  static const Color _borderColor = Color(0xFF4B5563); // Border color

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  void _submitPasswordChange() {
    if (_formKey.currentState!.validate()) {
      // 1. Check if new passwords match
      if (_newPasswordController.text != _confirmNewPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("New passwords do not match."), backgroundColor: Color(0xFFEF4444)),
        );
        return;
      }

      // In a real application, you would send this data to a backend API here.

      // 2. Show Success and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Password updated successfully!"), backgroundColor: _accentColor),
      );
      // Wait briefly before popping, allowing the user to see the success message
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  // Helper method to create professional-looking text fields with toggles
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
      style: const TextStyle(color: Colors.white), // Input text color
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: _cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _accentColor, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.white54,
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
      // Keep dark background from your ProfileScreen
      backgroundColor: const Color(0xFF1F2937), 
      appBar: AppBar(
        title: const Text(
          "Change Password",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1F2937), // Match Scaffold background
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _accentColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.security, color: _accentColor),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Use a strong, unique password to protect your account.",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Current Password Field
              _buildPasswordField(
                controller: _currentPasswordController,
                labelText: "Current Password",
                isVisible: _currentPasswordVisible,
                onToggle: () {
                  setState(() {
                    _currentPasswordVisible = !_currentPasswordVisible;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password.';
                  }
                  // In a real app, you'd check this against the stored hash
                  return null; 
                },
              ),
              const SizedBox(height: 20),

              // New Password Field
              _buildPasswordField(
                controller: _newPasswordController,
                labelText: "New Password",
                isVisible: _newPasswordVisible,
                onToggle: () {
                  setState(() {
                    _newPasswordVisible = !_newPasswordVisible;
                  });
                },
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return 'Password must be at least 8 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Confirm New Password Field
              _buildPasswordField(
                controller: _confirmNewPasswordController,
                labelText: "Confirm New Password",
                isVisible: _confirmNewPasswordVisible,
                onToggle: () {
                  setState(() {
                    _confirmNewPasswordVisible = !_confirmNewPasswordVisible;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Update Button
              ElevatedButton(
                onPressed: _submitPasswordChange,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
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