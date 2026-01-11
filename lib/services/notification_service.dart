// lib/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../main.dart';
import '../sprint2/renter_dashboard/booking_request.dart';
import 'package:profile_managemenr/sprint2/Rentee/HistoryRentee/history_rentee.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _currentUserFcmToken;

  Future<void> initialize() async {
    print('🔔 ========== NOTIFICATION INIT START ==========');

    try {
      // Request permission
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print('🔔 Permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        _currentUserFcmToken = await _fcm.getToken();

        if (_currentUserFcmToken != null) {
          print('✅ FCM Token: ${_currentUserFcmToken!.substring(0, 30)}...');
        } else {
          print('❌ No FCM token received');
        }

        // Initialize local notifications
        const androidSettings = AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        );
        const iosSettings = DarwinInitializationSettings();
        const initSettings = InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        );

        await _localNotifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: (response) {
            if (response.payload != null) {
              final data = jsonDecode(response.payload!);
              _handleNotificationTap(data);
            }
          },
        );

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print('📬 Foreground: ${message.notification?.title}');
          _showLocalNotification(message);
        });

        // Handle background taps
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          print('🧪 onMessageOpenedApp DATA: ${message.data}');
          _handleNotificationTap(message.data);
        });

        FirebaseMessaging.instance.getInitialMessage().then((message) {
          if (message != null) {
            print('🧪 getInitialMessage DATA: ${message.data}');
            _handleNotificationTap(message.data);
          } //cold start
        });

        print('✅ Notification service ready');
      } else {
        print('❌ Permission denied');
      }
    } catch (e) {
      print('❌ Init error: $e');
    }

    print('🔔 ========== NOTIFICATION INIT END ==========');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'rental_channel',
      'Rental Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    final data = Map<String, dynamic>.from(message.data);

    // 🔴 ENSURE notificationId exists
    if (!data.containsKey('notificationId')) {
      print('⚠️ notificationId missing in payload');
    }

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
      payload: jsonEncode(data),
    );
  }

  Future<void> saveFcmToken(String userId) async {
    print('💾 ========== SAVE FCM TOKEN ==========');
    print('💾 User: $userId');
    print('💾 Token: ${_currentUserFcmToken?.substring(0, 30)}...');

    if (_currentUserFcmToken == null) {
      print('❌ No token to save');
      return;
    }

    try {
      // Use set with merge to avoid overwriting
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': _currentUserFcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Token saved to Firestore');

      // VERIFY
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data()?['fcmToken'] != null) {
        print('✅ VERIFIED in Firestore');
      } else {
        print('❌ NOT FOUND in Firestore - Check security rules!');
      }
    } catch (e) {
      print('❌ Save error: $e');
      print('❌ Check Firestore security rules!');
    }

    print('💾 ========================================');
  }

  Future<void> notifyRenterOfBookingRequest({
    required String renterId,
    required String renteeId,
    required String renteeName,
    required String itemName,
    required String bookingId,
    required String itemId,
  }) async {
    final docRef = await _firestore.collection('notifications').add({
      'userId': renterId,
      'fromUserId': renteeId,
      'renterId': renterId,
      'type': 'booking_request',
      'title': 'New Booking Request',
      'body': '$renteeName requested to book $itemName',
      'bookingId': bookingId,
      'itemId': itemId,
      'itemName': itemName,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await docRef.update({'notificationId': docRef.id});

    final notificationId = docRef.id;
    print('✅ Notification ID: $notificationId');
  }

  Future<void> notifyRenteeOfBookingApproval({
    required String renteeId,
    required String itemName,
    required String bookingId,
    required String renterId,
  }) async {
    try {
      final docRef = await _firestore.collection('notifications').add({
        'userId': renteeId,
        'type': 'booking_approved',
        'title': 'Booking Approved ✅',
        'body': 'Your request for $itemName was approved!',
        'bookingId': bookingId,
        'renterId': renterId,
        'itemName': itemName,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Approval notification ID: ${docRef.id}');
    } catch (e) {
      print('❌ Error creating approval notification: $e');
    }
  }

  Future<void> notifyRenteeOfBookingRejection({
    required String renteeId,
    required String itemName,
    required String bookingId,
    required String renterId,
  }) async {
    try {
      final docRef = await _firestore.collection('notifications').add({
        'userId': renteeId,
        'type': 'booking_rejected',
        'title': 'Booking Rejected ❌',
        'body': 'Your request for $itemName was rejected',
        'bookingId': bookingId,
        'renterId': renterId,
        'itemName': itemName,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('❌ Rejection notification ID: ${docRef.id}');
    } catch (e) {
      print('❌ Error creating rejection notification: $e');
    }
  }


      Future<void> notifyRenteeApproved({
        required String renteeId,
        required String bookingId,
        required String itemName,
      }) async {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': renteeId,
          'type': 'booking_approved',
          'title': 'Booking Approved ✅',
          'body': 'Your booking for $itemName was approved',
          'bookingId': bookingId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

  Future<void> notifyRenteeOfPickupConfirmation({
    required String renteeId,
    required String itemName,
    required String bookingId,
    required DateTime endDate,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': renteeId,
        'type': 'pickup_confirmed',
        'title': 'Pickup Confirmed ✅',
        'body': 'You picked up $itemName. Enjoy!',
        'bookingId': bookingId,
        'itemName': itemName,
        'endDate': Timestamp.fromDate(endDate),
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  Future<void> notifyRenteeOfReturnConfirmation({
    required String renteeId,
    required String itemName,
    required String bookingId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': renteeId,
        'type': 'return_confirmed',
        'title': 'Return Confirmed ✅',
        'body': 'Thank you for returning $itemName!',
        'bookingId': bookingId,
        'itemName': itemName,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  Stream<int> getUnreadNotificationsCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<Map<String, dynamic>>> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList(),
        );
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

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

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      print('✅ Notification deleted: $notificationId');
    } catch (e) {
      print('❌ Failed to delete notification $notificationId: $e');
    }
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    final bookingId = data['bookingId'];
    final renterId = data['renterId'];
    final notificationId = data['notificationId'];
    final type = data['type'];

    if (notificationId != null) {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    if (type == 'booking_request') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => BookingRequestsScreen(
            renterId: renterId,
            focusBookingId: bookingId,
          ),
        ),
      );
    } else if (type == 'booking_approved' || type == 'booking_cancelled' ||type == 'booking_rejected') {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => const HistoryRenteeScreen(
            isRenter: false, // rentee history
          ),
        ),
      );
    }
  }
}
