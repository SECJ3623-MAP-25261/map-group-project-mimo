// lib/utils/report_form_manager.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:profile_managemenr/services/report_service.dart';
import 'package:profile_managemenr/services/auth_service.dart';

class ReportFormManager extends ChangeNotifier {
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String? selectedCategory;
  String? userType;
  File? selectedImage;
  String? imageBase64;
  
  final List<String> categories = [
    'Bug or Technical Issue',
    'Inappropriate Content',
    'Item Misrepresentation',
    'Account or Security Concern',
    'Feature Suggestion',
    'Other',
  ];

  // Validation getters
  bool get isSubjectValid => subjectController.text.trim().isNotEmpty;
  bool get isDetailsValid => detailsController.text.trim().isNotEmpty;
  bool get isCategoryValid => selectedCategory != null;
  bool get isUserTypeValid => userType != null;
  bool get isFormValid => isSubjectValid && isDetailsValid && isCategoryValid && isUserTypeValid;

  void setSelectedCategory(String? category) {
    selectedCategory = category;
    notifyListeners();
  }

  void setUserType(String? type) {
    userType = type;
    notifyListeners();
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        final bytes = await imageFile.readAsBytes();
        final base64String = base64Encode(bytes);

        selectedImage = imageFile;
        imageBase64 = base64String;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  void removeImage() {
    selectedImage = null;
    imageBase64 = null;
    notifyListeners();
  }

  Future<bool> submitReport({
    required ReportService reportService,
    required AuthService authService,
  }) async {
    final userId = authService.userId;
    final userEmail = authService.userEmail;
    
    if (userId == null || userEmail == null) {
      return false;
    }
    
    String userName = 'Unknown User';
    try {
      final userData = await authService.getUserData(userId);
      userName = userData?['fullName'] ?? userEmail.split('@')[0];
    } catch (e) {
      print('Could not fetch user name: $e');
      userName = userEmail.split('@')[0];
    }

    final success = await reportService.submitReport(
      userId: userId,
      userEmail: userEmail,
      userName: userName,
      category: selectedCategory!,
      userType: userType!,
      subject: subjectController.text.trim(),
      details: detailsController.text.trim(),
      photoBase64: imageBase64,
    );

    return success;
  }

  void resetForm() {
    subjectController.clear();
    detailsController.clear();
    selectedCategory = null;
    userType = null;
    selectedImage = null;
    imageBase64 = null;
    notifyListeners();
  }

  @override
  void dispose() {
    subjectController.dispose();
    detailsController.dispose();
    super.dispose();
  }
}