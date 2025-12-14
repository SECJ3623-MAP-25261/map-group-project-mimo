// lib/widgets/report_center/report_form.dart

import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import '.../../form_fields/category_field.dart';
import '.../../form_fields/details_field.dart';
import '.../../form_fields/photo_field.dart';
import '.../../form_fields/subject_field.dart';
import '.../../form_fields/submit_button.dart';
import '.../../form_fields/user_type_field.dart';
import 'package:profile_managemenr/services/report_service.dart';
import 'package:profile_managemenr/services/auth_service.dart';
import '.../../report_form_manager.dart';

class ReportForm extends StatefulWidget {
  const ReportForm({super.key});

  @override
  State<ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<ReportForm> {
  final ReportFormManager _formManager = ReportFormManager();
  final ReportService _reportService = ReportService();
  final AuthService _authService = AuthService();
  
  bool _isSubmitting = false;
  bool _hasAttemptedSubmit = false;

  @override
  void initState() {
    super.initState();
    _formManager.addListener(_onFormChange);
  }

  @override
  void dispose() {
    _formManager.removeListener(_onFormChange);
    _formManager.dispose();
    super.dispose();
  }

  void _onFormChange() {
    if (mounted) setState(() {});
  }

  Future<void> _submitReport() async {
    if (!_formManager.isFormValid) return;

    setState(() => _isSubmitting = true);

    try {
      final success = await _formManager.submitReport(
        reportService: _reportService,
        authService: _authService,
      );

      if (!mounted) return;

      if (success) {
        _showSnackBar(
          'Thank you! Your report has been submitted successfully.',
          AppColors.successColor,
        );

        _formManager.resetForm();
        _hasAttemptedSubmit = false;

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

  void _validateAndSubmit() {
    setState(() {
      _hasAttemptedSubmit = true;
    });

    if (!_formManager.isFormValid) {
      _showSnackBar('Please fill in all required fields.', AppColors.errorColor);
      return;
    }

    _submitReport();
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
              // Note: MyReportsScreen would need to be imported from the appropriate location
              // Navigator.pushReplacement(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => const MyReportsScreen(),
              //   ),
              // );
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CategoryField(
          selectedCategory: _formManager.selectedCategory,
          onCategoryChanged: _formManager.setSelectedCategory,
          hasError: _hasAttemptedSubmit && !_formManager.isCategoryValid,
        ),
        const SizedBox(height: 20),

        UserTypeField(
          selectedUserType: _formManager.userType,
          onUserTypeChanged: _formManager.setUserType,
          hasError: _hasAttemptedSubmit && !_formManager.isUserTypeValid,
        ),
        const SizedBox(height: 20),

        SubjectField(
          controller: _formManager.subjectController,
          hasError: _hasAttemptedSubmit && !_formManager.isSubjectValid,
        ),
        const SizedBox(height: 20),

        DetailsField(
          controller: _formManager.detailsController,
          hasError: _hasAttemptedSubmit && !_formManager.isDetailsValid,
        ),
        const SizedBox(height: 20),

        PhotoField(
          selectedImage: _formManager.selectedImage,
          imageBase64: _formManager.imageBase64,
          onImagePicked: _formManager.pickImage,
          onImageRemoved: _formManager.removeImage,
        ),
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

        SubmitButton(
          isSubmitting: _isSubmitting,
          isFormValid: _formManager.isFormValid,
          onSubmit: _validateAndSubmit,
        ),
      ],
    );
  }
}