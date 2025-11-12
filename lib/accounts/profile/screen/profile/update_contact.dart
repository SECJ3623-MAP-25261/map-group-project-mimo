import 'package:flutter/material.dart';

class UpdateContactPage extends StatefulWidget {
  const UpdateContactPage({super.key});

  @override
  State<UpdateContactPage> createState() => _UpdateContactPageState();
}

class _UpdateContactPageState extends State<UpdateContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  static const Color _accentColor = Color(0xFF3B82F6); // Professional Blue
  static const Color _cardColor = Color(0xFF374151); // Input/Card background
  static const Color _borderColor = Color(0xFF4B5563); // Border color

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
      
      // Determine what was actually updated for a specific message
      if (newEmail.isNotEmpty && newPhone.isNotEmpty) {
        message = "Email and phone updated successfully!";
      } else if (newEmail.isNotEmpty) {
        message = "Email address updated successfully!";
      } else if (newPhone.isNotEmpty) {
        message = "Phone number updated successfully!";
      }

      // Show Success and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ $message"), backgroundColor: _accentColor),
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
      style: const TextStyle(color: Colors.white), 
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: _accentColor),
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
        hintText: labelText,
        hintStyle: const TextStyle(color: Colors.white38),
      ),
      validator: validator,
    );
  }

  
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      // Allow empty, meaning the user only wants to update the phone number
      return null; 
    }
    // Basic email regex for professional validation
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  // Validation logic for Phone Number
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      // Allow empty, meaning the user only wants to update the email
      return null;
    }
    // Simple check for digits only, adjust regex for specific country codes if needed
    final phoneRegex = RegExp(r'^\+?[\d\s-]{8,}$'); 
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number.';
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      appBar: AppBar(
        title: const Text(
          "Update Contact Information",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1F2937),
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
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: _accentColor),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "You can update your email, phone number, or both. Leave a field blank if you do not wish to change it.",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // === Email Section ===
              Text(
                "Update Email Address",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
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

              // === Phone Section ===
              Text(
                "Update Phone Number",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
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

              // Save Changes Button
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Save Changes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                onPressed: _submitChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}