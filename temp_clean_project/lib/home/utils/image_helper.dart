import 'package:flutter/material.dart';
import 'dart:convert';

class ImageHelper {
  static Widget buildImage(
    dynamic imageData, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    if (imageData == null) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.image, size: 60, color: Colors.grey),
      );
    }

    if (imageData is String) {
      if (imageData.startsWith('http')) {
        return Image.network(
          imageData,
          fit: fit,
          width: width,
          height: height,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: const Icon(Icons.image_not_supported, size: 60),
            );
          },
        );
      } else {
        try {
          return Image.memory(
            base64Decode(imageData),
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, size: 60),
              );
            },
          );
        } catch (e) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 60),
          );
        }
      }
    }

    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Icon(Icons.image, size: 60, color: Colors.grey),
    );
  }
}