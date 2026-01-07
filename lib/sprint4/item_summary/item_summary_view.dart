// lib/sprint4/item_summary/item_summary_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';

class ItemSummaryScreen extends StatelessWidget {
  final String itemId;

  const ItemSummaryScreen({super.key, required this.itemId});

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return {};
  }

  num _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? 0;
  }

  String _monthKey(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection('item_summaries').doc(itemId);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.accentColor,
        title: const Text('Item Summary', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ref.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentColor),
            );
          }
          if (snap.hasError) {
            return _errorView(context, snap.error.toString());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return _emptyView(context);
          }

          final d = snap.data!.data()!;
          final itemName = (d['itemName'] ?? 'Item').toString();
          final views = (d['views'] ?? 0) as num;
          final edits = (d['edits'] ?? 0) as num;

          final totalBookings = (d['bookingsTotal'] ?? 0) as num;
          final pending = (d['bookingsPending'] ?? 0) as num;
          final confirmed = (d['bookingsConfirmed'] ?? 0) as num;
          final ongoing = (d['bookingsOngoing'] ?? 0) as num;
          final completed = (d['bookingsCompleted'] ?? 0) as num;
          final cancelled = (d['bookingsCancelled'] ?? 0) as num;

          final totalRentalDays = (d['totalRentalDays'] ?? 0) as num;
          final totalEarnings = (d['totalEarnings'] ?? 0) as num;

          final earningsByMonth = _asMap(d['earningsByMonth']);

          final now = DateTime.now();
          final thisKey = _monthKey(now);
          final lastMonth = DateTime(now.year, now.month - 1, 1);
          final lastKey = _monthKey(lastMonth);

          final thisMonthEarnings = _num(_asMap(earningsByMonth[thisKey])['earnings']);
          final lastMonthEarnings = _num(_asMap(earningsByMonth[lastKey])['earnings']);

          final sortedMonths = earningsByMonth.keys.toList()..sort((a, b) => b.compareTo(a));

          print('ItemSummary itemId = $itemId');
          print('Doc keys = ${d.keys}');
          print('earningsByMonth = ${d['earningsByMonth']}');


          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _headerCard(itemName: itemName, d: d),
              const SizedBox(height: 12),

              _sectionTitle('Engagement'),
              _metricRow([
                _metricCard('Views', views.toStringAsFixed(0), Icons.visibility),
                _metricCard('Edits', edits.toStringAsFixed(0), Icons.edit),
              ]),

              const SizedBox(height: 12),
              _sectionTitle('Bookings'),
              _metricRow([
                _metricCard('Total', totalBookings.toStringAsFixed(0), Icons.receipt_long),
                _metricCard('Completed', completed.toStringAsFixed(0), Icons.check_circle),
              ]),
              const SizedBox(height: 10),
              _statusBreakdown(pending, confirmed, ongoing, completed, cancelled),

              const SizedBox(height: 12),
              _sectionTitle('Earnings'),
              _metricRow([
                _metricCard('Total Earnings (RM)', totalEarnings.toStringAsFixed(2), Icons.payments),
                _metricCard('Total Rental Days', totalRentalDays.toStringAsFixed(0), Icons.calendar_month),
              ]),

              const SizedBox(height: 12),
              _sectionTitle('Monthly Earnings'),
              _metricRow([
                _metricCard('This Month (RM)', thisMonthEarnings.toStringAsFixed(2), Icons.trending_up),
                _metricCard('Last Month (RM)', lastMonthEarnings.toStringAsFixed(2), Icons.history),
              ]),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: sortedMonths.isEmpty
                    ? Text(
                        'No monthly earnings yet.\nComplete a booking to generate monthly report.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      )
                    : Column(
                        children: sortedMonths.take(6).map((k) {
                          final m = _asMap(earningsByMonth[k]);
                          final e = _num(m['earnings']);
                          final days = _num(m['rentalDays']);
                          final b = _num(m['completedBookings']);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(k, style: TextStyle(color: Colors.grey[700])),
                                Text(
                                  'RM ${e.toStringAsFixed(2)} • ${days.toStringAsFixed(0)} days • ${b.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _headerCard({required String itemName, required Map<String, dynamic> d}) {
    final cat = (d['category'] ?? '-').toString();
    final size = (d['size'] ?? '-').toString();
    final price = (d['pricePerDay'] ?? 0).toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(itemName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('$cat • $size', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 6),
          Text('RM $price / day', style: const TextStyle(color: AppColors.accentColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
    );
  }

  Widget _metricRow(List<Widget> cards) {
    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 12),
        Expanded(child: cards[1]),
      ],
    );
  }

  Widget _metricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accentColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBreakdown(num pending, num confirmed, num ongoing, num completed, num cancelled) {
    Widget row(String label, num v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(v.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          row('Pending', pending),
          row('Confirmed', confirmed),
          row('Ongoing', ongoing),
          row('Completed', completed),
          row('Cancelled', cancelled),
        ],
      ),
    );
  }

  Widget _emptyView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_chart_outlined, size: 52, color: Colors.grey[400]),
            const SizedBox(height: 10),
            const Text('No summary yet', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              'This item has no stored report data yet.\nOpen the item, edit it, or create bookings to generate summary.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView(BuildContext context, String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text('Error loading summary: $msg', style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}
