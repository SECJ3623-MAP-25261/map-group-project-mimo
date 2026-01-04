// lib/accounts/profile/screen/report_analysis.dart
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

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
      // Step 1: Check current user
      final user = FirebaseAuth.instance.currentUser;
      developer.log('Step 1: Checking user...');
      developer.log('User: ${user?.uid}');
      developer.log('User email: ${user?.email}');
      
      if (user == null) {
        setState(() {
          _error = 'You must be logged in to view rental insights.';
          _debugInfo = 'No user found in FirebaseAuth.instance.currentUser';
          _isLoading = false;
        });
        return;
      }

      // Step 2: Get and log token info
      developer.log('Step 2: Getting ID token...');
      final idTokenResult = await user.getIdTokenResult(true);
      final token = idTokenResult.token;
      
      developer.log('Token exists: ${token != null}');
      developer.log('Token length: ${token?.length}');
      developer.log('Token expiration: ${idTokenResult.expirationTime}');
      developer.log('Token issue time: ${idTokenResult.issuedAtTime}');
      developer.log('Token claims: ${idTokenResult.claims}');
      
      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'Failed to get authentication token';
          _debugInfo = 'Token is null or empty';
          _isLoading = false;
        });
        return;
      }

      // Step 3: Check token expiration
      final now = DateTime.now();
      final expirationTime = idTokenResult.expirationTime;
      if (expirationTime != null && now.isAfter(expirationTime)) {
        setState(() {
          _error = 'Token has expired';
          _debugInfo = 'Token expired at: $expirationTime, Current time: $now';
          _isLoading = false;
        });
        return;
      }

      // Step 4: Configure Firebase Functions
      developer.log('Step 3: Configuring Firebase Functions...');
      
      // Use the correct region - your function is in us-central1
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      
      developer.log('Functions instance configured for us-central1');

      // Step 5: Call the function
      developer.log('Step 4: Calling Cloud Function...');
      final callable = functions.httpsCallable(
        'generateRentalInsights',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 60), // Increased timeout
        ),
      );

      developer.log('Step 5: Executing callable...');
      final result = await callable.call();
      
      developer.log('Step 6: Received response');
      developer.log('Response data: ${result.data}');

      if (result.data == null) {
        throw Exception('No data returned from Cloud Function');
      }

      if (result.data['success'] == true && result.data['data'] != null) {
        setState(() {
          _insights = result.data['data'];
          _error = null;
          _debugInfo = 'Success! Data loaded at ${DateTime.now()}';
          _isLoading = false;
        });
      } else {
        throw Exception(result.data['error'] ?? 'No data returned from backend');
      }
      
    } on FirebaseFunctionsException catch (e) {
      developer.log('FirebaseFunctionsException: ${e.code}');
      developer.log('Message: ${e.message}');
      developer.log('Details: ${e.details}');
      
      setState(() {
        switch (e.code) {
          case 'unauthenticated':
            _error = 'Authentication Error';
            _debugInfo = '''
Error Code: ${e.code}
Message: ${e.message}
Details: ${e.details}

Possible causes:
1. Cloud Function not properly configured to accept authentication
2. Firebase Authentication not initialized in backend
3. Token not being passed correctly
4. CORS or security rules blocking the request

Please check your Cloud Function code.
            ''';
            break;
            
          case 'not-found':
            _error = 'Function Not Found';
            _debugInfo = '''
The Cloud Function 'generateRentalInsights' was not found.

Possible causes:
1. Function name mismatch
2. Function not deployed
3. Wrong region configured

Please verify:
- Function is deployed: firebase deploy --only functions
- Function name is exactly: generateRentalInsights
- Function region matches app configuration
            ''';
            break;
            
          case 'permission-denied':
            _error = 'Permission Denied';
            _debugInfo = 'Code: ${e.code}\nMessage: ${e.message}\nDetails: ${e.details}';
            break;
            
          case 'deadline-exceeded':
            _error = 'Request Timeout';
            _debugInfo = 'The request took too long. The function might be processing too much data or experiencing issues.';
            break;
            
          case 'internal':
            _error = 'Internal Server Error';
            _debugInfo = 'Code: ${e.code}\nMessage: ${e.message}\nDetails: ${e.details}';
            break;
            
          default:
            _error = 'Cloud Function Error: ${e.code}';
            _debugInfo = 'Message: ${e.message}\nDetails: ${e.details}';
        }
        _isLoading = false;
      });
      
    } catch (e, stackTrace) {
      developer.log('General error: $e');
      developer.log('Stack trace: $stackTrace');
      
      setState(() {
        _error = 'Unexpected Error';
        _debugInfo = 'Error: $e\n\nStack trace:\n$stackTrace';
        _isLoading = false;
      });
    }
  }

  Future<void> _testBasicCall() async {
    try {
      developer.log('Testing basic callable function...');
      
      // Test if we can call ANY function
      final functions = FirebaseFunctions.instance;
      final testCallable = functions.httpsCallable('generateRentalInsights');
      
      developer.log('Attempting call...');
      final result = await testCallable.call({'test': true});
      
      developer.log('Test call succeeded: ${result.data}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test call succeeded: ${result.data}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      developer.log('Test call failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test call failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.accentColor,
        title: const Text('Rental Insights', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => _showDebugInfo(),
            tooltip: 'Show Debug Info',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchReportData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentColor))
          : _error != null
              ? _buildErrorView()
              : _buildReportContent(),
    );
  }

  void _showDebugInfo() {
    final user = FirebaseAuth.instance.currentUser;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SingleChildScrollView(
          child: SelectableText(
            '''
Current User:
- UID: ${user?.uid ?? 'null'}
- Email: ${user?.email ?? 'null'}
- Email Verified: ${user?.emailVerified ?? false}
- Provider: ${user?.providerData.map((p) => p.providerId).join(', ') ?? 'none'}

Last Error:
${_error ?? 'None'}

Debug Info:
${_debugInfo ?? 'None'}

App Info:
- Build Mode: ${const bool.fromEnvironment('dart.vm.product') ? 'Release' : 'Debug'}
            ''',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _testBasicCall();
              Navigator.pop(context);
            },
            child: const Text('Test Function Call'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_debugInfo != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    _debugInfo!,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _fetchReportData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _showDebugInfo,
                    icon: const Icon(Icons.info),
                    label: const Text('Debug Info'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    if (_insights == null) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
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
            _buildMetricCard(
              'Total Rentals',
              '${data['totalRentals'] ?? 0}',
              Icons.format_list_numbered,
            ),
            _buildMetricCard(
              'Total Spent',
              'RM ${(data['totalSpent'] ?? 0.0).toStringAsFixed(2)}',
              Icons.payments,
            ),
            _buildMetricCard(
              'Money Saved',
              'RM ${(data['moneySaved'] ?? 0.0).toStringAsFixed(2)}',
              Icons.savings,
            ),
            _buildMetricCard(
              'Return Score',
              '${data['returnScore'] ?? 0}%',
              Icons.check_circle,
            ),

            const SizedBox(height: 24),
            const Text(
              'Monthly Spending',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildMonthlySpendingChart(data['monthlySpending']),

            const SizedBox(height: 24),
            const Text(
              'Rental Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildCategoryChart(data['categoryStats']),

            const SizedBox(height: 24),
            const Text(
              'Cost Comparison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildCostComparison(data['costComparison']),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.accentColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySpendingChart(dynamic monthlyData) {
    if (monthlyData == null || monthlyData is! List || monthlyData.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: const Text('No monthly data available'),
        ),
      );
    }

    final chartData = monthlyData
        .map((e) => MonthlyData(
              e['month'] as String? ?? '',
              (e['amount'] as num?)?.toDouble() ?? 0.0,
            ))
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 200,
          child: SfCartesianChart(
            primaryXAxis: CategoryAxis(),
            tooltipBehavior: TooltipBehavior(enable: true),
            series: <ColumnSeries<MonthlyData, String>>[
              ColumnSeries<MonthlyData, String>(
                dataSource: chartData,
                xValueMapper: (MonthlyData sales, _) => sales.month,
                yValueMapper: (MonthlyData sales, _) => sales.amount,
                color: AppColors.accentColor,
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChart(dynamic categoryData) {
    if (categoryData == null || categoryData is! List || categoryData.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: const Text('No category data available'),
        ),
      );
    }

    final chartData = categoryData
        .map((e) => CategoryData(
              e['name'] as String? ?? '',
              (e['count'] as num?)?.toInt() ?? 0,
            ))
        .toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 200,
          child: SfCircularChart(
            legend: Legend(
              isVisible: true,
              overflowMode: LegendItemOverflowMode.wrap,
              position: LegendPosition.bottom,
            ),
            series: <PieSeries<CategoryData, String>>[
              PieSeries<CategoryData, String>(
                dataSource: chartData,
                xValueMapper: (CategoryData item, _) => item.name,
                yValueMapper: (CategoryData item, _) => item.count,
                dataLabelMapper: (CategoryData item, _) => '${item.name}: ${item.count}',
                dataLabelSettings: const DataLabelSettings(isVisible: true),
                radius: '80%',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCostComparison(dynamic comparisonData) {
    if (comparisonData == null) {
      return Card(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: const Text('No cost comparison data available'),
        ),
      );
    }

    final double rental = ((comparisonData['rental'] as num?) ?? 0).toDouble();
    final double buying = ((comparisonData['buying'] as num?) ?? 0).toDouble();
    final int saved = (comparisonData['percentSaved'] as num?)?.toInt() ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Avg. Rental',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      'RM ${rental.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Avg. Buying Price',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      'RM ${buying.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: saved > 0 ? saved / 100.0 : 0,
                backgroundColor: Colors.grey[300],
                color: AppColors.accentColor,
                minHeight: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You saved ~$saved% by renting!',
              style: const TextStyle(
                color: AppColors.accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
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