import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import 'dart:convert';
import '.../../date_formatter.dart';
import '.../../status_helper.dart';

class ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ReportCard({
    super.key,
    required this.report,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCardBackground : Colors.white;
    final textColor = isDark ? AppColors.darkTextColor : AppColors.lightTextColor;
    final hintColor = isDark ? AppColors.darkHintColor : AppColors.lightHintColor;

    final status = report['status'] ?? 'pending';
    final hasPhoto = report['photoBase64'] != null;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.only(bottom: screenWidth < 360 ? 12 : 16),
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
          // Only show actions if callbacks are provided
          if (onEdit != null || onDelete != null)
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding = isSmallScreen ? 12.0 : 16.0;

    return Padding(
      padding: EdgeInsets.all(horizontalPadding),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _StatusBadge(status: status),
                    _UserTypeBadge(userType: userType),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  category ?? 'Unknown Category',
                  style: TextStyle(
                    color: hintColor,
                    fontSize: isSmallScreen ? 11 : 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormatter.format(createdAt),
            style: TextStyle(
              color: hintColor,
              fontSize: isSmallScreen ? 10 : 12,
            ),
            textAlign: TextAlign.right,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: isSmallScreen ? 9 : 10,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 6 : 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        userType ?? 'User',
        style: TextStyle(
          color: AppColors.accentColor,
          fontSize: isSmallScreen ? 9 : 10,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding = isSmallScreen ? 12.0 : 16.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject ?? 'No subject',
            style: TextStyle(
              fontSize: isSmallScreen ? 15 : 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            details ?? 'No details provided',
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
              color: hintColor,
              height: 1.5,
            ),
            maxLines: 5, // Increased from 3 to show more content
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding = isSmallScreen ? 12.0 : 16.0;
    final imageHeight = isSmallScreen ? 130.0 : 150.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        horizontalPadding,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          base64Decode(photoBase64),
          height: imageHeight,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: imageHeight,
              color: isDark ? AppColors.darkCardBackground : Colors.grey[300],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.grey,
                    size: isSmallScreen ? 28 : 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
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
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ReportActions({
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding = isSmallScreen ? 12.0 : 16.0;

    // Filter out null callbacks
    final hasEdit = onEdit != null;
    final hasDelete = onDelete != null;

    if (!hasEdit && !hasDelete) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.all(horizontalPadding),
      child: Row(
        children: [
          if (hasEdit)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: Icon(Icons.edit_rounded, size: isSmallScreen ? 16 : 18),
                label: Text(
                  'Edit',
                  style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentColor,
                  side: BorderSide(color: AppColors.accentColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 10 : 12,
                  ),
                ),
              ),
            ),
          if (hasEdit && hasDelete) SizedBox(width: isSmallScreen ? 8 : 12),
          if (hasDelete)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: Icon(Icons.delete_rounded, size: isSmallScreen ? 16 : 18),
                label: Text(
                  'Delete',
                  style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.errorColor,
                  side: BorderSide(color: AppColors.errorColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 10 : 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}