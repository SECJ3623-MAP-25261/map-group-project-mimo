import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:async';

import '../../../../constants/app_colors.dart';
import 'spending_components.dart';
import 'spending_charts.dart';

class SpendingAnalysisScreen extends StatefulWidget {
  const SpendingAnalysisScreen({super.key});

  @override
  State<SpendingAnalysisScreen> createState() => _SpendingAnalysisScreenState();
}

class _SpendingAnalysisScreenState extends State<SpendingAnalysisScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  String _selectedPeriod = 'monthly';
  String? _selectedWeeklyMonth;
  Map<String, dynamic> _analysisData = {};
  bool _isLoading = true;
  String? _errorMessage;
  bool _isRegenerating = false;

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
      debugPrint("Update failed: $e");
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
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.accentColor,
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
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Period Switcher (Monthly/Weekly/Category)
                      PeriodSelector(
                        selectedPeriod: _selectedPeriod,
                        onChanged: (val) => setState(() => _selectedPeriod = val),
                      ),
                      const SizedBox(height: 16),
                      
                      //Small Summary Cards
                      SummaryCards(summary: _analysisData['summary'] ?? {}),
                      const SizedBox(height: 20),
                      
                      //The Big Chart
                      AnalysisChartSection(
                        selectedPeriod: _selectedPeriod,
                        analysisData: _analysisData,
                        selectedWeeklyMonth: _selectedWeeklyMonth,
                        onMonthChanged: (val) => setState(() => _selectedWeeklyMonth = val),
                      ),
                      const SizedBox(height: 16),
                      
                      //List of details at the bottom
                      BreakdownList(
                        selectedPeriod: _selectedPeriod,
                        analysisData: _analysisData,
                        selectedWeeklyMonth: _selectedWeeklyMonth,
                      ),
                    ],
                  ),
                ),
    );
  }
}