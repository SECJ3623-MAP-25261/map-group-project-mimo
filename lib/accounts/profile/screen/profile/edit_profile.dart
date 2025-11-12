import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Initialize with placeholder data if available, or empty strings
  String _name = "John Doe"; 
  String _phone = "012-3456789"; 

  // Define consistent theme colors
  static const Color _accentColor = Color(0xFF3B82F6); 
  static const Color _cardColor = Color(0xFF374151); 
  static const Color _darkBackground = Color(0xFF1F2937);
  static const Color _textColor = Colors.white;

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // 1. Placeholder for your saving logic (e.g., update Firebase)
      // print("Saving Name: $_name, Phone: $_phone"); 

      // 2. Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Profile updated successfully!"), 
          backgroundColor: _accentColor,
        ),
      );
      
      // 3. Navigate back to the ProfileScreen
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _darkBackground,
        foregroundColor: _textColor,
        elevation: 0,
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
                      backgroundColor: _cardColor,
                      backgroundImage: const AssetImage('assets/images/profile_placeholder.png'),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: _darkBackground, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: _textColor, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // --- Name Field ---
              TextFormField(
                initialValue: _name,
                style: const TextStyle(color: _textColor),
                decoration: InputDecoration(
                  labelText: "Name",
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.person_outline, color: _accentColor),
                  filled: true,
                  fillColor: _cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF4B5563)),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Name cannot be empty' : null,
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 20),
              
              // --- Phone Field ---
              TextFormField(
                initialValue: _phone,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: _textColor),
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.phone_outlined, color: _accentColor),
                  filled: true,
                  fillColor: _cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF4B5563)),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Phone number cannot be empty' : null,
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
                  backgroundColor: _accentColor,
                  foregroundColor: _textColor,
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