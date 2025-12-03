// lib/accounts/profile/screen/report_center.dart

import 'package:flutter/material.dart';
import 'package:profile_managemenr/services/report_service.dart';
import 'package:profile_managemenr/services/auth_service.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'my_reports.dart';

class ReportCenterScreen extends StatefulWidget {
  const ReportCenterScreen({super.key});

  @override
  State<ReportCenterScreen> createState() => _ReportCenterScreenState();
}

class _ReportCenterScreenState extends State<ReportCenterScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final ReportService _reportService = ReportService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  
  String? _selectedCategory;
  String? _userType;
  File? _selectedImage;
  String? _imageBase64;
  
  final List<String> _categories = [
    'Bug or Technical Issue',
    'Inappropriate Content',
    'Item Misrepresentation',
    'Account or Security Concern',
    'Feature Suggestion',
    'Other',
  ];

  bool _isSubmitting = false;
  bool _hasAttemptedSubmit = false;

  // Validation getters
  bool get _isSubjectValid => _subjectController.text.trim().isNotEmpty;
  bool get _isDetailsValid => _detailsController.text.trim().isNotEmpty;
  bool get _isCategoryValid => _selectedCategory != null;
  bool get _isUserTypeValid => _userType != null;
  bool get _isFormValid => _isSubjectValid && _isDetailsValid && _isCategoryValid && _isUserTypeValid;

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
        });

        _showSnackBar('Photo added successfully', AppColors.successColor);
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', AppColors.errorColor);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _imageBase64 = null;
    });
    _showSnackBar('Photo removed', Colors.grey);
  }

  void _validateAndSubmit() {
    setState(() {
      _hasAttemptedSubmit = true;
    });

    if (!_isFormValid) {
      _showSnackBar('Please fill in all required fields.', AppColors.errorColor);
      return;
    }

    _submitReport();
  }

  Future<void> _submitReport() async {
    if (!_isFormValid) return;

    setState(() => _isSubmitting = true);

    try {
      final userId = _authService.userId;
      final userEmail = _authService.userEmail;
      
      if (userId == null || userEmail == null) {
        if (!mounted) return;
        _showSnackBar('Please log in to submit a report.', AppColors.errorColor);
        setState(() => _isSubmitting = false);
        return;
      }
      
      String userName = 'Unknown User';
      try {
        final userData = await _authService.getUserData(userId);
        userName = userData?['fullName'] ?? userEmail.split('@')[0];
      } catch (e) {
        print('Could not fetch user name: $e');
        userName = userEmail.split('@')[0];
      }

      final success = await _reportService.submitReport(
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        category: _selectedCategory!,
        userType: _userType!,
        subject: _subjectController.text.trim(),
        details: _detailsController.text.trim(),
        photoBase64: _imageBase64,
      );

      if (!mounted) return;

      if (success) {
        _showSnackBar(
          'Thank you! Your report has been submitted successfully.',
          AppColors.successColor,
        );

        _resetForm();

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _showSuccessDialog();
          }
        });
      } else {
        _showSnackBar(
          'Failed to submit report. Please check your internet connection and try again.',
          AppColors.errorColor,
        );
        setState(() => _isSubmitting = false);
      }
    } catch (e) {
      if (!mounted) return;
      
      print('Error submitting report: $e');
      _showSnackBar(
        'An unexpected error occurred. Please try again.',
        AppColors.errorColor,
      );
      setState(() => _isSubmitting = false);
    }
  }

  void _resetForm() {
    _subjectController.clear();
    _detailsController.clear();
    setState(() {
      _selectedCategory = null;
      _userType = null;
      _selectedImage = null;
      _imageBase64 = null;
      _isSubmitting = false;
      _hasAttemptedSubmit = false;
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text('Report Submitted'),
          ],
        ),
        content: const Text('Your report has been submitted successfully. Our team will review it and get back to you soon.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyReportsScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('View My Reports'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildCategoryField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCardBackground : Colors.white;
    final textColor = isDark ? AppColors.darkTextColor : AppColors.lightTextColor;
    final hintColor = isDark ? AppColors.darkHintColor : AppColors.lightHintColor;
    final borderColor = isDark ? AppColors.darkBorderColor : AppColors.lightBorderColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category *',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: _hasAttemptedSubmit && !_isCategoryValid
                ? Border.all(color: AppColors.errorColor, width: 1)
                : null,
          ),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            value: _selectedCategory,
            hint: Text(
              'Select a category',
              style: TextStyle(color: hintColor),
            ),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(
                  category,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedCategory = value),
            borderRadius: BorderRadius.circular(25),
            isExpanded: true,
          ),
        ),
        if (_hasAttemptedSubmit && !_isCategoryValid)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              'Please select a category',
              style: TextStyle(
                color: AppColors.errorColor,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserTypeField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCardBackground : Colors.white;
    final textColor = isDark ? AppColors.darkTextColor : AppColors.lightTextColor;
    final hintColor = isDark ? AppColors.darkHintColor : AppColors.lightHintColor;
    final borderColor = isDark ? AppColors.darkBorderColor : AppColors.lightBorderColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'I am reporting as *',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: _hasAttemptedSubmit && !_isUserTypeValid
                ? Border.all(color: AppColors.errorColor, width: 1)
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _userType = 'Rentee'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _userType == 'Rentee'
                          ? AppColors.accentColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _userType == 'Rentee'
                            ? AppColors.accentColor
                            : borderColor,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _userType == 'Rentee'
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: _userType == 'Rentee'
                              ? AppColors.accentColor
                              : hintColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rentee',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _userType = 'Renter'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _userType == 'Renter'
                          ? AppColors.accentColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _userType == 'Renter'
                            ? AppColors.accentColor
                            : borderColor,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _userType == 'Renter'
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: _userType == 'Renter'
                              ? AppColors.accentColor
                              : hintColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Renter',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_hasAttemptedSubmit && !_isUserTypeValid)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              'Please select how you are reporting',
              style: TextStyle(
                color: AppColors.errorColor,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubjectField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCardBackground : Colors.white;
    final textColor = isDark ? AppColors.darkTextColor : AppColors.lightTextColor;
    final hintColor = isDark ? AppColors.darkHintColor : AppColors.lightHintColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject *',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: _hasAttemptedSubmit && !_isSubjectValid
                ? Border.all(color: AppColors.errorColor, width: 1)
                : null,
          ),
          child: TextField(
            controller: _subjectController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Briefly describe the issue',
              hintStyle: TextStyle(color: hintColor),
              filled: true,
              fillColor: cardBg,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide(
                  color: AppColors.accentColor,
                  width: 2,
                ),
              ),
              errorText: _hasAttemptedSubmit && !_isSubjectValid
                  ? 'Subject is required'
                  : null,
              errorStyle: const TextStyle(height: 0.8),
              errorMaxLines: 1,
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCardBackground : Colors.white;
    final textColor = isDark ? AppColors.darkTextColor : AppColors.lightTextColor;
    final hintColor = isDark ? AppColors.darkHintColor : AppColors.lightHintColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details *',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: _hasAttemptedSubmit && !_isDetailsValid
                ? Border.all(color: AppColors.errorColor, width: 1)
                : null,
          ),
          child: TextField(
            controller: _detailsController,
            style: TextStyle(color: textColor),
            maxLines: 6,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: 'Provide as much detail as possible...',
              hintStyle: TextStyle(color: hintColor),
              contentPadding: const EdgeInsets.all(16),
              filled: true,
              fillColor: cardBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.accentColor,
                  width: 2,
                ),
              ),
              errorText: _hasAttemptedSubmit && !_isDetailsValid
                  ? 'Details are required'
                  : null,
              errorStyle: const TextStyle(height: 0.8),
              errorMaxLines: 1,
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCardBackground : Colors.white;
    final hintColor = isDark ? AppColors.darkHintColor : AppColors.lightHintColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Attach Photo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextColor : AppColors.lightTextColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(Optional)',
              style: TextStyle(
                color: hintColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        if (_selectedImage == null)
          InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorderColor : AppColors.lightBorderColor,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 40,
                    color: AppColors.accentColor.withOpacity(0.7),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to add photo',
                    style: TextStyle(
                      color: hintColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Max size: 1MB',
                    style: TextStyle(
                      color: hintColor.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    _selectedImage!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDark ? AppColors.darkCardBackground : Colors.grey[300],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.grey, size: 40),
                            SizedBox(height: 8),
                            Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: _removeImage,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.errorColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: _isSubmitting
          ? Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentColor),
                  ),
                ),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accentColor.withOpacity(0.9),
                    AppColors.accentColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _validateAndSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'SUBMIT REPORT',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textColor = isDark ? AppColors.darkTextColor : AppColors.lightTextColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: PreferredSize(
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
              'Report Center',
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
            actions: [
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyReportsScreen(),
                    ),
                  );
                },
                tooltip: 'My Reports',
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accentColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Help us improve Campus Closet by reporting any issues, concerns, or suggestions.',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildCategoryField(),
              const SizedBox(height: 20),

              _buildUserTypeField(),
              const SizedBox(height: 20),

              _buildSubjectField(),
              const SizedBox(height: 20),

              _buildDetailsField(),
              const SizedBox(height: 20),

              _buildPhotoField(),
              const SizedBox(height: 32),

              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  '* Required fields',
                  style: TextStyle(
                    color: isDark ? AppColors.darkHintColor : AppColors.lightHintColor,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }
}