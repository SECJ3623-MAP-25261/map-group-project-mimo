import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import '../item_detail/widgets/image_carousel.dart';
import '../item_detail/widgets/item_action_widget.dart';
import '../item_detail/widgets/review_summary_widget.dart';

class ItemDetailScreen extends StatelessWidget {
  final Map item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final images = item['images'] as List? ?? [];

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.accentColor,
        title: Text(item['name'] ?? 'Item'),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Carousel
              ImageCarousel(images: images),

              // Name & Price
              Text(
                item['name'] ?? 'Unnamed Item',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.lightTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "RM${(item['pricePerDay'] ?? 0).toStringAsFixed(2)}/day",
                style: const TextStyle(
                  color: AppColors.accentColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Reviews Summary
              ReviewSummaryWidget(
                itemId: item['id'],
                itemName: item['name'] ?? 'Item',
              ),
              const SizedBox(height: 16),

              // Details
              if (item['category'] != null || item['size'] != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightCardBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (item['category'] != null) ...[
                        const Icon(Icons.category,
                            size: 16, color: AppColors.lightHintColor),
                        const SizedBox(width: 4),
                        Text(
                          item['category'],
                          style:
                              const TextStyle(color: AppColors.lightTextColor),
                        ),
                      ],
                      if (item['category'] != null && item['size'] != null)
                        const SizedBox(width: 16),
                      if (item['size'] != null) ...[
                        const Icon(Icons.straighten,
                            size: 16, color: AppColors.lightHintColor),
                        const SizedBox(width: 4),
                        Text(
                          item['size'],
                          style:
                              const TextStyle(color: AppColors.lightTextColor),
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Description
              if (item['description'] != null &&
                  item['description'].toString().isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['description'],
                      style: const TextStyle(
                        color: AppColors.lightTextColor,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // Action Buttons
              ItemActionsWidget(item: item),
            ],
          ),
        ),
      ),
    );
  }
}