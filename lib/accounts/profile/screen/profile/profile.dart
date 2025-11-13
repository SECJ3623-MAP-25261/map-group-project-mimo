import 'package:flutter/material.dart';
import 'package:profile_managemenr/accounts/profile/screen/profile/edit_profile.dart';
import '../../../../dbase/data.dart';
import 'package:profile_managemenr/accounts/personalization/personalization.dart';
import 'change_password.dart';
import 'update_contact.dart';
import 'notification.dart';
import 'view_activity.dart';
import 'delete_account.dart';




class ProfileScreen extends StatelessWidget {

  // Assuming dummyUsers[0] is the current user
  final user = dummyUsers[0]; 
  final renter = renter1; // Assuming renter1 is correctly defined and available

  @override
  Widget build(BuildContext context) {
    // Define a vibrant, professional accent color
    const Color primaryColor = Color(0xFF3B82F6); // Professional Blue
    const Color darkBackground = Color(0xFF1F2937); // Slightly lighter dark background
    const Color cardBackground = Color(0xFF374151); // Inner card background

    return Scaffold(
      // 1. Updated Scaffold background to a slightly less harsh dark tone
      backgroundColor: darkBackground, 
      appBar: AppBar(
        title: const Text('Account Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            // 2. Updated Card/Container background for contrast
            decoration: BoxDecoration(
              color: cardBackground, 
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // === Profile Picture ===
                CircleAvatar(
                  radius: 50,
                  backgroundColor: primaryColor.withOpacity(0.2), // Accent color ring
                  child: CircleAvatar(
                    radius: 47,
                    backgroundColor: Colors.black87,
                    backgroundImage: AssetImage(
                      'assets/images/profile_placeholder.png', // Placeholder image
                    ),
                  ),
                ),

                const SizedBox(height: 20),


                // === User Info ===
                const Text(
                  "MY PROFILE",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white, // Changed color for visibility
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2.0,

                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  user.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white, // Changed color for visibility
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  user.email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),

                const SizedBox(height: 25),

                // === Edit Profile Button ===
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit, size: 20),
                  label: const Text("Edit Profile", style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor, // Use vibrant primary color
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=> EditProfileScreen()));
                  },
                ),

                const SizedBox(height: 12),

                // === Delete Account Button ===
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete_forever, size: 20),
                  label: const Text("Delete Account", style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444), // Vibrant red for caution
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>DeleteConfirmationDialog() ));
                  },
                ),

                const Divider(height: 40, thickness: 1, color: Colors.white10),

                // === List of Options ===
                _buildProfileOption("Change Password", Icons.lock_outline, context, primaryColor),
                _buildProfileOption("Update Email / Phone", Icons.contact_mail_outlined, context, primaryColor),
                _buildProfileOption("Manage Notifications", Icons.notifications_active_outlined, context, primaryColor),
                _buildProfileOption("View Activity", Icons.insights, context, primaryColor),
                _buildProfileOption("Personalization Settings",Icons.color_lens_outlined,context, primaryColor),

                const SizedBox(height: 40),

                // === Footer ===
                const Text(
                  "Campus Closet © 2025",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(String text, IconData icon, BuildContext context, Color accentColor) {
    return InkWell( // Use InkWell for a ripple effect (more professional)
      onTap: () {
        // Navigation logic remains the same
        if (text == "Personalization Settings") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CampusClosetApp(renter: renter1, user: dummyUsers[0]),
            ),
          );
        }
        else if(text == "Change Password"){
          Navigator.push(context,MaterialPageRoute(builder: (context)=> ChangePasswordPage()));
        }
        else if(text == "Update Email / Phone"){
          Navigator.push(context, MaterialPageRoute(builder: (context)=> UpdateContactPage()));
        }
        else if(text == "Manage Notifications"){
          Navigator.push(context,MaterialPageRoute(builder: (context)=>NotificationsPage()));
        }
        else if(text=="View Activity"){
          Navigator.push(context, MaterialPageRoute(builder: (context)=>ViewActivityPage()));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8), // Adjusted padding
        child: Row(
          children: [
            Icon(icon, color: accentColor, size: 24), // Use accent color for icons
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}