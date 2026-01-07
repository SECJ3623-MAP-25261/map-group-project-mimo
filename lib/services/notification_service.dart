// lib/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
        const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
        const iosSettings = DarwinInitializationSettings();
        const initSettings = InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        );

        await _localNotifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: (response) {
            print('📬 Notification tapped: ${response.payload}');
          },
        );

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print('📬 Foreground: ${message.notification?.title}');
          _showLocalNotification(message);
        });

        // Handle background taps
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          print('📬 Background tap: ${message.notification?.title}');
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

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
      payload: jsonEncode(message.data),
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
  }) async {
    print('');
    print('🔔 ========== CREATE NOTIFICATION ==========');
    print('🔔 Type: Booking Request');
    print('🔔 To: $renterId');
    print('🔔 From: $renteeName');
    print('🔔 Item: $itemName');
    
    try {
      final data = {
        'userId': renterId,
        'type': 'booking_request',
        'title': 'New Booking Request',
        'body': '$renteeName wants to rent your $itemName',
        'bookingId': bookingId,
        'itemName': itemName,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      print('📝 Data: $data');
      
      final docRef = await _firestore.collection('notifications').add(data);
      
      print('✅ Created: ${docRef.id}');
      
      // VERIFY
      final doc = await docRef.get();
      if (doc.exists) {
        print('✅ VERIFIED in Firestore');
      } else {
        print('❌ NOT FOUND - Check security rules!');
      }
      
    } catch (e) {
      print('❌ Create error: $e');
      print('❌ FIRESTORE RULES ISSUE!');
    }
    
    print('🔔 ========================================');
    print('');
  }

  Future<void> notifyRenteeOfBookingApproval({
    required String renteeId,
    required String itemName,
    required String bookingId,
    required String meetUpAddress,
    required DateTime startDate,
  }) async {
    print('🔔 Creating approval notification...');
    
    try {
      await _firestore.collection('notifications').add({
        'userId': renteeId,
        'type': 'booking_approved',
        'title': 'Booking Approved ✅',
        'body': 'Your request for $itemName was approved!',
        'bookingId': bookingId,
        'itemName': itemName,
        'meetUpAddress': meetUpAddress,
        'startDate': Timestamp.fromDate(startDate),
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Approval notification created');
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  Future<void> notifyRenteeOfBookingRejection({
    required String renteeId,
    required String itemName,
    required String bookingId,
  }) async {
    try {
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
    } catch (e) {
      print('❌ Error: $e');
    }
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
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
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
    await _firestore.collection('notifications').doc(notificationId).delete();
  }
}
