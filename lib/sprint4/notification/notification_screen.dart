// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:profile_managemenr/services/notification_service.dart';
import 'package:profile_managemenr/services/auth_service.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final userId = _authService.userId;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: AppColors.accentColor,
        ),
        body: const Center(child: Text('Please log in to view notifications')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.accentColor,
        foregroundColor: Colors.white,
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () => _markAllAsRead(userId),
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationService.getNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, 
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final notificationId = notification['id'] as String;
    final type = notification['type'] as String? ?? 'general';
    final title = notification['title'] as String? ?? 'Notification';
    final body = notification['body'] as String? ?? '';
    final isRead = notification['isRead'] as bool? ?? false;
    final createdAt = notification['createdAt'];

    final icon = _getIconForType(type);
    final color = _getColorForType(type);

    return Dismissible(
      key: Key(notificationId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        _notificationService.deleteNotification(notificationId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead ? Colors.grey[300]! : color.withOpacity(0.3),
            width: isRead ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                body,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatTimestamp(createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          trailing: !isRead
              ? Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: () {
            if (!isRead) {
              _notificationService.markAsRead(notificationId);
            }
            _handleNotificationTap(notification);
          },
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'booking_request':
        return Icons.notification_important;
      case 'booking_approved':
        return Icons.check_circle;
      case 'booking_cancelled':
        return Icons.cancel;
      case 'pickup_confirmed':
        return Icons.shopping_bag;
      case 'return_confirmed':
        return Icons.assignment_turned_in;
      case 'return_reminder':
        return Icons.alarm;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'booking_request':
        return Colors.orange;
      case 'booking_approved':
        return Colors.green;
      case 'booking_cancelled':
        return Colors.red;
      case 'pickup_confirmed':
        return Colors.purple;
      case 'return_confirmed':
        return Colors.blue;
      case 'return_reminder':
        return Colors.amber;
      default:
        return AppColors.accentColor;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    
    try {
      final DateTime dateTime = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM d, yyyy').format(dateTime);
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final type = notification['type'] as String?;
    final bookingId = notification['bookingId'] as String?;

    // Navigate based on notification type
    if (bookingId != null) {
      // Navigate to booking details screen
      // Navigator.pushNamed(context, '/booking-details', arguments: bookingId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening booking: $bookingId')),
      );
    }
  }

  Future<void> _markAllAsRead(String userId) async {
    await _notificationService.markAllAsRead(userId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }
}