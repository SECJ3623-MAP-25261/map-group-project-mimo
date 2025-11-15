import 'package:flutter/material.dart';

/// App color constants for dark and light themes
class AppColors {
  // Accent color (same for both themes)
  static const Color accentColor = Color.fromARGB(255, 50, 230, 209); // Teal Accent
  
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF1F2937);
  static const Color darkCardBackground = Color(0xFF374151);
  static const Color darkInputFillColor = Color(0xFF111827);
  static const Color darkTextColor = Colors.white;
  static const Color darkHintColor = Colors.white60;
  static const Color darkBorderColor = Color(0xFF4B5563);
  
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF3F4F6);
  static const Color lightCardBackground = Colors.white;
  static const Color lightInputFillColor = Color(0xFFF9FAFB);
  static const Color lightTextColor = Color(0xFF111827);
  static const Color lightHintColor = Color(0xFF6B7280);
  static const Color lightBorderColor = Color(0xFFD1D5DB);
  
  // Status colors (same for both themes)
  static const Color errorColor = Color(0xFFe76f51); // Coral/Orange
  static const Color successColor = Color(0xFF4CAF50);
  
  // Password strength colors (same for both themes)
  static const Color weakPassword = Color(0xFFff4d4f);
  static const Color fairPassword = Color(0xFFfaad14);
  static const Color goodPassword = Color(0xFF52c41a);
  static const Color strongPassword = Color(0xFF4096ff);
}