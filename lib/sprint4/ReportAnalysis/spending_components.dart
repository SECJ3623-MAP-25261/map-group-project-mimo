import 'package:flutter/material.dart';
import '../../../../constants/app_colors.dart';

// --- PERIOD SELECTOR ---
class PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final Function(String) onChanged;

  const PeriodSelector({super.key, required this.selectedPeriod, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildBtn('Monthly', 'monthly'),
          _buildBtn('Weekly', 'weekly'),
          _buildBtn('Category', 'category'),
        ],
      ),
    );
  }

  Widget _buildBtn(String label, String value) {
    bool isSelected = selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
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
}

// --- SUMMARY CARDS ---
class SummaryCards extends StatelessWidget {
  final Map<String, dynamic> summary;
  const SummaryCards({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
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
}

// --- BREAKDOWN LIST ---
class BreakdownList extends StatelessWidget {
  final String selectedPeriod;
  final Map<String, dynamic> analysisData;
  final String? selectedWeeklyMonth;

  const BreakdownList({super.key, required this.selectedPeriod, required this.analysisData, this.selectedWeeklyMonth});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> listData = [];
    
    if (selectedPeriod == 'weekly') {
      final List groups = analysisData['weeklyGroups'] ?? [];
      final current = groups.firstWhere((g) => g['monthName'] == selectedWeeklyMonth, orElse: () => {});
      listData = List<Map<String, dynamic>>.from(current['weeks'] ?? []);
    } else if (selectedPeriod == 'monthly') {
      listData = List<Map<String, dynamic>>.from(analysisData['monthly']?['chartData'] ?? []);
    } else {
      listData = List<Map<String, dynamic>>.from(analysisData['category']?['chartData'] ?? []);
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
}