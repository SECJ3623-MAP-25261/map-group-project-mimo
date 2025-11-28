import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';

class ViewActivityPage extends StatelessWidget {
  const ViewActivityPage({super.key});

  // Activity list (unchanged)
  final List<String> _activities = const [
    "18:30 - You listed 'Blue Hoodie' for rent",
    "15:45 - You updated your profile picture",
    "10:15 - You received a new message",
    "Yesterday - You changed your password",
    "Yesterday - Rental request confirmed for 'Black Backpack'",
    "5/11/2025 - Updated your phone number in contact settings",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground, // ✅ Light gray background
      appBar: AppBar(
        title: const Text(
          "Activity Log",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextColor, // ✅ Dark text
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        itemCount: _activities.length,
        separatorBuilder: (_, __) => const SizedBox(height: 5),
        itemBuilder: (context, index) {
          String activity = _activities[index];

          // Icon & color logic (same as before — just update colors)
          IconData icon;
          Color color;

          if (activity.contains("listed") || activity.contains("request confirmed")) {
            icon = Icons.shopping_bag_outlined;
            color = Colors.green; // Can keep semantic colors like green/amber
          } else if (activity.contains("password") || activity.contains("updated")) {
            icon = Icons.security;
            color = AppColors.accentColor; // ✅ Use your accent
          } else if (activity.contains("message")) {
            icon = Icons.chat_bubble_outline;
            color = Colors.amber; // or replace with AppColors if preferred
          } else {
            icon = Icons.history;
            color = AppColors.lightHintColor; // ✅ subdued gray
          }

          return Container(
            decoration: BoxDecoration(
              color: AppColors.lightCardBackground, // ✅ white card
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              leading: Icon(icon, color: color, size: 28),
              title: Text(
                activity,
                style: TextStyle(
                  color: AppColors.lightTextColor, // ✅ dark gray text
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: AppColors.lightHintColor.withOpacity(0.6), // ✅ subtle arrow
              ),
              onTap: () {
                // Handle tap if needed
              },
            ),
          );
        },
      ),
    );
  }
}