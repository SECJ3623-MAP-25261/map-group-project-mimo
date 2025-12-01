// lib/services/auth_service.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Track user changes
  String? _previousUserId;
  
  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get user email
  String? get userEmail => _auth.currentUser?.email;

  // Get user ID
  String? get userId => _auth.currentUser?.uid;

  // Check if user changed
  bool get hasUserChanged => _previousUserId != null && _previousUserId != userId;

  // Listen to auth state changes
  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      print('🔄 Auth state changed: ${user?.uid ?? "null"}');
      _previousUserId = userId;
      notifyListeners();
    });
  }

  // Check if email exists
  Future<bool> checkEmailExists(String email) async {
    try {
      List<String> methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check email: $e');
    }
  }

  // Register user + save extra info (name, phone)
  Future<User?> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save additional user data to Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ User registered: ${credential.user!.uid}');
      notifyListeners();
      
      return credential.user;
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // Sign in user
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ User signed in: ${credential.user!.uid}');
      notifyListeners();
      
      return credential.user;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Get user data from Firestore
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

  // Manual user change notification (for external auth changes)
  void notifyUserChange() {
    print('🔄 Manual user change notification');
    notifyListeners();
  }

  // Logout with confirmation dialog
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
                Navigator.pop(context); // Close dialog
                
                try {
                  _previousUserId = userId;
                  await _auth.signOut();
                  print('✅ User logged out');
                  notifyListeners();
                  
                  // Navigate to login screen and clear all routes
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error logging out: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // Direct logout without confirmation (if needed)
  Future<void> logoutDirect(BuildContext context) async {
    try {
      _previousUserId = userId;
      await _auth.signOut();
      print('✅ User logged out directly');
      notifyListeners();
      
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}