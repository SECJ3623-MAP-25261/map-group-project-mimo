// ItemDetailScreen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import '../item_detail/widgets/image_carousel.dart';
import '../item_detail/widgets/item_action_widget.dart';
import '../item_detail/widgets/review_summary_widget.dart';
import 'package:profile_managemenr/sprint2/Rentee/searchRentee/search.dart';
import 'package:profile_managemenr/sprint2/Rentee/Booking Rentee/booking.dart'; // Booking screen

class ItemDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final images = item['images'] as List? ?? [];
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isVerySmallScreen = screenWidth < 340;

    final horizontalPadding = isVerySmallScreen
        ? 12.0
        : (isSmallScreen ? 14.0 : 16.0);
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
                ImageCarousel(images: images),
                SizedBox(height: verticalSpacing),
                _buildItemHeader(isSmallScreen, isVerySmallScreen),
                SizedBox(height: verticalSpacing),
                ReviewSummaryWidget(
                  itemId: item['id'],
                  itemName: item['name'] ?? 'Item',
                ),
                SizedBox(height: verticalSpacing),
                if (item['category'] != null || item['size'] != null)
                  _buildDetailsSection(isSmallScreen, isVerySmallScreen),
                if (item['category'] != null || item['size'] != null)
                  SizedBox(height: verticalSpacing),
                if (item['description'] != null &&
                    item['description'].toString().isNotEmpty)
                  _buildDescriptionSection(isSmallScreen, isVerySmallScreen),
                if (item['description'] != null &&
                    item['description'].toString().isNotEmpty)
                  SizedBox(height: sectionSpacing),

                // ✅ Item Actions (Book, Message, etc.)
                ItemActionsWidget(
                  item: item,
                  onBookPressed: () async {
                    // 🔓 Force portrait for booking screen only
                    await SystemChrome.setPreferredOrientations([
                      DeviceOrientation.portraitUp,
                    ]);

                    // Navigate to original booking screen
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingScreen(itemData: item),
                      ),
                    );

                    // 🔒 Restore system default after returning
                    await SystemChrome.setPreferredOrientations(
                      DeviceOrientation.values,
                    );
                  },
                ),

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
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_rounded, size: isSmallScreen ? 20 : 24),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Compare button with text
        TextButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SearchPage(preSelectedItem: item, startCompareMode: true),
              ),
            );
          },
          icon: Icon(
            Icons.compare_rounded,
            color: Colors.white,
            size: isSmallScreen ? 22 : 24,
          ),
          label: const Text("Compare", style: TextStyle(color: Colors.white)),
        ),
        // Share button
        IconButton(
          icon: Icon(Icons.share_rounded, size: isSmallScreen ? 22 : 24),
          tooltip: 'Share',
          onPressed: () {
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
        ),
      ],
    );
  }

  Widget _buildItemHeader(bool isSmallScreen, bool isVerySmallScreen) {
    final nameFontSize = isVerySmallScreen
        ? 20.0
        : (isSmallScreen ? 22.0 : 24.0);
    final priceFontSize = isVerySmallScreen
        ? 18.0
        : (isSmallScreen ? 19.0 : 20.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item['name'] ?? 'Unnamed Item',
          style: TextStyle(
            fontSize: nameFontSize,
            fontWeight: FontWeight.bold,
            color: AppColors.lightTextColor,
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
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.currency_exchange_rounded,
                    color: AppColors.accentColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "RM${((item['pricePerDay'] ?? 0) as num).toDouble().toStringAsFixed(2)}/day",
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
    return Container(
      padding: EdgeInsets.all(isVerySmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 16,
        children: [
          if (item['category'] != null)
            _buildDetailChip(Icons.category_rounded, item['category']),
          if (item['size'] != null)
            _buildDetailChip(Icons.straighten_rounded, item['size']),
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.accentColor),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }

  Widget _buildDescriptionSection(bool isSmallScreen, bool isVerySmallScreen) {
    return Container(
      padding: EdgeInsets.all(isVerySmallScreen ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        item['description'] ?? '',
        style: TextStyle(color: AppColors.lightTextColor),
      ),
    );
  }
}
