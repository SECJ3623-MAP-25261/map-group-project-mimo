// lib/accounts/profile/screen/report_analysis.dart
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart'
    show kIsWeb, kDebugMode, defaultTargetPlatform;

class ReportAnalysisScreen extends StatefulWidget {
  const ReportAnalysisScreen({Key? key}) : super(key: key);

  @override
  State<ReportAnalysisScreen> createState() => _ReportAnalysisScreenState();
}

class _ReportAnalysisScreenState extends State<ReportAnalysisScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _insights;
  String? _error;
  String? _debugInfo;

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _debugInfo = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      developer.log('✅ User authenticated: ${user.uid}');

      // Initialize Firebase Functions
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');

      // 🔌 Use emulator in debug mode (NOT web)
      if (!kIsWeb && kDebugMode) {
        final host = defaultTargetPlatform == TargetPlatform.android
            ? '10.0.2.2'
            : 'localhost';
        const port = 5001;
        functions.useFunctionsEmulator(host, port);
        developer.log('🔌 Using Firebase Functions emulator at $host:$port');
      }

      // Call function
      final callable = functions.httpsCallable('generateRentalInsights');
      developer.log('📞 Calling generateRentalInsights...');
      final result = await callable.call();

      if (result.data != null) {
        setState(() {
          _insights = Map<String, dynamic>.from(result.data);
          _isLoading = false;
        });
      } else {
        throw Exception('No data returned from backend');
      }
    } on FirebaseFunctionsException catch (e) {
      developer.log('❌ Cloud Function Error: ${e.code} - ${e.message}');
      developer.log('Details: ${e.details}');
      String errorMessage = 'Failed to load insights';
      String debugMessage = 'Error Code: ${e.code}\nMessage: ${e.message}';

      if (e.code == 'unavailable') {
        errorMessage = 'Emulator Unreachable';
        debugMessage =
            'Make sure the Firebase emulator is running:\n→ firebase emulators:start --only functions';
      } else if (e.code == 'unauthenticated') {
        errorMessage = 'Authentication Error';
        debugMessage +=
            '\n\nThis may be due to App Check enforcement in production.\nUsing emulator should bypass this in debug mode.';
      } else if (e.code == 'permission-denied') {
        errorMessage = 'Permission Denied';
        debugMessage += '\n\nCheck Firestore security rules';
      }

      if (e.details != null) debugMessage += '\n\nDetails: ${e.details}';

      setState(() {
        _error = errorMessage;
        _debugInfo = debugMessage;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('❌ General Error: $e');
      setState(() {
        _error = 'Unexpected error';
        _debugInfo = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.accentColor,
        title: const Text('Rental Insights',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchReportData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentColor))
          : _error != null
              ? _buildErrorView()
              : _buildReportContent(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_debugInfo != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8)),
                child: SelectableText(
                  _debugInfo!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchReportData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    if (_insights == null) {
      return const Center(
        child: Text('No data available',
            style: TextStyle(fontSize: 16, color: Colors.grey)),
      );
    }
    final data = _insights!;
    return RefreshIndicator(
      onRefresh: _fetchReportData,
      color: AppColors.accentColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricCard('Total Rentals', '${data['totalRentals'] ?? 0}',
                Icons.format_list_numbered),
            _buildMetricCard('Total Spent',
                'RM ${(data['totalSpent'] ?? 0.0).toStringAsFixed(2)}',
                Icons.payments),
            _buildMetricCard('Money Saved',
                'RM ${(data['moneySaved'] ?? 0.0).toStringAsFixed(2)}',
                Icons.savings),
            _buildMetricCard('Return Score',
                '${data['returnScore'] ?? 0}%', Icons.check_circle),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.accentColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold))
                  ]),
            )
          ],
        ),
      ),
    );
  }
}

class MonthlyData {
  final String month;
  final double amount;
  MonthlyData(this.month, this.amount);
}

class CategoryData {
  final String name;
  final int count;
  CategoryData(this.name, this.count);
}
