import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';

class ReviewViewRenterScreen extends StatefulWidget {
  final String itemId;
  final String itemName;

  const ReviewViewRenterScreen({
    super.key,
    required this.itemId,
    required this.itemName,
  });

  @override
  State<ReviewViewRenterScreen> createState() =>
      _ReviewViewRenterScreenState();
}

class _ReviewViewRenterScreenState extends State<ReviewViewRenterScreen> {
  String _filterRating = 'all';

  // ✅ FIXED: Use 'createdAt', and structure query correctly
  Stream<QuerySnapshot> _getReviewsStream() {
    Query query = FirebaseFirestore.instance
        .collection('reviews')
        .where('itemId', isEqualTo: widget.itemId);

    if (_filterRating != 'all') {
      int rating = int.parse(_filterRating);
      query = query.where('rating', isEqualTo: rating);
    }

    // ⚠️ orderBy() MUST come AFTER all where() clauses
    query = query.orderBy('createdAt', descending: true);

    return query.snapshots();
  }

  Future<Map<String, dynamic>> _calculateStats() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('itemId', isEqualTo: widget.itemId)
        .get();

    if (snapshot.docs.isEmpty) {
      return {
        'totalReviews': 0,
        'averageRating': 0.0,
        'ratingDistribution': {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      };
    }

    int total = snapshot.docs.length;
    double sum = 0;
    Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var doc in snapshot.docs) {
      int rating = doc['rating'] as int;
      sum += rating;
      distribution[rating] = (distribution[rating] ?? 0) + 1;
    }

    return {
      'totalReviews': total,
      'averageRating': sum / total,
      'ratingDistribution': distribution,
    };
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow[700]!;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return AppColors.accentColor;
    }
  }

  // ✅ FIXED: Accept dynamic + handle null, use 'createdAt'
  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';
    try {
      final now = DateTime.now();
      final date = (timestamp as Timestamp).toDate();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.accentColor,
        title: Text(
          'Reviews: ${widget.itemName}',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Stats Summary
          FutureBuilder<Map<String, dynamic>>(
            future: _calculateStats(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final stats = snapshot.data!;
              final totalReviews = stats['totalReviews'] as int;
              final averageRating = stats['averageRating'] as double;
              final distribution =
                  stats['ratingDistribution'] as Map<int, int>;

              return Container(
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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentColor,
                              ),
                            ),
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < averageRating.round()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                );
                              }),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalReviews review${totalReviews != 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: AppColors.lightHintColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [5, 4, 3, 2, 1].map((rating) {
                            final count = distribution[rating] ?? 0;
                            final percentage = totalReviews > 0
                                ? (count / totalReviews * 100)
                                : 0.0;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Text(
                                    '$rating',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.lightTextColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.star,
                                      size: 12, color: Colors.amber),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 100,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: percentage / 100,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: _getRatingColor(rating),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$count',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.lightHintColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // Filter Buttons
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('all', 'All'),
                _buildFilterChip('5', '5 Stars'),
                _buildFilterChip('4', '4 Stars'),
                _buildFilterChip('3', '3 Stars'),
                _buildFilterChip('2', '2 Stars'),
                _buildFilterChip('1', '1 Star'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Reviews List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getReviewsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading reviews: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 64,
                          color: AppColors.lightHintColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _filterRating == 'all'
                              ? 'No reviews yet'
                              : 'No $_filterRating star reviews',
                          style: const TextStyle(
                            color: AppColors.lightHintColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final review = doc.data() as Map<String, dynamic>;

                    return Card(
                      color: AppColors.lightCardBackground,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.accentColor,
                                  child: Text(
                                    (review['userName'] as String? ?? 'U')[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        review['userName'] ?? 'Anonymous',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.lightTextColor,
                                        ),
                                      ),
                                      Text(
                                        // ✅ Use 'createdAt'
                                        _getTimeAgo(review['createdAt']),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.lightHintColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRatingColor(review['rating'])
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _getRatingColor(review['rating']),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: _getRatingColor(review['rating']),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${review['rating']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              _getRatingColor(review['rating']),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (review['comment'] != null &&
                                (review['comment'] as String).isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                review['comment'],
                                style: const TextStyle(
                                  color: AppColors.lightTextColor,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              'Booking: ${review['bookingId']?.toString().substring(0, 8).toUpperCase() ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.lightHintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filterRating == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterRating = value;
          });
        },
        backgroundColor: AppColors.lightCardBackground,
        selectedColor: AppColors.accentColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.lightTextColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: Colors.white,
      ),
    );
  }
}