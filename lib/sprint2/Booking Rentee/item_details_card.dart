// lib/sprint2/Booking/widgets/item_details_card.dart

import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import 'dart:convert';

class ItemDetailsCard extends StatefulWidget {
  final String itemName;
  final List<dynamic> itemImages;

  const ItemDetailsCard({
    super.key,
    required this.itemName,
    required this.itemImages,
  });

  @override
  State<ItemDetailsCard> createState() => _ItemDetailsCardState();
}

class _ItemDetailsCardState extends State<ItemDetailsCard> {
  late PageController _imagePageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  void _showFullScreenImage(String imageData) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 1.0,
                maxScale: 4.0,
                child: imageData.startsWith('http')
                    ? Image.network(imageData, fit: BoxFit.contain)
                    : Image.memory(base64Decode(imageData), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String imageData) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: imageData.startsWith('http')
          ? Image.network(
              imageData,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.lightInputFillColor,
                child: const Center(
                  child: Icon(Icons.broken_image,
                      size: 50, color: AppColors.lightHintColor),
                ),
              ),
            )
          : Image.memory(
              base64Decode(imageData),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.lightInputFillColor,
                child: const Center(
                  child: Icon(Icons.broken_image,
                      size: 50, color: AppColors.lightHintColor),
                ),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Attire Name Display
        const Text(
          'Attire Name',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.lightTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.lightInputFillColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.lightBorderColor),
          ),
          child: Text(
            widget.itemName,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.lightTextColor,
            ),
          ),
        ),
        
        const SizedBox(height: 16),

        // Item Images Section
        const Text(
          'Item Images',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.lightTextColor,
          ),
        ),
        const SizedBox(height: 8),

        if (widget.itemImages.isEmpty)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lightBorderColor),
                color: AppColors.lightInputFillColor,
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported,
                        size: 50, color: AppColors.lightHintColor),
                    SizedBox(height: 8),
                    Text('No images available',
                        style: TextStyle(
                            color: AppColors.lightHintColor, fontSize: 14)),
                  ],
                ),
              ),
            ),
          )
        else
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: PageView.builder(
                    controller: _imagePageController,
                    itemCount: widget.itemImages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      final imageData = widget.itemImages[index].toString();
                      return GestureDetector(
                        onTap: () => _showFullScreenImage(imageData),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.lightBorderColor,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _buildImage(imageData),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Dots indicator
              if (widget.itemImages.length > 1) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.itemImages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? AppColors.accentColor
                            : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Swipe to view more • Tap to enlarge',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.lightHintColor,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}