import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:profile_managemenr/services/auth_service.dart';
import 'package:profile_managemenr/services/notification_service.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import 'package:profile_managemenr/sprint2/renter_dashboard/booking_request.dart';
import 'package:profile_managemenr/sprint2/Rentee/HistoryRentee/history_rentee.dart';
import 'package:profile_managemenr/sprint4/notications_navigator.dart';

class NotificationsScreen extends StatelessWidget {
  NotificationsScreen({super.key});

  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final userId = _authService.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.accentColor,
        actions: [
          if (userId != null)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: () => _notificationService.markAllAsRead(userId),
            ),
        ],
      ),
      body: userId == null
          ? const Center(child: Text('Please login'))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _notificationService.getNotifications(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final notifications = snapshot.data ?? [];

                if (notifications.isEmpty) {
                  return const Center(child: Text('No notifications'));
                }

                return ListView.separated(
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return _notificationTile(context, n);
                  },
                );
              },
            ),
    );
  }

  Widget _notificationTile(BuildContext context, Map<String, dynamic> n) {
    final id = n['id'];
    final bookingId = n['bookingId'];
    if (id == null) return SizedBox(); // skip this notification if no id
    final title = n['title'] ?? 'Notification';
    final message = n['body'] ?? '';
    final isRead = n['isRead'] ?? false;
    final createdAt = n['createdAt'];

    return Dismissible(
      key: ValueKey(id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        try {
          await _notificationService.deleteNotification(id);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Notification deleted')));
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
        }
      },
      child: Container(
        color: isRead ? Colors.white : Colors.grey.shade100,
        child: ListTile(
          leading: Icon(
            Icons.notifications,
            color: isRead ? Colors.grey : AppColors.accentColor,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const SizedBox(height: 4),
              Text(
                _formatTime(createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),

          onTap: () async {
  if (!isRead) {
    await _notificationService.markAsRead(id);
  }

    handleNotificationNavigation(
    context: context,
    data: n,
    userId: _authService.userId!,
  );
}

        ),
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Just now';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return DateFormat('dd MMM yyyy').format(date);
  }
}
