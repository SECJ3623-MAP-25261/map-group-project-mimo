import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import 'registration_screen.dart';

void main() {
  runApp(const RegistrationApp());
}

class RegistrationApp extends StatelessWidget {
  const RegistrationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Account Registration',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const RegistrationScreen(),
    );
  }
}