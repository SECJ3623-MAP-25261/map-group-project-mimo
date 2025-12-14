
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:profile_managemenr/constants/app_colors.dart';
import '../models/item_model.dart';

class ItemGridCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback onTap;

  const ItemGridCard({
    Key? key,
    required this.item,
    required this.onTap,
  }) : super(key: key);

  Widget _buildImage() {
    final imageData = item.images.isNotEmpty ? item.images[0] : null;

    if (imageData == null) {
      return Container(
        color: Colors.grey[300],
        child: const Icon(Icons.image, size: 40, color: Colors.grey),
      );
    }

    if (imageData is String && imageData.startsWith('http')) {
      return Image.network(
        imageData,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported, size: 40),
        ),
      );
    }

    return Image.memory(
      base64Decode(imageData),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported, size: 40),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lightCardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: _buildImage(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                item.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.lightTextColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "RM${item.pricePerDay.toStringAsFixed(2)}/day",
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}