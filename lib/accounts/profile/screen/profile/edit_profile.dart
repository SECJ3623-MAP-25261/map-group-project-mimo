import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart'; // ✅ Import your AppColors

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Initialize with placeholder data
  String _name = "John Doe";
  String _phone = "012-3456789";

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("✅ Profile updated successfully!"),
          backgroundColor: AppColors.accentColor,
          duration: const Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground, // ✅ Light gray background
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextColor, // ✅ Dark text for AppBar
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Profile Picture Placeholder ---
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.lightCardBackground, // ✅ white background
                      backgroundImage: const AssetImage('assets/images/profile_placeholder.png'),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.accentColor, // ✅ your teal/blue
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.lightBackground, // ✅ light bg as border
                            width: 2,
                          ),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- Name Field ---
              TextFormField(
                initialValue: _name,
                style: TextStyle(color: AppColors.lightTextColor),
                decoration: InputDecoration(
                  labelText: "Name",
                  labelStyle: TextStyle(color: AppColors.lightHintColor),
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.accentColor),
                  filled: true,
                  fillColor: AppColors.lightInputFillColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.lightBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.accentColor, width: 2),
                  ),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Name cannot be empty'
                    : null,
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 20),

              // --- Phone Field ---
              TextFormField(
                initialValue: _phone,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: AppColors.lightTextColor),
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  labelStyle: TextStyle(color: AppColors.lightHintColor),
                  prefixIcon: Icon(Icons.phone_outlined, color: AppColors.accentColor),
                  filled: true,
                  fillColor: AppColors.lightInputFillColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.lightBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.accentColor, width: 2),
                  ),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Phone number cannot be empty'
                    : null,
                onSaved: (value) => _phone = value!,
              ),
              const SizedBox(height: 40),

              // --- Save Button ---
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text(
                  "Save Changes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                onPressed: _saveChanges,
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