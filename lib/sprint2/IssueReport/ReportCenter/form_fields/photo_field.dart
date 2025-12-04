import 'dart:io';
import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';

class PhotoField extends StatelessWidget {
  final File? selectedImage;
  final String? imageBase64;
  final Function() onImagePicked;
  final Function() onImageRemoved;

  const PhotoField({
    super.key,
    this.selectedImage,
    this.imageBase64,
    required this.onImagePicked,
    required this.onImageRemoved,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCardBackground : Colors.white;
    final hintColor = isDark ? AppColors.darkHintColor : AppColors.lightHintColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Attach Photo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextColor : AppColors.lightTextColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(Optional)',
              style: TextStyle(
                color: hintColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        if (selectedImage == null)
          InkWell(
            onTap: onImagePicked,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorderColor : AppColors.lightBorderColor,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 40,
                    color: AppColors.accentColor.withOpacity(0.7),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to add photo',
                    style: TextStyle(
                      color: hintColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Max size: 1MB',
                    style: TextStyle(
                      color: hintColor.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    selectedImage!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDark ? AppColors.darkCardBackground : Colors.grey[300],
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.grey, size: 40),
                            SizedBox(height: 8),
                            Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    onTap: onImageRemoved,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.errorColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}