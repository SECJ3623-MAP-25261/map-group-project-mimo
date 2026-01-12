import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../constants/app_colors.dart';

class AnalysisChartSection extends StatelessWidget {
  final String selectedPeriod;
  final Map<String, dynamic> analysisData;
  final String? selectedWeeklyMonth;
  final Function(String?) onMonthChanged;

  const AnalysisChartSection({
    super.key,
    required this.selectedPeriod,
    required this.analysisData,
    this.selectedWeeklyMonth,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedPeriod == 'weekly') {
      final List groups = analysisData['weeklyGroups'] ?? [];
      if (groups.isEmpty) return const Center(child: Text("No data"));

      final currentGroup = groups.firstWhere(
        (g) => g['monthName'] == selectedWeeklyMonth,
        orElse: () => groups.first,
      );
      final List weeks = currentGroup['weeks'] ?? [];

      return _container(
        title: 'Weekly Spending',
        headerAction: DropdownButton<String>(
          value: selectedWeeklyMonth,
          underline: const SizedBox(),
          items: groups.map<DropdownMenuItem<String>>((g) {
            return DropdownMenuItem(value: g['monthName'], child: Text(g['monthName'], style: const TextStyle(fontSize: 14)));
          }).toList(),
          onChanged: onMonthChanged,
        ),
        child: _BarChartWidget(data: weeks.cast<Map<String, dynamic>>()),
      );
    } else if (selectedPeriod == 'category') {
      final List data = analysisData['category']?['chartData'] ?? [];
      return _container(title: 'By Category', child: _PieChartWidget(data: data.cast<Map<String, dynamic>>()));
    } else {
      final List data = analysisData['monthly']?['chartData'] ?? [];
      return _container(title: 'Monthly Spending', child: _BarChartWidget(data: data.cast<Map<String, dynamic>>(), isMonthly: true));
    }
  }

  Widget _container({required String title, required Widget child, Widget? headerAction}) {
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
}

//bar chart logic
class _BarChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final bool isMonthly;
  const _BarChartWidget({required this.data, this.isMonthly = false});

  @override
  Widget build(BuildContext context) {
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
}

//pie chart logic
class _PieChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  _PieChartWidget({required this.data});

  final List<Color> colors = [AppColors.accentColor, Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.pink, Colors.teal, Colors.amber];

  @override
  Widget build(BuildContext context) {
    return PieChart(PieChartData(
      sections: data.asMap().entries.map((e) {
        return PieChartSectionData(
          value: (e.value['amount'] as num).toDouble(),
          title: '${e.value['percentage'].toStringAsFixed(0)}%',
          color: colors[e.key % colors.length],
          radius: 50,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        );
      }).toList(),
    ));
  }
}