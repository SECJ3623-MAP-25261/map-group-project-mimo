import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import '../item_detail/widgets/image_carousel.dart';
import '../item_detail/widgets/item_action_widget.dart';
import '../item_detail/widgets/review_summary_widget.dart';
import 'package:profile_managemenr/sprint2/Rentee/searchRentee/search.dart';

class ItemDetailScreen extends StatefulWidget {
  final Map item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  Map get item => widget.item;

  @override
  void initState() {
    super.initState();

    // Increment view count as soon as this page is opened.
    final dynamic rawId = item['id'] ?? item['itemId'];
    final String itemId = (rawId ?? '').toString();

    if (itemId.isNotEmpty) {
      // Item summary is now maintained fully by backend (Cloud Functions).
      // Log a lightweight view event; a Cloud Function will increment
      // item_summaries/{itemId}.views.
      FirebaseFirestore.instance.collection('item_views').add({
        'itemId': itemId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = item['images'] as List? ?? [];
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive breakpoints
    final isVerySmallScreen = screenWidth < 350;
    final isSmallScreen = screenWidth < 400;

    // Responsive sizing
    final horizontalPadding =
        isVerySmallScreen ? 12.0 : (isSmallScreen ? 14.0 : 16.0);
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
              crossAxisAlignment: CrossAxisAlignment.start,
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

                // Action Widget (Rent/Book)
                ItemActionsWidget(item: item),
                SizedBox(height: sectionSpacing),
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
        'Item Details',
        style: TextStyle(
          fontSize: isSmallScreen ? 18 : 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      foregroundColor: Colors.white,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_rounded, size: isSmallScreen ? 20 : 24),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Compare button
        TextButton.icon(
          onPressed: () {
            // Prepare item data with proper structure
            final itemData = Map<String, dynamic>.from(item);

            // Ensure 'id' field exists
            if (!itemData.containsKey('id')) {
              itemData['id'] = item['itemId'] ?? item['id'] ?? '';
            }

            // Ensure price field exists
            if (!itemData.containsKey('pricePerDay') &&
                !itemData.containsKey('price')) {
              itemData['pricePerDay'] = 0.0;
            }

            print(
              '📦 Passing item to compare: ${itemData['id']} - ${itemData['name']}',
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchPage(
                  preSelectedItem: itemData,
                  startCompareMode: true,
                ),
              ),
            );
          },
          icon: const Icon(Icons.compare_arrows, color: Colors.white),
          label: const Text('Compare', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildItemHeader(bool isSmallScreen, bool isVerySmallScreen) {
    final titleSize = isVerySmallScreen ? 18.0 : (isSmallScreen ? 20.0 : 24.0);
    final priceSize = isVerySmallScreen ? 16.0 : (isSmallScreen ? 18.0 : 20.0);

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              item['name'] ?? 'Item Name',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: AppColors.lightTextColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'RM ${item['pricePerDay'] ?? item['price'] ?? '0'}',
                style: TextStyle(
                  fontSize: priceSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentColor,
                ),
              ),
              Text(
                '/day',
                style: TextStyle(
                  fontSize: isVerySmallScreen ? 12 : 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (item['category'] != null)
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.category_rounded,
                    size: iconSize,
                    color: AppColors.accentColor,
                  ),
                  SizedBox(width: isVerySmallScreen ? 6 : 8),
                  Expanded(
                    child: Text(
                      item['category'].toString(),
                      style: TextStyle(
                        fontSize: textSize,
                        color: AppColors.lightTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (item['category'] != null && item['size'] != null)
            SizedBox(width: itemSpacing),
          if (item['size'] != null)
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.straighten_rounded,
                    size: iconSize,
                    color: AppColors.accentColor,
                  ),
                  SizedBox(width: isVerySmallScreen ? 6 : 8),
                  Expanded(
                    child: Text(
                      'Size ${item['size']}',
                      style: TextStyle(
                        fontSize: textSize,
                        color: AppColors.lightTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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
      padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
