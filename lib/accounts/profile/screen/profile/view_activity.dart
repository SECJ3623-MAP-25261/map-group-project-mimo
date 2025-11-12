import 'package:flutter/material.dart';

class ViewActivityPage extends StatelessWidget {
  const ViewActivityPage({super.key});

  // Define consistent theme colors
  static const Color _accentColor = Color(0xFF3B82F6);
  static const Color _cardColor = Color(0xFF374151);
  static const Color _darkBackground = Color(0xFF1F2937);
  static const Color _textColor = Colors.white;

  // Simple list of strings, as requested
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
      backgroundColor: _darkBackground,
      appBar: AppBar(
        title: const Text(
          "Activity Log",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _darkBackground,
        foregroundColor: _textColor,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        itemCount: _activities.length,
        separatorBuilder: (_, __) => const SizedBox(height: 5), // Spacer between cards
        itemBuilder: (context, index) {
          // Determine the icon and color based on content (simple string parsing)
          IconData icon;
          Color color;
          String activity = _activities[index];

          if (activity.contains("listed") || activity.contains("request confirmed")) {
            icon = Icons.shopping_bag_outlined;
            color = Colors.green;
          } else if (activity.contains("password") || activity.contains("updated")) {
            icon = Icons.security;
            color = _accentColor;
          } else if (activity.contains("message")) {
            icon = Icons.chat_bubble_outline;
            color = Colors.amber;
          } else {
            icon = Icons.history;
            color = Colors.white70;
          }
          
          return Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              leading: Icon(icon, color: color, size: 28),
              title: Text(
                activity,
                style: const TextStyle(color: _textColor, fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white30),
              onTap: () {
                // Handle tap action
              },
            ),
          );
        },
      ),
    );
  }
}