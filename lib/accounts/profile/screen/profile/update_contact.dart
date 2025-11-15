import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart'; // ✅ Your color system

class UpdateContactPage extends StatefulWidget {
  const UpdateContactPage({super.key});

  @override
  State<UpdateContactPage> createState() => _UpdateContactPageState();
}

class _UpdateContactPageState extends State<UpdateContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submitChanges() {
    if (_formKey.currentState!.validate()) {
      String newEmail = _emailController.text;
      String newPhone = _phoneController.text;

      String message = "Contact info saved.";
      if (newEmail.isNotEmpty && newPhone.isNotEmpty) {
        message = "Email and phone updated successfully!";
      } else if (newEmail.isNotEmpty) {
        message = "Email address updated successfully!";
      } else if (newPhone.isNotEmpty) {
        message = "Phone number updated successfully!";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ $message"),
          backgroundColor: AppColors.accentColor,
          duration: const Duration(seconds: 2),
        ),
      );

      _emailController.clear();
      _phoneController.clear();
    }
  }

  Widget _buildContactField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: AppColors.lightTextColor), // dark gray text
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: AppColors.lightHintColor),
        prefixIcon: Icon(icon, color: AppColors.accentColor),
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
        hintText: labelText,
        hintStyle: TextStyle(color: AppColors.lightHintColor.withOpacity(0.6)),
      ),
      validator: validator,
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return null;
    final phoneRegex = RegExp(r'^\+?[\d\s-]{8,}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground, // ✅ Light gray background
      appBar: AppBar(
        title: const Text(
          "Update Contact Information",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextColor, // dark text for AppBar
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card (light version)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightCardBackground, // white card
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.accentColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "You can update your email, phone number, or both. Leave a field blank if you do not wish to change it.",
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

              Text(
                "Update Email Address",
                style: TextStyle(
                  color: AppColors.lightTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _buildContactField(
                controller: _emailController,
                labelText: "New Email",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 30),

              Text(
                "Update Phone Number",
                style: TextStyle(
                  color: AppColors.lightTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _buildContactField(
                controller: _phoneController,
                labelText: "New Phone Number",
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
              ),
              const SizedBox(height: 40),

              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Save Changes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                onPressed: _submitChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}