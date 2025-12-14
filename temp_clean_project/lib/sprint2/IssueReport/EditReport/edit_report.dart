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
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalMargin = screenWidth < 360 ? 12.0 : 16.0;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(horizontalMargin),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeHelper(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isVerySmallScreen = screenWidth < 340;
    
    // Responsive padding
    final horizontalPadding = isVerySmallScreen ? 12.0 : (isSmallScreen ? 16.0 : 20.0);
    final verticalSpacing = isSmallScreen ? 16.0 : 20.0;
    final sectionSpacing = isSmallScreen ? 24.0 : 32.0;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: isSmallScreen ? 12.0 : 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Text
                _buildHeaderText(isSmallScreen),
                SizedBox(height: verticalSpacing),
                
                // Category Dropdown
                CategoryDropdown(
                  categories: _categories,
                  selectedCategory: _selectedCategory,
                  onChanged: (value) => setState(() => _selectedCategory = value),
                  theme: theme,
                ),
                SizedBox(height: verticalSpacing),
                
                // User Type Selector
                UserTypeSelector(
                  userType: _userType,
                  onChanged: (value) => setState(() => _userType = value),
                  theme: theme,
                ),
                SizedBox(height: verticalSpacing),
                
                // Subject Input
                InputField(
                  label: 'Subject',
                  controller: _subjectController,
                  theme: theme,
                ),
                SizedBox(height: verticalSpacing),
                
                // Details Input
                InputField(
                  label: 'Details',
                  controller: _detailsController,
                  maxLines: isSmallScreen ? 5 : 6,
                  theme: theme,
                ),
                SizedBox(height: verticalSpacing),
                
                // Photo Section
                PhotoSection(
                  imageBase64: _imageBase64,
                  selectedImage: _selectedImage,
                  onPickImage: _pickImage,
                  onRemoveImage: _removeImage,
                  theme: theme,
                ),
                SizedBox(height: sectionSpacing),
                
                // Submit Button
                SubmitButton(
                  isSubmitting: _isSubmitting,
                  onPressed: _updateReport,
                  buttonText: 'UPDATE REPORT',
                ),
                
                // Bottom spacing for better scrolling
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderText(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.edit_note_rounded,
            color: AppColors.accentColor,
            size: isSmallScreen ? 20 : 24,
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: Text(
              'Update your report details below',
              style: TextStyle(
                color: AppColors.accentColor,
                fontSize: isSmallScreen ? 13 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
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
          centerTitle: false,
          title: Text(
            'Edit Report',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.white,
              size: isSmallScreen ? 20 : 24,
            ),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
          ),
          actions: [
            // Optional: Add a save icon button
            if (!_isSubmitting)
              IconButton(
                icon: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: isSmallScreen ? 22 : 26,
                ),
                onPressed: _updateReport,
                tooltip: 'Save',
              ),
          ],
        ),
      ),
    );
  }
}