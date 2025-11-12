import 'package:flutter/material.dart';

// Define consistent theme colors
const Color _accentColor = Color(0xFF3B82F6); 
const Color _cardBackground = Color(0xFF374151);
const Color _deleteButtonColor = Color(0xFFEF4444); // Vibrant Red

class DeleteConfirmationDialog extends StatelessWidget {
  const DeleteConfirmationDialog({super.key});

  // Placeholder function for the actual backend deletion logic
  void _deleteAccount(BuildContext context) {
    // 1. In a real app, integrate your backend logic here:
    //    e.g., Call an API, delete local tokens, etc.
    
    // 2. Show a final confirmation/success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Account permanently deleted."),
        backgroundColor: _deleteButtonColor,
        duration: Duration(seconds: 3),
      ),
    );

    // 3. Close the dialog and navigate to the login screen
    Navigator.of(context).pop(); // Close the dialog

    // Example of navigating to login (uncomment and replace LoginPage() with your actual login widget)
    // Navigator.of(context).pushAndRemoveUntil(
    //     MaterialPageRoute(builder: (context) => const LoginPage()),
    //     (Route<dynamic> route) => false,
    // );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Apply dark theme styling to the dialog
      backgroundColor: _cardBackground, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      
      title: Row(
        children: const [
          Icon(Icons.warning_amber, color: _deleteButtonColor, size: 28),
          SizedBox(width: 10),
          Text(
            "Confirm Account Deletion",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      
      content: const Text(
        "Are you absolutely sure you want to permanently delete your account? This action cannot be undone, and all associated data will be lost.",
        style: TextStyle(color: Colors.white70),
      ),
      
      actions: [
        // Cancel Button
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            "Cancel",
            style: TextStyle(color: _accentColor, fontSize: 16),
          ),
        ),
        
        // Confirm Delete Button (Red and high contrast)
        ElevatedButton(
          onPressed: () => _deleteAccount(context), // Call the delete function
          style: ElevatedButton.styleFrom(
            backgroundColor: _deleteButtonColor, 
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text(
            "Delete Permanently",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}