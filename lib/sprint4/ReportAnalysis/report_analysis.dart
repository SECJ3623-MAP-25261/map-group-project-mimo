// lib/accounts/profile/screen/spending_analysis_screen.dart
// Real-time Firestore with detailed list per view

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
  State<SpendingAnalysisScreen> createState() =>
      _SpendingAnalysisScreenState();
}

class _SpendingAnalysisScreenState extends State<SpendingAnalysisScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  String _selectedPeriod = 'monthly';
  Map<String, dynamic> _analysisData = {};
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRegenerating = false;

  StreamSubscription<DocumentSnapshot>? _analysisSubscription;

  @override
  void initState() {
    super.initState();
    _startRealTimeListener();
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

  Future<void> _regenerateAnalysis() async {
    setState(() {
      _isRegenerating = true;
    });

    try {
      final callable = _functions.httpsCallable('regenerateSpendingAnalysis');
      await callable.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Analysis updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to regenerate: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegenerating = false;
        });
      }
    }
  }

  Map<String, dynamic> _getCurrentPeriodData() {
    if (_analysisData.isEmpty) return {};

    switch (_selectedPeriod) {
      case 'weekly':
        return _analysisData['weekly'] ?? {};
      case 'category':
        return _analysisData['category'] ?? {};
      case 'monthly':
      default:
        return _analysisData['monthly'] ?? {};
    }
  }

  @override
  void dispose() {
    _analysisSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.accentColor,
        elevation: 0,
        title: Text(
          'Spending Analysis',
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isRegenerating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _isRegenerating ? null : _regenerateAnalysis,
            tooltip: 'Regenerate Analysis',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.accentColor),
                  const SizedBox(height: 20),
                  Text(
                    'Loading analysis...',
                    style: TextStyle(
                      color: AppColors.lightTextColor,
                      fontSize: isSmallScreen ? 14 : 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? _buildErrorState(isSmallScreen)
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                ),
    );
  }

  Widget _buildErrorState(bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: isSmallScreen ? 64 : 80,
              color: Colors.orange[400],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'No Analysis Available',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                color: AppColors.lightTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            Text(
              'Complete a booking to generate spending analysis',
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                color: AppColors.lightHintColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 20 : 24),
            ElevatedButton.icon(
              onPressed: _isRegenerating ? null : _regenerateAnalysis,
              icon: _isRegenerating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(_isRegenerating ? 'Generating...' : 'Generate Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 20 : 24,
                  vertical: isSmallScreen ? 12 : 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
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
        border: Border.all(color: AppColors.lightBorderColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          _buildPeriodButton('Monthly', 'monthly', isSmallScreen),
          _buildPeriodButton('Weekly', 'weekly', isSmallScreen),
          _buildPeriodButton('Category', 'category', isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value, bool isSmallScreen) {
    final isSelected = _selectedPeriod == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedPeriod != value) {
            setState(() => _selectedPeriod = value);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
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
              fontSize: isSmallScreen ? 13 : 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(bool isSmallScreen) {
    final summary = _analysisData['summary'] ?? {};
    final totalSpent = (summary['totalSpent'] ?? 0.0) as num;
    final totalBookings = (summary['totalBookings'] ?? 0) as int;
    final average = (summary['averagePerBooking'] ?? 0.0) as num;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Spent',
            'RM ${totalSpent.toStringAsFixed(2)}',
            Icons.payments_rounded,
            AppColors.accentColor,
            isSmallScreen,
          ),
        ),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Expanded(
          child: _buildSummaryCard(
            'Bookings',
            totalBookings.toString(),
            Icons.shopping_bag_rounded,
            Colors.blue,
            isSmallScreen,
          ),
        ),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Expanded(
          child: _buildSummaryCard(
            'Average',
            'RM ${average.toStringAsFixed(2)}',
            Icons.trending_up_rounded,
            Colors.green,
            isSmallScreen,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
      String label, String value, IconData icon, Color color, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isSmallScreen ? 20 : 24),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            label,
            style: TextStyle(
              color: AppColors.lightHintColor,
              fontSize: isSmallScreen ? 11 : 12,
            ),
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          Text(
            value,
            style: TextStyle(
              color: AppColors.lightTextColor,
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 12 : 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChart(bool isSmallScreen) {
    final periodData = _getCurrentPeriodData();
    final chartData = List<Map<String, dynamic>>.from(
      periodData['chartData'] ?? [],
    );

    if (chartData.isEmpty) {
      return _buildEmptyChart(isSmallScreen);
    }

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorderColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _selectedPeriod == 'category'
                    ? Icons.pie_chart_rounded
                    : Icons.bar_chart_rounded,
                color: AppColors.accentColor,
                size: isSmallScreen ? 20 : 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedPeriod == 'category'
                      ? 'Spending by Category'
                      : _selectedPeriod == 'weekly'
                          ? 'Weekly Spending'
                          : 'Monthly Spending',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: _selectedPeriod == 'category'
                ? _buildPieChart(chartData)
                : _buildBarChart(chartData, isSmallScreen),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data, bool isSmallScreen) {
    if (data.isEmpty) return const SizedBox();

    double maxValue = data.map((e) => (e['amount'] as num).toDouble()).reduce(
          (a, b) => a > b ? a : b,
        ) *
        1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                'RM ${(rod.toY).toStringAsFixed(2)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  final label = _selectedPeriod == 'weekly'
                      ? data[value.toInt()]['week']
                      : data[value.toInt()]['month'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label.toString(),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 11,
                        color: AppColors.lightHintColor,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  'RM${value.toInt()}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 9 : 10,
                    color: AppColors.lightHintColor,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.lightBorderColor.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        barGroups: data.asMap().entries.map((entry) {
          final amount = (entry.value['amount'] ?? 0) as num;
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: amount.toDouble(),
                color: AppColors.accentColor,
                width: isSmallScreen ? 12 : 16,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPieChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return const SizedBox();

    final colors = [
      AppColors.accentColor,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.amber,
    ];

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final amount = (item['amount'] ?? 0) as num;

          return PieChartSectionData(
            value: amount.toDouble(),
            title: '',
            color: colors[index % colors.length],
            radius: 70,
          );
        }).toList(),
      ),
    );
  }

  // 🔹 NEW: Detailed list below chart
  Widget _buildDetailsList(bool isSmallScreen) {
    final periodData = _getCurrentPeriodData();
    final chartData = List<Map<String, dynamic>>.from(
      periodData['chartData'] ?? [],
    );

    if (chartData.isEmpty) {
      return const SizedBox();
    }

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorderColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedPeriod == 'category'
                ? 'Category Details'
                : _selectedPeriod == 'weekly'
                    ? 'Weekly Breakdown'
                    : 'Monthly Breakdown',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.lightTextColor,
              fontSize: isSmallScreen ? 15 : 16,
            ),
          ),
          const SizedBox(height: 12),
          ...chartData.map((item) {
            String label;
            final amount = (item['amount'] ?? 0) as num;

            if (_selectedPeriod == 'category') {
              label = item['category'].toString();
            } else if (_selectedPeriod == 'weekly') {
              label = 'Week ${item['week']}';
            } else {
              label = item['month'].toString();
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: AppColors.lightTextColor,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                  ),
                  Text(
                    'RM ${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightTextColor,
                      fontSize: isSmallScreen ? 13 : 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorderColor.withOpacity(0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: isSmallScreen ? 48 : 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No data available',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete a booking to see your spending analysis',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}