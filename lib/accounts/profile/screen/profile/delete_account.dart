import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart'; // ✅ Import your AppColors

class DeleteConfirmationDialog extends StatelessWidget {
  const DeleteConfirmationDialog({super.key});

  void _deleteAccount(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("✅ Account permanently deleted."),
        backgroundColor: AppColors.errorColor, // ✅ Your coral red
        duration: const Duration(seconds: 3),
      ),
    );

    Navigator.of(context).pop(); // Close dialog

    // Uncomment below to navigate to login after deletion:
    // Navigator.of(context).pushAndRemoveUntil(
    //   MaterialPageRoute(builder: (context) => const LoginPage()),
    //   (Route<dynamic> route) => false,
    // );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // ✅ Light-themed background
      backgroundColor: AppColors.lightCardBackground, // white
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      
      title: Row(
        children: [
          Icon(Icons.warning_amber, color: AppColors.errorColor, size: 28),
          const SizedBox(width: 10),
          Text(
            "Confirm Account Deletion",
            style: TextStyle(
              color: AppColors.lightTextColor, // dark gray text
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      
      content: Text(
        "Are you absolutely sure you want to permanently delete your account? This action cannot be undone, and all associated data will be lost.",
        style: TextStyle(
          color: AppColors.lightHintColor, // gray-500 for body text
        ),
      ),
      
      actions: [
        // Cancel Button
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            "Cancel",
            style: TextStyle(
              color: AppColors.accentColor, // your teal/blue
              fontSize: 16,
            ),
          ),
        ),
        
        // Confirm Delete Button
        ElevatedButton(
          onPressed: () => _deleteAccount(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.errorColor, // ✅ coral red from your palette
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