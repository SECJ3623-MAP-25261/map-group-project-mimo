import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

Future<void> setupFCM(String userId) async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Ask permission
  await messaging.requestPermission();

  // Get token
  String? token = await messaging.getToken();

  // 👀 SEE TOKEN IN CONSOLE
  debugPrint("📱 FCM TOKEN: $token");

  if (token != null) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set({'fcmToken': token}, SetOptions(merge: true));

    debugPrint("✅ FCM token saved to Firestore");
  }
}
