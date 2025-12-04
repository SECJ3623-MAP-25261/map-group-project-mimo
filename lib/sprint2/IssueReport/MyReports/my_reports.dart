// ============================================
// FILE 1: lib/accounts/profile/screen/my_reports.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:profile_managemenr/services/report_service.dart';
import 'package:profile_managemenr/services/auth_service.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import '.../../report_card.dart';
import '.../../empty_states.dart';
import 'package:profile_managemenr/sprint2/IssueReport/EditReport/edit_report.dart';
//import 'package:profile_managemenr/sprint2/IssueReport/ReportCenter/report_form_manager.dart';
import '../ReportCenter/report_center.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final ReportService _reportService = ReportService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
    });
  }

  Future<void> _loadReports() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = _authService.userId;
      if (userId == null || userId.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please log in to view your reports';
        });
        return;
      }

      print('Fetching reports for email: $userId');

      final reports = await _reportService.getUserReportsByUserId(userId);

      print('Loaded ${reports.length} reports from service');

      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading reports: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load reports. Please try again.';
      });
    }
  }

  Future<void> _deleteReport(String reportId, int index) async {
    final confirm = await _showDeleteConfirmation();

    if (confirm == true) {
      final success = await _reportService.deleteReport(reportId);
      
      if (success) {
        setState(() => _reports.removeAt(index));
        if (mounted) {
          _showSnackBar('Report deleted successfully', AppColors.successColor);
        }
      } else {
        if (mounted) {
          _showSnackBar('Failed to delete report', AppColors.errorColor);
        }
      }
    }
  }

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report? This action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.errorColor),
            ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _navigateToReportCenter() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReportCenterScreen(),
      ),
    );
    if (result == true && mounted) {
      _loadReports();
    }
  }

  Future<void> _navigateToEditReport(Map<String, dynamic> report) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditReportScreen(report: report),
      ),
    );
    if (result == true) {
      _loadReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFAB(),
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
            'My Reports',
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
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadReports,
              tooltip: 'Refresh',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentColor),
        ),
      );
    }

    if (_authService.userId == null) {
      return LoginRequiredState(onRetry: _loadReports);
    }

    if (_errorMessage != null) {
      return ErrorState(
        message: _errorMessage!,
        onRetry: _loadReports,
      );
    }

    if (_reports.isEmpty) {
      return EmptyReportsState(
        onCreateReport: _navigateToReportCenter,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: _loadReports,
      backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
      color: AppColors.accentColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          return ReportCard(
            report: _reports[index],
            onEdit: () => _navigateToEditReport(_reports[index]),
            onDelete: () => _deleteReport(_reports[index]['id'], index),
          );
        },
      ),
    );
  }

  Widget? _buildFAB() {
    if (_authService.userId == null) return null;

    return FloatingActionButton.extended(
      onPressed: _navigateToReportCenter,
      backgroundColor: AppColors.accentColor,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'New Report',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}







