// lib/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  String? _currentUserFcmToken;

  // Initialize notifications
  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permission granted');
      
      // Get FCM token
      _currentUserFcmToken = await _fcm.getToken();
      print('📱 FCM Token: $_currentUserFcmToken');

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    } else {
      print('❌ Notification permission denied');
    }
  }

  // Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('📬 Foreground notification: ${message.notification?.title}');
    _showLocalNotification(message);
  }

  // Handle background message tap
  void _handleBackgroundMessage(RemoteMessage message) {
    print('📬 Background notification tapped: ${message.notification?.title}');
    // Navigate to relevant screen based on message data
  }

  // Handle local notification tap
  void _onNotificationTap(NotificationResponse response) {
    print('📬 Local notification tapped: ${response.payload}');
    // Navigate based on payload
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'rental_channel',
      'Rental Notifications',
      channelDescription: 'Notifications for rental requests and updates',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  // Save FCM token to Firestore
  Future<void> saveFcmToken(String userId) async {
    if (_currentUserFcmToken != null) {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': _currentUserFcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ FCM token saved for user: $userId');
    }
  }

  // Send notification when rentee requests an item
  Future<void> notifyRenterOfBookingRequest({
    required String renterId,
    required String renteeId,
    required String renteeName,
    required String itemName,
    required String bookingId,
  }) async {
    try {
      // Get renter's FCM token
      final renterDoc = await _firestore.collection('users').doc(renterId).get();
      final renterToken = renterDoc.data()?['fcmToken'] as String?;

      if (renterToken == null) {
        print('⚠️ No FCM token for renter: $renterId');
        return;
      }

      // Create in-app notification record
      await _firestore.collection('notifications').add({
        'userId': renterId,
        'type': 'booking_request',
        'title': 'New Booking Request',
        'body': '$renteeName has requested to rent your $itemName',
        'bookingId': bookingId,
        'itemName': itemName,
        'renteeName': renteeName,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send push notification
      await _sendPushNotification(
        token: renterToken,
        title: 'New Booking Request 📦',
        body: '$renteeName wants to rent your $itemName',
        data: {
          'type': 'booking_request',
          'bookingId': bookingId,
          'renterId': renterId,
        },
      );

      print('✅ Booking request notification sent to renter');
    } catch (e) {
      print('❌ Error sending booking request notification: $e');
    }
  }

  // Send notification when renter approves booking
  Future<void> notifyRenteeOfBookingApproval({
    required String renteeId,
    required String itemName,
    required String bookingId,
    required String meetUpAddress,
    required DateTime startDate,
  }) async {
    try {
      final renteeDoc = await _firestore.collection('users').doc(renteeId).get();
      final renteeToken = renteeDoc.data()?['fcmToken'] as String?;

      if (renteeToken == null) {
        print('⚠️ No FCM token for rentee: $renteeId');
        return;
      }

      await _firestore.collection('notifications').add({
        'userId': renteeId,
        'type': 'booking_approved',
        'title': 'Booking Approved ✅',
        'body': 'Your request for $itemName has been approved!',
        'bookingId': bookingId,
        'itemName': itemName,
        'meetUpAddress': meetUpAddress,
        'startDate': startDate,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _sendPushNotification(
        token: renteeToken,
        title: 'Booking Approved ✅',
        body: 'Your request for $itemName has been approved! Meet-up: $meetUpAddress',
        data: {
          'type': 'booking_approved',
          'bookingId': bookingId,
        },
      );

      print('✅ Booking approval notification sent to rentee');
    } catch (e) {
      print('❌ Error sending booking approval notification: $e');
    }
  }

  // Send notification when renter rejects booking
  Future<void> notifyRenteeOfBookingRejection({
    required String renteeId,
    required String itemName,
    required String bookingId,
  }) async {
    try {
      final renteeDoc = await _firestore.collection('users').doc(renteeId).get();
      final renteeToken = renteeDoc.data()?['fcmToken'] as String?;

      if (renteeToken == null) return;

      await _firestore.collection('notifications').add({
        'userId': renteeId,
        'type': 'booking_cancelled',
        'title': 'Booking Cancelled',
        'body': 'Your request for $itemName was not approved',
        'bookingId': bookingId,
        'itemName': itemName,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _sendPushNotification(
        token: renteeToken,
        title: 'Booking Not Approved',
        body: 'Sorry, your request for $itemName was not approved',
        data: {
          'type': 'booking_cancelled',
          'bookingId': bookingId,
        },
      );

      print('✅ Booking rejection notification sent to rentee');
    } catch (e) {
      print('❌ Error sending booking rejection notification: $e');
    }
  }

  // Send notification when pickup is verified
  Future<void> notifyRenteeOfPickupConfirmation({
    required String renteeId,
    required String itemName,
    required String bookingId,
    required DateTime endDate,
  }) async {
    try {
      final renteeDoc = await _firestore.collection('users').doc(renteeId).get();
      final renteeToken = renteeDoc.data()?['fcmToken'] as String?;

      if (renteeToken == null) return;

      await _firestore.collection('notifications').add({
        'userId': renteeId,
        'type': 'pickup_confirmed',
        'title': 'Pickup Confirmed ✅',
        'body': 'You have successfully picked up $itemName. Enjoy!',
        'bookingId': bookingId,
        'itemName': itemName,
        'endDate': endDate,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _sendPushNotification(
        token: renteeToken,
        title: 'Pickup Confirmed ✅',
        body: 'Enjoy your $itemName! Remember to return it by ${_formatDate(endDate)}',
        data: {
          'type': 'pickup_confirmed',
          'bookingId': bookingId,
        },
      );

      print('✅ Pickup confirmation notification sent to rentee');
    } catch (e) {
      print('❌ Error sending pickup confirmation notification: $e');
    }
  }

  // Send notification when return is verified
  Future<void> notifyRenteeOfReturnConfirmation({
    required String renteeId,
    required String itemName,
    required String bookingId,
  }) async {
    try {
      final renteeDoc = await _firestore.collection('users').doc(renteeId).get();
      final renteeToken = renteeDoc.data()?['fcmToken'] as String?;

      if (renteeToken == null) return;

      await _firestore.collection('notifications').add({
        'userId': renteeId,
        'type': 'return_confirmed',
        'title': 'Return Confirmed ✅',
        'body': 'Your return of $itemName has been confirmed. Thank you!',
        'bookingId': bookingId,
        'itemName': itemName,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _sendPushNotification(
        token: renteeToken,
        title: 'Return Confirmed ✅',
        body: 'Thank you for returning $itemName on time! 🎉',
        data: {
          'type': 'return_confirmed',
          'bookingId': bookingId,
        },
      );

      print('✅ Return confirmation notification sent to rentee');
    } catch (e) {
      print('❌ Error sending return confirmation notification: $e');
    }
  }

  // Send reminder notification before rental ends
  Future<void> sendReturnReminder({
    required String renteeId,
    required String itemName,
    required String bookingId,
    required DateTime endDate,
  }) async {
    try {
      final renteeDoc = await _firestore.collection('users').doc(renteeId).get();
      final renteeToken = renteeDoc.data()?['fcmToken'] as String?;

      if (renteeToken == null) return;

      await _firestore.collection('notifications').add({
        'userId': renteeId,
        'type': 'return_reminder',
        'title': 'Return Reminder ⏰',
        'body': 'Please return $itemName by ${_formatDate(endDate)}',
        'bookingId': bookingId,
        'itemName': itemName,
        'endDate': endDate,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _sendPushNotification(
        token: renteeToken,
        title: 'Return Reminder ⏰',
        body: 'Don\'t forget to return $itemName by ${_formatDate(endDate)}',
        data: {
          'type': 'return_reminder',
          'bookingId': bookingId,
        },
      );

      print('✅ Return reminder notification sent to rentee');
    } catch (e) {
      print('❌ Error sending return reminder notification: $e');
    }
  }

  // Core function to send push notification via FCM
  Future<void> _sendPushNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    // Note: This requires FCM Server Key in your backend
    // For production, implement this on your backend server
    // This is a simplified example
    
    print('📤 Sending push notification to token: ${token.substring(0, 20)}...');
    print('   Title: $title');
    print('   Body: $body');
    
    // In a real app, call your backend API here
    // Example: await http.post('https://your-backend.com/send-notification', ...);
  }

  // Get unread notifications count
  Stream<int> getUnreadNotificationsCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get all notifications for user
  Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in notifications.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // Helper to format date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}