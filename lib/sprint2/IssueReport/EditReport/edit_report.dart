// ============================================
// FILE 1: lib/accounts/profile/screen/edit_report.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:profile_managemenr/constants/app_colors.dart';
import '.../../category_dropdown.dart';
import '.../../user_type_selector.dart';
import '.../../input_field.dart';
import '.../../photo_section.dart';
import '.../../submit_button.dart';
import '.../../theme_helper.dart';

class EditReportScreen extends StatefulWidget {
  final Map<String, dynamic> report;

  const EditReportScreen({super.key, required this.report});

  @override
  State<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  late final TextEditingController _subjectController;
  late final TextEditingController _detailsController;
  late String? _selectedCategory;
  late String? _userType;
  String? _imageBase64;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  bool _photoChanged = false;

  static const List<String> _categories = [
    'Bug or Technical Issue',
    'Inappropriate Content',
    'Item Misrepresentation',
    'Account or Security Concern',
    'Feature Suggestion',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _subjectController = TextEditingController(text: widget.report['subject']);
    _detailsController = TextEditingController(text: widget.report['details']);
    _selectedCategory = widget.report['category'];
    _userType = widget.report['userType'];
    _imageBase64 = widget.report['photoBase64'];
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
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

        setState(() {
          _selectedImage = imageFile;
          _imageBase64 = base64String;
          _photoChanged = true;
        });

        _showSnackBar('Photo updated', AppColors.successColor);
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', AppColors.errorColor);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageBase64 = null;
      _photoChanged = true;
    });
    _showSnackBar('Photo removed', Colors.grey);
  }

  bool _validateFields() {
    return _subjectController.text.trim().isNotEmpty &&
        _detailsController.text.trim().isNotEmpty &&
        _selectedCategory != null &&
        _userType != null;
  }

  Future<void> _updateReport() async {
    if (!_validateFields()) {
      _showSnackBar('Please fill in all required fields.', AppColors.errorColor);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final updates = _buildUpdateData();
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(widget.report['id'])
          .update(updates);

      if (!mounted) return;

      _showSnackBar('Report updated successfully', AppColors.successColor);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error updating report: $e', AppColors.errorColor);
      setState(() => _isSubmitting = false);
    }
  }

  Map<String, dynamic> _buildUpdateData() {
    final updates = {
      'subject': _subjectController.text.trim(),
      'details': _detailsController.text.trim(),
      'category': _selectedCategory,
      'userType': _userType,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (_photoChanged) {
      updates['photoBase64'] = _imageBase64 ?? FieldValue.delete();
    }

    return updates;
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CategoryDropdown(
                categories: _categories,
                selectedCategory: _selectedCategory,
                onChanged: (value) => setState(() => _selectedCategory = value),
                theme: theme,
              ),
              const SizedBox(height: 20),
              UserTypeSelector(
                userType: _userType,
                onChanged: (value) => setState(() => _userType = value),
                theme: theme,
              ),
              const SizedBox(height: 20),
              InputField(
                label: 'Subject',
                controller: _subjectController,
                theme: theme,
              ),
              const SizedBox(height: 20),
              InputField(
                label: 'Details',
                controller: _detailsController,
                maxLines: 6,
                theme: theme,
              ),
              const SizedBox(height: 20),
              PhotoSection(
                imageBase64: _imageBase64,
                selectedImage: _selectedImage,
                onPickImage: _pickImage,
                onRemoveImage: _removeImage,
                theme: theme,
              ),
              const SizedBox(height: 32),
              SubmitButton(
                isSubmitting: _isSubmitting,
                onPressed: _updateReport,
                buttonText: 'UPDATE REPORT',
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accentColor.withOpacity(0.9),
              AppColors.accentColor,
            ],
          ),
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Edit Report',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }
}



