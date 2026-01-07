// lib/services/auth_service.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:profile_managemenr/services/notification_service.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  String? _previousUserId;

  User? get currentUser => _auth.currentUser;
  String? get userEmail => _auth.currentUser?.email;
  String? get userId => _auth.currentUser?.uid;
  bool get hasUserChanged => _previousUserId != null && _previousUserId != userId;

  AuthService() {
    print('🔐 AuthService initialized');
    _auth.authStateChanges().listen((User? user) async {
      print('🔄 Auth state changed: ${user?.uid ?? "null"}');
      _previousUserId = userId;
      
      if (user != null) {
        print('✅ User logged in: ${user.uid}');
        await _notificationService.saveFcmToken(user.uid);
      } else {
        print('❌ User logged out');
      }
      
      notifyListeners();
    });
  }

  Future<bool> isAdmin() async {
    final uid = userId;
    if (uid == null) return false;

    try {
      final userData = await getUserData(uid);
      final role = userData?['role'] as String?;
      return role?.toLowerCase() == 'admin';
    } catch (e) {
      print('⚠️ Error checking admin status: $e');
      return false;
    }
  }

  Future<User?> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      print('📝 Registering user: $email');
      
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ User created: ${credential.user!.uid}');

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ User data saved');

      await _notificationService.saveFcmToken(credential.user!.uid);

      notifyListeners();
      return credential.user;
      
    } on FirebaseAuthException catch (e) {
      print('❌ Registration error: ${e.code}');
      if (e.code == 'email-already-in-use') {
        throw Exception('Email already exists');
      } else if (e.code == 'invalid-email') {
        throw Exception('Invalid email');
      } else if (e.code == 'weak-password') {
        throw Exception('Weak password');
      }
      throw Exception(e.message);
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      print('🔐 Signing in: $email');
      
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Signed in: ${credential.user!.uid}');

      await _notificationService.saveFcmToken(credential.user!.uid);

      notifyListeners();
      return credential.user;
      
    } on FirebaseAuthException catch (e) {
      print('❌ Sign in error: ${e.code}');
      if (e.code == 'user-not-found') {
        throw Exception('No user found with this email');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password');
      }
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  void notifyUserChange() {
    print('🔄 Manual user change notification');
    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  _previousUserId = userId;
                  await _auth.signOut();
                  notifyListeners();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> logoutDirect(BuildContext context) async {
    try {
      _previousUserId = userId;
      await _auth.signOut();
      notifyListeners();
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}