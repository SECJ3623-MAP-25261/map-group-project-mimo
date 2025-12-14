import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import '../item_detail/widgets/image_carousel.dart';
import '../item_detail/widgets/item_action_widget.dart';
import '../item_detail/widgets/review_summary_widget.dart';
//import 'package:profile_managemenr/services/auth_service.dart';

class ItemDetailScreen extends StatelessWidget {
  final Map item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final images = item['images'] as List? ?? [];
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isVerySmallScreen = screenWidth < 340;

    // Responsive sizing
    final horizontalPadding = isVerySmallScreen ? 12.0 : (isSmallScreen ? 14.0 : 16.0);
    final verticalSpacing = isSmallScreen ? 12.0 : 16.0;
    final sectionSpacing = isSmallScreen ? 20.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: _buildAppBar(context, isSmallScreen),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Carousel
                ImageCarousel(images: images),
                SizedBox(height: verticalSpacing),

                // Name & Price
                _buildItemHeader(isSmallScreen, isVerySmallScreen),
                SizedBox(height: verticalSpacing),

                // Reviews Summary
                ReviewSummaryWidget(
                  itemId: item['id'],
                  itemName: item['name'] ?? 'Item',
                ),
                SizedBox(height: verticalSpacing),

                // Details (Category & Size)
                if (item['category'] != null || item['size'] != null)
                  _buildDetailsSection(isSmallScreen, isVerySmallScreen),

                if (item['category'] != null || item['size'] != null)
                  SizedBox(height: verticalSpacing),

                // Description
                if (item['description'] != null &&
                    item['description'].toString().isNotEmpty)
                  _buildDescriptionSection(isSmallScreen, isVerySmallScreen),

                if (item['description'] != null &&
                    item['description'].toString().isNotEmpty)
                  SizedBox(height: sectionSpacing),

                // Action Buttons
                ItemActionsWidget(item: item),
                
                // Bottom spacing for comfortable scrolling
                SizedBox(height: horizontalPadding),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isSmallScreen) {
    return AppBar(
      backgroundColor: AppColors.accentColor,
      elevation: 0,
      title: Text(
        item['name'] ?? 'Item',
        style: TextStyle(
          color: Colors.white,
          fontSize: isSmallScreen ? 18 : 20,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_rounded,
          size: isSmallScreen ? 20 : 24,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.share_rounded,
            size: isSmallScreen ? 22 : 24,
          ),
          onPressed: () {
            // Share functionality (optional)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Share feature coming soon'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
          tooltip: 'Share',
        ),
      ],
    );
  }

  Widget _buildItemHeader(bool isSmallScreen, bool isVerySmallScreen) {
    final nameFontSize = isVerySmallScreen ? 20.0 : (isSmallScreen ? 22.0 : 24.0);
    final priceFontSize = isVerySmallScreen ? 18.0 : (isSmallScreen ? 19.0 : 20.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item['name'] ?? 'Unnamed Item',
          style: TextStyle(
            fontSize: nameFontSize,
            fontWeight: FontWeight.bold,
            color: AppColors.lightTextColor,
            height: 1.2,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isVerySmallScreen ? 10 : 12,
                vertical: isVerySmallScreen ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.currency_exchange_rounded,
                    color: AppColors.accentColor,
                    size: isVerySmallScreen ? 18 : 20,
                  ),
                  SizedBox(width: isVerySmallScreen ? 4 : 6),
                  Text(
                    "RM${(item['pricePerDay'] ?? 0).toStringAsFixed(2)}/day",
                    style: TextStyle(
                      color: AppColors.accentColor,
                      fontSize: priceFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsSection(bool isSmallScreen, bool isVerySmallScreen) {
    final iconSize = isVerySmallScreen ? 14.0 : 16.0;
    final textSize = isVerySmallScreen ? 13.0 : 14.0;
    final containerPadding = isVerySmallScreen ? 10.0 : 12.0;
    final itemSpacing = isVerySmallScreen ? 12.0 : 16.0;

    return Container(
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.lightHintColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Wrap(
        spacing: itemSpacing,
        runSpacing: 8,
        children: [
          if (item['category'] != null)
            _buildDetailChip(
              icon: Icons.category_rounded,
              label: item['category'],
              iconSize: iconSize,
              textSize: textSize,
            ),
          if (item['size'] != null)
            _buildDetailChip(
              icon: Icons.straighten_rounded,
              label: item['size'],
              iconSize: iconSize,
              textSize: textSize,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required double iconSize,
    required double textSize,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: AppColors.accentColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.lightTextColor,
              fontSize: textSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(bool isSmallScreen, bool isVerySmallScreen) {
    final titleFontSize = isVerySmallScreen ? 15.0 : 16.0;
    final descriptionFontSize = isVerySmallScreen ? 13.0 : 14.0;

    return Container(
      padding: EdgeInsets.all(isVerySmallScreen ? 12.0 : 14.0),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.lightHintColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_rounded,
                size: isVerySmallScreen ? 18 : 20,
                color: AppColors.accentColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.lightTextColor,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 10),
          Text(
            item['description'],
            style: TextStyle(
              color: AppColors.lightTextColor,
              fontSize: descriptionFontSize,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}