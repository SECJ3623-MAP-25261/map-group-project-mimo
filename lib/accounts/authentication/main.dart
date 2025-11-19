import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // ← Core Firebase
import 'package:profile_managemenr/accounts/authentication/login.dart'; // Your login screen

// Optional: If you have a custom theme
import 'package:profile_managemenr/constants/app_theme.dart'; // Make sure this file exists

void main() async {
  // 🔑 Required for async initialization
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 Initialize Firebase (connects your app to Firebase project)
  await Firebase.initializeApp();

  // 🎨 Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Closet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // ← Only if you have AppTheme defined
      // If you don't have AppTheme, just remove this line or use defaultTheme
      home: const LoginPage(), // Start with login screen
    );
  }
}