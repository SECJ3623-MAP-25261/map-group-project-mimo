import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import 'package:profile_managemenr/sprint2/renter_dashboard/review_view_renter.dart';

class ReviewSummaryWidget extends StatelessWidget {
  final String itemId;
  final String itemName;

  const ReviewSummaryWidget({
    Key? key,
    required this.itemId,
    required this.itemName,
  }) : super(key: key);

  Future<Map> _getReviewStats() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('itemId', isEqualTo: itemId)
          .get();

      if (snapshot.docs.isEmpty) {
        return {'count': 0, 'average': 0.0};
      }

      int total = snapshot.docs.length;
      double sum = 0;

      for (var doc in snapshot.docs) {
        sum += (doc['rating'] as int);
      }

      return {
        'count': total,
        'average': sum / total,
      };
    } catch (e) {
      return {'count': 0, 'average': 0.0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map>(
      future: _getReviewStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;
        final count = stats['count'] as int;
        final average = stats['average'] as double;

        if (count == 0) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightCardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightBorderColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.rate_review_outlined,
                    color: AppColors.lightHintColor),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'No reviews yet',
                    style: TextStyle(
                      color: AppColors.lightHintColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewViewRenterScreen(
                          itemId: itemId,
                          itemName: itemName,
                        ),
                      ),
                    );
                  },
                  child: const Text('View'),
                ),
              ],
            ),
          );
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReviewViewRenterScreen(
                  itemId: itemId,
                  itemName: itemName,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightCardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightBorderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 24),
                      const SizedBox(width: 4),
                      Text(
                        average.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$count review${count != 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightTextColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tap to see all reviews',
                        style: TextStyle(
                          color: AppColors.lightHintColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.lightHintColor),
              ],
            ),
          ),
        );
      },
    );
  }
}