import 'package:flutter/material.dart';
import 'package:profile_managemenr/accounts/profile/screen/profile/edit_profile.dart';
import '../../../../dbase/data.dart';
import 'package:profile_managemenr/accounts/personalization/personalization.dart';
import 'change_password.dart';
import 'update_contact.dart';
import 'notification.dart';
import 'view_activity.dart';
import 'delete_account.dart';

// ✅ Import AppColors to match your AppTheme's usage
import 'package:profile_managemenr/constants/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  final user = dummyUsers[0];
  final renter = renter1;

  @override
  Widget build(BuildContext context) {
    // 🔸 Match EXACTLY what your AppTheme.darkTheme uses:
    // - scaffold is WHITE (from Color.fromARGB(255, 255, 255, 255))
    // - text uses LIGHT theme colors (AppColors.lightTextColor = dark gray)
    // - inputs use light palette

    const Color scaffoldBg = Color.fromARGB(255, 255, 255, 255); // ← your current darkTheme bg (white!)
    const Color cardBg = AppColors.lightCardBackground; // white
    const Color primaryColor = AppColors.accentColor; // teal
    const Color textColor = AppColors.lightTextColor; // dark gray (#111827)
    const Color textSecondary = AppColors.lightHintColor; // gray-500

    return Scaffold(
      backgroundColor: scaffoldBg, // ← white, as in your darkTheme
      appBar: AppBar(
        title: Text('Account Settings', style: TextStyle(color: textColor)),
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: true,
        foregroundColor: textColor,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg, // white
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Picture
                CircleAvatar(
                  radius: 50,
                  backgroundColor: primaryColor.withOpacity(0.2),
                  child: CircleAvatar(
                    radius: 47,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: const AssetImage('lib/widgets/Mail gemini.png'),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  "MY PROFILE",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  user.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user.email,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 25),

                // Edit Profile Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit, size: 20),
                  label: const Text("Edit Profile", style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfileScreen()));
                  },
                ),
                const SizedBox(height: 12),

                // Delete Account Button
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete_forever, size: 20),
                  label: const Text("Delete Account", style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => DeleteConfirmationDialog()));
                  },
                ),

                const Divider(height: 40, thickness: 1, color: Colors.grey),

                // Menu Items — all using light-theme text colors
                _buildProfileOption("Change Password", Icons.lock_outline, context, primaryColor, textColor, textSecondary),
                _buildProfileOption("Update Email / Phone", Icons.contact_mail_outlined, context, primaryColor, textColor, textSecondary),
                _buildProfileOption("Manage Notifications", Icons.notifications_active_outlined, context, primaryColor, textColor, textSecondary),
                _buildProfileOption("View Activity", Icons.insights, context, primaryColor, textColor, textSecondary),
                _buildProfileOption("Personalization Settings", Icons.color_lens_outlined, context, primaryColor, textColor, textSecondary),

                const SizedBox(height: 40),
                Text(
                  "Campus Closet © 2025",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textSecondary.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    String text,
    IconData icon,
    BuildContext context,
    Color accentColor,
    Color textColor,
    Color textSecondary,
  ) {
    return InkWell(
      onTap: () {
        if (text == "Personalization Settings") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CampusClosetApp(renter: renter1, user: dummyUsers[0]),
            ),
          );
        } else if (text == "Change Password") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ChangePasswordPage()));
        } else if (text == "Update Email / Phone") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => UpdateContactPage()));
        } else if (text == "Manage Notifications") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsPage()));
        } else if (text == "View Activity") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ViewActivityPage()));
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: accentColor, size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: textColor, fontSize: 16),
              ),
            ),
            Icon(Icons.chevron_right, color: textSecondary),
          ],
        ),
      ),
    );
  }
}