import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:profile_managemenr/constants/app_colors.dart';
import '.../../theme_helper.dart';

class PhotoSection extends StatelessWidget {
  final String? imageBase64;
  final File? selectedImage;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final ThemeHelper theme;

  const PhotoSection({
    super.key,
    required this.imageBase64,
    required this.selectedImage,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textColor,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        if (imageBase64 == null && selectedImage == null)
          _EmptyPhotoPlaceholder(onPickImage: onPickImage, theme: theme)
        else
          _PhotoPreview(
            imageBase64: imageBase64,
            selectedImage: selectedImage,
            onRemoveImage: onRemoveImage,
            theme: theme,
          ),
      ],
    );
  }
}

class _EmptyPhotoPlaceholder extends StatelessWidget {
  final VoidCallback onPickImage;
  final ThemeHelper theme;

  const _EmptyPhotoPlaceholder({
    required this.onPickImage,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPickImage,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.borderColor, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 40,
              color: AppColors.accentColor,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to add photo',
              style: TextStyle(color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  final String? imageBase64;
  final File? selectedImage;
  final VoidCallback onRemoveImage;
  final ThemeHelper theme;

  const _PhotoPreview({
    required this.imageBase64,
    required this.selectedImage,
    required this.onRemoveImage,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.cardBg,
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
            child: selectedImage != null
                ? Image.file(
                    selectedImage!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  )
                : Image.memory(
                    base64Decode(imageBase64!),
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: InkWell(
              onTap: onRemoveImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.errorColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}