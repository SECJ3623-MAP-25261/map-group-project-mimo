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

  // ✅ NEW: Stream for dynamic earnings
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

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: AppColors.lightCardBackground,
              borderRadius: BorderRadius.circular(20),
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
                Text(
                  'Welcome, $name 👕',
                  style: TextStyle(
                    color: AppColors.accentColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your items, requests, and earnings.',
                  style: TextStyle(color: AppColors.lightHintColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Stats Row
                Row(
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
                          return buildClickableStat(
                            context,
                            value: '...',
                            label: 'Items Listed',
                            page: YourItemsPage(renterId: currentUserId),
                          );
                        }
                        int itemCount = snapshot.data!.docs.length;
                        return buildClickableStat(
                          context,
                          value: '$itemCount',
                          label: 'Items Listed',
                          page: YourItemsPage(renterId: currentUserId),
                        );
                      },
                    ),

                    // ✅ Earnings (Dynamic)
                    StreamBuilder<double>(
                      stream: getEarningsStream(currentUserId),
                      builder: (context, snapshot) {
                        String earningsText = 'RM0.00';
                        if (snapshot.hasData) {
                          earningsText = 'RM${snapshot.data!.toStringAsFixed(2)}';
                        } else if (snapshot.hasError) {
                          earningsText = 'Error';
                        }
                        return buildClickableStat(
                          context,
                          value: earningsText,
                          label: 'Earnings',
                          page: HistoryRenteeScreen(isRenter: true),
                        );
                      },
                    ),

                    // Pending Requests
                    StreamBuilder<int>(
                      stream: getPendingRequestsCount(currentUserId),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return buildClickableStat(
                            context,
                            value: '...',
                            label: 'Requests',
                            page: BookingRequestsScreen(renterId: currentUserId),
                          );
                        }

                        int pendingCount = snapshot.data!;
                        Widget statWidget = buildClickableStat(
                          context,
                          value: '$pendingCount',
                          label: 'Requests',
                          page: BookingRequestsScreen(renterId: currentUserId),
                        );

                        if (pendingCount > 0) {
                          return Stack(
                            children: [
                              statWidget,
                              Positioned(
                                top: -5,
                                right: -5,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$pendingCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
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
                ),
                const SizedBox(height: 30),

                // Action buttons
                menuButton(context, 'Add New Item', Icons.add, currentUserId),
                menuButton(context, 'View Rental Requests', Icons.inventory, currentUserId),
                menuButton(context, 'Transaction History', Icons.receipt_long, currentUserId),
                menuButton(context, 'Help & Support', Icons.help_outline, currentUserId),
                menuButton(context, 'View Item Reviews', Icons.star_rate, currentUserId),

                const SizedBox(height: 20),

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Back to Profile 👤',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Campus Closet © 2025',
                  style: TextStyle(
                    color: AppColors.lightHintColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ Updated menuButton to accept currentUserId
Widget menuButton(BuildContext context, String title, IconData icon, String currentUserId) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
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
          // ✅ Navigate to real history (renter mode)
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
      icon: Icon(icon, color: AppColors.lightTextColor),
      label: Text(title, style: TextStyle(color: AppColors.lightTextColor)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lightInputFillColor,
        minimumSize: const Size(double.infinity, 50),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

Widget buildClickableStat(
  BuildContext context, {
  required String value,
  required String label,
  required Widget page,
}) {
  return Expanded(
    child: GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.accentColor,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: AppColors.lightHintColor, fontSize: 11),
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

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.lightCardBackground,
        foregroundColor: AppColors.lightTextColor,
        title: Text(title),
        elevation: isDark ? 0 : 1,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64, color: AppColors.accentColor),
            const SizedBox(height: 16),
            Text(
              '$title',
              style: TextStyle(
                color: AppColors.lightTextColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon...',
              style: TextStyle(color: AppColors.lightHintColor, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}