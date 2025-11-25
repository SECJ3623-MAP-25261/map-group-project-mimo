import 'package:flutter/material.dart';
import 'package:profile_managemenr/accounts/profile/screen/profile/edit_profile.dart';
import 'package:profile_managemenr/accounts/personalization/personalization.dart';
import 'change_password.dart';
//import 'update_contact.dart';
import 'notification.dart';
import 'view_activity.dart';
import 'delete_account.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import 'package:profile_managemenr/services/auth_service.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Widget _buildProfileAvatar(String userName) {
  ImageProvider? imageProvider;
  
  // Try to load base64 image from Firestore
  final base64String = _userData?['profilePictureBase64'];
  if (base64String != null && base64String.isNotEmpty) {
    try {
      final bytes = base64Decode(base64String);
      imageProvider = MemoryImage(bytes);
    } catch (e) {
      print('Error decoding profile image: $e');
    }
  }

  const Color primaryColor = AppColors.accentColor;

  return CircleAvatar(
    radius: 50,
    backgroundColor: primaryColor.withOpacity(0.2),
    child: CircleAvatar(
      radius: 47,
      backgroundColor: Colors.grey[200],
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            )
          : null,
    ),
  );
}
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = _authService.userId;
      if (userId != null) {
        final data = await _authService.getUserData(userId);
        setState(() {
          _userData = data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color scaffoldBg = Color.fromARGB(255, 255, 255, 255);
    const Color cardBg = AppColors.lightCardBackground;
    const Color primaryColor = AppColors.accentColor;
    const Color textColor = AppColors.lightTextColor;
    const Color textSecondary = AppColors.lightHintColor;

    // Get data from Firebase or use defaults
    final String userName = _userData?['fullName'] ?? 'User';
    final String userEmail = _authService.userEmail ?? 'email@example.com';
    final String userPhone = _userData?['phone'] ?? 'Not provided';

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text('Account Settings', style: TextStyle(color: textColor)),
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: true,
        foregroundColor: textColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardBg,
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
                      // Profile Picture with Base64 support
                      _buildProfileAvatar(userName),
                      // Profile Picture
                      /*CircleAvatar(
                        radius: 50,
                        backgroundColor: primaryColor.withOpacity(0.2),
                        child: CircleAvatar(
                          radius: 47,
                          backgroundColor: Colors.grey[200],
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),*/
                      // Profile Picture with Base64 support
                        

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

                      // User Name from Firebase
                      Text(
                        userName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      // User Email from Firebase
                      Text(
                        userEmail,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textSecondary, fontSize: 16),
                      ),
                      
                      // User Phone from Firebase
                      if (userPhone != 'Not provided')
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            userPhone,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: textSecondary, fontSize: 14),
                          ),
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
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(userData: _userData),
                            ),
                          );
                          // Reload data if profile was updated
                          if (result == true) {
                            _loadUserData();
                          }
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => DeleteConfirmationDialog()),
                          );
                        },
                      ),

                      const Divider(height: 40, thickness: 1, color: Colors.grey),

                      // Menu Items
                      _buildProfileOption(
                        "Change Password",
                        Icons.lock_outline,
                        context,
                        primaryColor,
                        textColor,
                        textSecondary,
                      ),
                      _buildProfileOption(
                        "Update Email / Phone",
                        Icons.contact_mail_outlined,
                        context,
                        primaryColor,
                        textColor,
                        textSecondary,
                      ),
                      _buildProfileOption(
                        "Manage Notifications",
                        Icons.notifications_active_outlined,
                        context,
                        primaryColor,
                        textColor,
                        textSecondary,
                      ),
                      _buildProfileOption(
                        "View Activity",
                        Icons.insights,
                        context,
                        primaryColor,
                        textColor,
                        textSecondary,
                      ),
                      _buildProfileOption(
                        "Personalization Settings",
                        Icons.color_lens_outlined,
                        context,
                        primaryColor,
                        textColor,
                        textSecondary,
                      ),

                      const SizedBox(height: 30),

                      // LOGOUT BUTTON
                      OutlinedButton.icon(
                        icon: const Icon(Icons.logout, size: 20),
                        label: const Text("Logout", style: TextStyle(fontSize: 16)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _authService.logout(context),
                      ),

                      const SizedBox(height: 20),
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
      onTap: () async {
        if (text == "Personalization Settings") {
  // Ensure _userData is available
  if (_userData != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RenterDashboard(userData: _userData!),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('User data not loaded.')),
    );
  }


        } else if (text == "Change Password") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChangePasswordPage()),
          );
        } else if (text == "Update Email / Phone") {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProfileScreen(userData: _userData),
            ),
          );
          if (result == true) {
            _loadUserData(); // Reload if updated
          }
        } else if (text == "Manage Notifications") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NotificationsPage()),
          );
        } else if (text == "View Activity") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ViewActivityPage()),
          );
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