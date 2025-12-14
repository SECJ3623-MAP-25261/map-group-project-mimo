import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import 'review_view_renter.dart';

class RenterAllReviewsScreen extends StatefulWidget {
  final String renterId;

  const RenterAllReviewsScreen({
    super.key,
    required this.renterId,
  });

  @override
  State<RenterAllReviewsScreen> createState() => _RenterAllReviewsScreenState();
}

class _RenterAllReviewsScreenState extends State<RenterAllReviewsScreen> {
  Future<List<Map<String, dynamic>>> _getItemsWithReviews() async {
    try {
      // Get all items for this renter
      final itemsSnapshot = await FirebaseFirestore.instance
          .collection('items')
          .where('renterId', isEqualTo: widget.renterId)
          .get();

      List<Map<String, dynamic>> itemsWithReviews = [];

      for (var itemDoc in itemsSnapshot.docs) {
        final itemData = itemDoc.data();
        final itemId = itemDoc.id;

        // Get review count and average for each item
        final reviewsSnapshot = await FirebaseFirestore.instance
            .collection('reviews')
            .where('itemId', isEqualTo: itemId)
            .get();

        if (reviewsSnapshot.docs.isNotEmpty) {
          int count = reviewsSnapshot.docs.length;
          double sum = 0;

          for (var reviewDoc in reviewsSnapshot.docs) {
            sum += (reviewDoc['rating'] as int);
          }

          itemsWithReviews.add({
            'id': itemId,
            'name': itemData['name'] ?? 'Unnamed Item',
            'image': itemData['images'] != null &&
                    (itemData['images'] as List).isNotEmpty
                ? itemData['images'][0]
                : null,
            'reviewCount': count,
            'averageRating': sum / count,
          });
        }
      }

      // Sort by review count (descending)
      itemsWithReviews.sort((a, b) => b['reviewCount'].compareTo(a['reviewCount']));

      return itemsWithReviews;
    } catch (e) {
      print('Error fetching items with reviews: $e');
      return [];
    }
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 3.5) return Colors.lightGreen;
    if (rating >= 2.5) return Colors.yellow[700]!;
    if (rating >= 1.5) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.accentColor,
        title: const Text(
          'Item Reviews',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getItemsWithReviews(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 80,
                    color: AppColors.lightHintColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No reviews yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.lightTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Reviews will appear here once\nrentees rate your items',
                    style: TextStyle(
                      color: AppColors.lightHintColor,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.lightCardBackground,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      icon: Icons.inventory,
                      value: '${items.length}',
                      label: 'Items\nReviewed',
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.lightBorderColor,
                    ),
                    _buildSummaryItem(
                      icon: Icons.rate_review,
                      value: '${items.fold<int>(0, (sum, item) => sum + (item['reviewCount'] as int))}',
                      label: 'Total\nReviews',
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.lightBorderColor,
                    ),
                    _buildSummaryItem(
                      icon: Icons.star,
                      value: items.isEmpty
                          ? '0.0'
                          : (items.fold<double>(
                                      0,
                                      (sum, item) =>
                                          sum +
                                          (item['averageRating'] as double)) /
                                  items.length)
                              .toStringAsFixed(1),
                      label: 'Avg\nRating',
                      color: Colors.amber,
                    ),
                  ],
                ),
              ),

              // Items List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final reviewCount = item['reviewCount'] as int;
                    final averageRating = item['averageRating'] as double;

                    return Card(
                      color: AppColors.lightCardBackground,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReviewViewRenterScreen(
                                itemId: item['id'],
                                itemName: item['name'],
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Item Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[300],
                                  child: item['image'] != null
                                      ? Image.network(
                                          item['image'],
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(Icons.image,
                                                color: Colors.grey);
                                          },
                                        )
                                      : const Icon(Icons.image,
                                          color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Item Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.lightTextColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getRatingColor(averageRating)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.star,
                                                size: 14,
                                                color:
                                                    _getRatingColor(averageRating),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                averageRating.toStringAsFixed(1),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: _getRatingColor(
                                                      averageRating),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '$reviewCount review${reviewCount != 1 ? 's' : ''}',
                                          style: const TextStyle(
                                            color: AppColors.lightHintColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Arrow Icon
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.lightHintColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? AppColors.accentColor, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.lightTextColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.lightHintColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}