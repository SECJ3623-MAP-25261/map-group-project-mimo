// lib/widgets/notification_badge.dart
import 'package:flutter/material.dart';
import 'package:profile_managemenr/services/notification_service.dart';
import 'package:profile_managemenr/services/auth_service.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import 'package:profile_managemenr/sprint4/notification/notification_screen.dart';

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final notificationService = NotificationService();
    final userId = authService.userId;

    if (userId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<int>(
      stream: notificationService.getUnreadNotificationsCount(userId),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// Example usage in your AppBar:
/*
AppBar(
  title: const Text('Campus Closet'),
  backgroundColor: AppColors.accentColor,
  actions: [
    const NotificationBadge(), // Add this
    // ... other actions
  ],
)
*/