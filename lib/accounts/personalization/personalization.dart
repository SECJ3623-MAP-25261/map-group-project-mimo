// lib/accounts/profile/screen/personalization.dart
import 'package:flutter/material.dart';
import 'package:profile_managemenr/accounts/profile/screen/profile/profile.dart';
import '../../../../constants/app_colors.dart';
import '../../../../sprint2/renter_dashboard/add_items.dart';
import '../../../../sprint2/renter_dashboard/items_listed.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:profile_managemenr/sprint2/renter_dashboard/booking_request.dart';
import 'package:profile_managemenr/sprint2/renter_dashboard/renter_all_review_screen.dart';
import 'package:profile_managemenr/sprint2/HistoryRentee/history_rentee.dart';

class RenterDashboard extends StatelessWidget {
  final Map<String, dynamic> userData;

  const RenterDashboard({super.key, required this.userData});

  // Stream to count pending requests for the current renter
  Stream<int> getPendingRequestsCount(String renterId) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('renterId', isEqualTo: renterId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.length;
        });
  }

  // Stream for dynamic earnings
  Stream<double> getEarningsStream(String renterId) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('renterId', isEqualTo: renterId)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) {
          double total = 0.0;
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            total += (data['finalFee'] as num?)?.toDouble() ?? 0.0;
          }
          return total;
        });
  }

  @override
  Widget build(BuildContext context) {
    String name = userData['fullName'] ?? 'User';
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(body: const Center(child: Text('Not signed in')));
    }
    final String currentUserId = user.uid;

    // Responsive variables
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isVerySmallScreen = screenWidth < 340;

    // Adaptive sizing
    final containerPadding = isVerySmallScreen ? 16.0 : (isSmallScreen ? 20.0 : 24.0);
    final outerPadding = isSmallScreen ? 12.0 : 16.0;
    final verticalSpacing = isSmallScreen ? 16.0 : 20.0;
    final titleFontSize = isVerySmallScreen ? 18.0 : (isSmallScreen ? 20.0 : 22.0);
    final subtitleFontSize = isSmallScreen ? 12.0 : 14.0;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(outerPadding),
            child: Container(
              padding: EdgeInsets.all(containerPadding),
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? screenWidth : 400,
              ),
              decoration: BoxDecoration(
                color: AppColors.lightCardBackground,
                borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Welcome Header
                  Text(
                    'Welcome, $name 👕',
                    style: TextStyle(
                      color: AppColors.accentColor,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  Text(
                    'Manage your items, requests, and earnings.',
                    style: TextStyle(
                      color: AppColors.lightHintColor,
                      fontSize: subtitleFontSize,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                  SizedBox(height: verticalSpacing),

                  // Stats Row
                  _buildStatsRow(context, currentUserId, isSmallScreen, isVerySmallScreen),
                  SizedBox(height: isSmallScreen ? 20 : 30),

                  // Action buttons
                  _buildMenuButton(
                    context,
                    'Add New Item',
                    Icons.add_rounded,
                    currentUserId,
                    isSmallScreen,
                  ),
                  _buildMenuButton(
                    context,
                    'View Rental Requests',
                    Icons.inventory_rounded,
                    currentUserId,
                    isSmallScreen,
                  ),
                  _buildMenuButton(
                    context,
                    'Transaction History',
                    Icons.receipt_long_rounded,
                    currentUserId,
                    isSmallScreen,
                  ),
                  _buildMenuButton(
                    context,
                    'Help & Support',
                    Icons.help_outline_rounded,
                    currentUserId,
                    isSmallScreen,
                  ),
                  _buildMenuButton(
                    context,
                    'View Item Reviews',
                    Icons.star_rate_rounded,
                    currentUserId,
                    isSmallScreen,
                  ),

                  SizedBox(height: verticalSpacing),

                  // Back to Profile Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ProfileScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 24 : 30,
                        vertical: isSmallScreen ? 10 : 12,
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Back to Profile 👤',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 20),
                  
                  // Footer
                  Text(
                    'Campus Closet © 2025',
                    style: TextStyle(
                      color: AppColors.lightHintColor,
                      fontSize: isSmallScreen ? 11 : 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    String currentUserId,
    bool isSmallScreen,
    bool isVerySmallScreen,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Items Listed
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('items')
              .where('renterId', isEqualTo: currentUserId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return _buildClickableStat(
                context,
                value: '...',
                label: 'Items Listed',
                page: YourItemsPage(renterId: currentUserId),
                isSmallScreen: isSmallScreen,
                isVerySmallScreen: isVerySmallScreen,
              );
            }
            int itemCount = snapshot.data!.docs.length;
            return _buildClickableStat(
              context,
              value: '$itemCount',
              label: 'Items Listed',
              page: YourItemsPage(renterId: currentUserId),
              isSmallScreen: isSmallScreen,
              isVerySmallScreen: isVerySmallScreen,
            );
          },
        ),

        // Earnings (Dynamic)
        StreamBuilder<double>(
          stream: getEarningsStream(currentUserId),
          builder: (context, snapshot) {
            String earningsText = 'RM0.00';
            if (snapshot.hasData) {
              earningsText = 'RM${snapshot.data!.toStringAsFixed(2)}';
            } else if (snapshot.hasError) {
              earningsText = 'Error';
            }
            return _buildClickableStat(
              context,
              value: earningsText,
              label: 'Earnings',
              page: HistoryRenteeScreen(isRenter: true),
              isSmallScreen: isSmallScreen,
              isVerySmallScreen: isVerySmallScreen,
            );
          },
        ),

        // Pending Requests
        StreamBuilder<int>(
          stream: getPendingRequestsCount(currentUserId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return _buildClickableStat(
                context,
                value: '...',
                label: 'Requests',
                page: BookingRequestsScreen(renterId: currentUserId),
                isSmallScreen: isSmallScreen,
                isVerySmallScreen: isVerySmallScreen,
              );
            }

            int pendingCount = snapshot.data!;
            Widget statWidget = _buildClickableStat(
              context,
              value: '$pendingCount',
              label: 'Requests',
              page: BookingRequestsScreen(renterId: currentUserId),
              isSmallScreen: isSmallScreen,
              isVerySmallScreen: isVerySmallScreen,
            );

            if (pendingCount > 0) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  statWidget,
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: EdgeInsets.all(isVerySmallScreen ? 3 : 4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$pendingCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isVerySmallScreen ? 9 : 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return statWidget;
          },
        ),
      ],
    );
  }

  Widget _buildClickableStat(
    BuildContext context, {
    required String value,
    required String label,
    required Widget page,
    required bool isSmallScreen,
    required bool isVerySmallScreen,
  }) {
    final valueFontSize = isVerySmallScreen ? 14.0 : (isSmallScreen ? 16.0 : 18.0);
    final labelFontSize = isVerySmallScreen ? 10.0 : 11.0;
    final verticalPadding = isSmallScreen ? 10.0 : 12.0;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: isVerySmallScreen ? 2 : 4),
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding,
            horizontal: isVerySmallScreen ? 4 : 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.accentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: valueFontSize,
                  color: AppColors.accentColor,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.lightHintColor,
                  fontSize: labelFontSize,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String title,
    IconData icon,
    String currentUserId,
    bool isSmallScreen,
  ) {
    final buttonHeight = isSmallScreen ? 46.0 : 50.0;
    final iconSize = isSmallScreen ? 20.0 : 22.0;
    final textSize = isSmallScreen ? 13.0 : 14.0;

    return Container(
      margin: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 6),
      child: ElevatedButton.icon(
        onPressed: () {
          if (title == 'Add New Item') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddItemPage()),
            );
          } else if (title == 'View Rental Requests') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BookingRequestsScreen(renterId: currentUserId),
              ),
            );
          } else if (title == 'Transaction History') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistoryRenteeScreen(isRenter: true),
              ),
            );
          } else if (title == 'View Item Reviews') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RenterAllReviewsScreen(renterId: currentUserId),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PlaceholderPage(title: title)),
            );
          }
        },
        icon: Icon(icon, color: AppColors.lightTextColor, size: iconSize),
        label: Text(
          title,
          style: TextStyle(
            color: AppColors.lightTextColor,
            fontSize: textSize,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightInputFillColor,
          minimumSize: Size(double.infinity, buttonHeight),
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
        ),
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.lightCardBackground,
        foregroundColor: AppColors.lightTextColor,
        title: Text(
          title,
          style: TextStyle(fontSize: isSmallScreen ? 16 : 18),
        ),
        elevation: isDark ? 0 : 1,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            size: isSmallScreen ? 20 : 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction_rounded,
                size: isSmallScreen ? 56 : 64,
                color: AppColors.accentColor,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.lightTextColor,
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 6 : 8),
              Text(
                'Coming soon...',
                style: TextStyle(
                  color: AppColors.lightHintColor,
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}