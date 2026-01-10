// lib/accounts/profile/screen/spending_analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../../constants/app_colors.dart';
import 'dart:async';

class SpendingAnalysisScreen extends StatefulWidget {
  const SpendingAnalysisScreen({super.key});

  @override
  State<SpendingAnalysisScreen> createState() => _SpendingAnalysisScreenState();
}

class _SpendingAnalysisScreenState extends State<SpendingAnalysisScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  String _selectedPeriod = 'monthly';
  String? _selectedWeeklyMonth; // Track which month's weeks we are looking at
  Map<String, dynamic> _analysisData = {};
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRegenerating = false;

  final List<Color> _categoryColors = [
    AppColors.accentColor,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.amber,
  ];

  StreamSubscription<DocumentSnapshot>? _analysisSubscription;

  @override
  void initState() {
    super.initState();
    _startRealTimeListener();
    _regenerateAnalysis();
  }

  void _startRealTimeListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User not authenticated';
      });
      return;
    }

    _analysisSubscription = _firestore
        .collection('spendingAnalysis')
        .doc(currentUser.uid)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        setState(() {
          _analysisData = {};
          _isLoading = false;
          _errorMessage = 'No analysis data available.';
        });
        return;
      }

      final data = snapshot.data()!;
      setState(() {
        _analysisData = data;
        _isLoading = false;
        _errorMessage = null;
        
        // Auto-select the latest month for weekly view if not already set
        if (_selectedWeeklyMonth == null && data['weeklyGroups'] != null) {
          final List groups = data['weeklyGroups'];
          if (groups.isNotEmpty) {
            _selectedWeeklyMonth = groups.first['monthName'];
          }
        }
      });
    }, onError: (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load analysis: $error';
          _isLoading = false;
        });
      }
    });
  }

    Future<void> _regenerateAnalysis({bool silent = true}) async {
  if (!silent) setState(() => _isRegenerating = true);

  try {
    final callable = _functions.httpsCallable('regenerateSpendingAnalysis');
    await callable.call();
    
  } catch (e) {
    debugPrint("Silent update failed: $e");
  } finally {
    if (!silent) setState(() => _isRegenerating = false);
  }
}

  @override
  void dispose() {
    _analysisSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.accentColor,
        elevation: 0,
        title: const Text('Spending Analysis', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isRegenerating 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _isRegenerating ? null : _regenerateAnalysis,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState(isSmallScreen)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildPeriodSelector(isSmallScreen),
                      const SizedBox(height: 16),
                      _buildSummaryCards(isSmallScreen),
                      const SizedBox(height: 20),
                      _buildChart(isSmallScreen),
                      const SizedBox(height: 16),
                      _buildDetailsList(isSmallScreen),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPeriodSelector(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildPeriodButton('Monthly', 'monthly'),
          _buildPeriodButton('Weekly', 'weekly'),
          _buildPeriodButton('Category', 'category'),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    bool isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.lightTextColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(bool isSmallScreen) {
    final summary = _analysisData['summary'] ?? {};
    return Row(
      children: [
        _card('Total Spent', 'RM ${(summary['totalSpent'] ?? 0).toStringAsFixed(2)}', Icons.payments, AppColors.accentColor),
        const SizedBox(width: 8),
        _card('Bookings', '${summary['totalBookings'] ?? 0}', Icons.shopping_bag, Colors.blue),
        const SizedBox(width: 8),
        _card('Average', 'RM ${(summary['averagePerBooking'] ?? 0).toStringAsFixed(2)}', Icons.analytics, Colors.green),
      ],
    );
  }

  Widget _card(String title, String val, IconData icon, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Icon(icon, color: col, size: 20),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(bool isSmallScreen) {
    if (_selectedPeriod == 'weekly') {
      final List groups = _analysisData['weeklyGroups'] ?? [];
      if (groups.isEmpty) return _buildEmptyChart();

      final currentGroup = groups.firstWhere(
        (g) => g['monthName'] == _selectedWeeklyMonth,
        orElse: () => groups.first,
      );
      final List weeks = currentGroup['weeks'] ?? [];

      return _chartContainer(
        title: 'Weekly Spending',
        headerAction: DropdownButton<String>(
          value: _selectedWeeklyMonth,
          underline: const SizedBox(),
          items: groups.map<DropdownMenuItem<String>>((g) {
            return DropdownMenuItem(value: g['monthName'], child: Text(g['monthName'], style: const TextStyle(fontSize: 14)));
          }).toList(),
          onChanged: (val) => setState(() => _selectedWeeklyMonth = val),
        ),
        child: _buildBarChart(weeks.cast<Map<String, dynamic>>()),
      );
    } else if (_selectedPeriod == 'category') {
      final List data = _analysisData['category']?['chartData'] ?? [];
      return _chartContainer(title: 'By Category', child: _buildPieChart(data.cast<Map<String, dynamic>>()));
    } else {
      final List data = _analysisData['monthly']?['chartData'] ?? [];
      return _chartContainer(title: 'Monthly Spending', child: _buildBarChart(data.cast<Map<String, dynamic>>(), isMonthly: true));
    }
  }

  Widget _chartContainer({required String title, required Widget child, Widget? headerAction}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (headerAction != null) headerAction,
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(height: 200, child: child),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data, {bool isMonthly = false}) {
    if (data.isEmpty) return const Center(child: Text("No data"));
    double maxY = data.map((e) => (e['amount'] as num).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2;
    if (maxY == 0) maxY = 100;

    return BarChart(
      BarChartData(
        maxY: maxY,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                int i = val.toInt();
                if (i >= 0 && i < data.length) {
                  return Text(isMonthly ? data[i]['month'] : data[i]['label'], style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (v, m) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10)))),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: data.asMap().entries.map((e) {
          return BarChartGroupData(x: e.key, barRods: [
            BarChartRodData(toY: (e.value['amount'] as num).toDouble(), color: AppColors.accentColor, width: 16, borderRadius: BorderRadius.circular(4)),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildPieChart(List<Map<String, dynamic>> data) {
    return PieChart(PieChartData(
      sections: data.asMap().entries.map((e) {
        return PieChartSectionData(
          value: (e.value['amount'] as num).toDouble(),
          title: '${e.value['percentage'].toStringAsFixed(0)}%',
          color: _categoryColors[e.key % _categoryColors.length],
          radius: 50,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        );
      }).toList(),
    ));
  }

  Widget _buildDetailsList(bool isSmallScreen) {
    List<Map<String, dynamic>> listData = [];
    if (_selectedPeriod == 'weekly') {
      final List groups = _analysisData['weeklyGroups'] ?? [];
      final current = groups.firstWhere((g) => g['monthName'] == _selectedWeeklyMonth, orElse: () => {});
      listData = List<Map<String, dynamic>>.from(current['weeks'] ?? []);
    } else if (_selectedPeriod == 'monthly') {
      listData = List<Map<String, dynamic>>.from(_analysisData['monthly']?['chartData'] ?? []);
    } else {
      listData = List<Map<String, dynamic>>.from(_analysisData['category']?['chartData'] ?? []);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Breakdown Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...listData.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(item['label'] ?? item['month'] ?? item['category'] ?? 'Unknown'),
                trailing: Text('RM ${(item['amount'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            )),
      ],
    );
  }

  Widget _buildErrorState(bool isSmallScreen) => Center(child: Text(_errorMessage ?? 'Error'));
  Widget _buildEmptyChart() => const Center(child: Text("No data for this period"));
}