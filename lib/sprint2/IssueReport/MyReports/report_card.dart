// ============================================
// FILE 2: lib/accounts/profile/widgets/report_card.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import 'dart:convert';
import '.../../date_formatter.dart';
import '.../../status_helper.dart';

class ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ReportCard({
    super.key,
    required this.report,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCardBackground : Colors.white;
    final textColor = isDark ? AppColors.darkTextColor : AppColors.lightTextColor;
    final hintColor = isDark ? AppColors.darkHintColor : AppColors.lightHintColor;

    final status = report['status'] ?? 'pending';
    final hasPhoto = report['photoBase64'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ReportHeader(
            status: status,
            userType: report['userType'],
            category: report['category'],
            createdAt: report['createdAt'],
            textColor: textColor,
            hintColor: hintColor,
          ),
          _ReportContent(
            subject: report['subject'],
            details: report['details'],
            textColor: textColor,
            hintColor: hintColor,
          ),
          if (hasPhoto)
            _ReportPhoto(
              photoBase64: report['photoBase64']!,
              isDark: isDark,
            ),
          _ReportActions(
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ReportHeader extends StatelessWidget {
  final String status;
  final String? userType;
  final String? category;
  final dynamic createdAt;
  final Color textColor;
  final Color hintColor;

  const _ReportHeader({
    required this.status,
    required this.userType,
    required this.category,
    required this.createdAt,
    required this.textColor,
    required this.hintColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusBadge(status: status),
                    const SizedBox(width: 8),
                    _UserTypeBadge(userType: userType),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  category ?? 'Unknown Category',
                  style: TextStyle(
                    color: hintColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormatter.format(createdAt),
            style: TextStyle(
              color: hintColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = StatusHelper.getColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _UserTypeBadge extends StatelessWidget {
  final String? userType;

  const _UserTypeBadge({required this.userType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        userType ?? 'User',
        style: TextStyle(
          color: AppColors.accentColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ReportContent extends StatelessWidget {
  final String? subject;
  final String? details;
  final Color textColor;
  final Color hintColor;

  const _ReportContent({
    required this.subject,
    required this.details,
    required this.textColor,
    required this.hintColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject ?? 'No subject',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            details ?? 'No details provided',
            style: TextStyle(
              fontSize: 14,
              color: hintColor,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ReportPhoto extends StatelessWidget {
  final String photoBase64;
  final bool isDark;

  const _ReportPhoto({
    required this.photoBase64,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          base64Decode(photoBase64),
          height: 150,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 150,
              color: isDark ? AppColors.darkCardBackground : Colors.grey[300],
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Failed to load image'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReportActions extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReportActions({
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentColor,
                side: BorderSide(color: AppColors.accentColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete, size: 18),
              label: const Text('Delete'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.errorColor,
                side: BorderSide(color: AppColors.errorColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}