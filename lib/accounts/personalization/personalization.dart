import 'package:flutter/material.dart';
import 'package:profile_managemenr/accounts/profile/screen/profile/profile.dart';
import '../../../../dbase/data.dart';
import '../../../../models/user.dart';
import 'package:profile_managemenr/accounts/profile/screen/profile/edit_profile.dart';

void main() {
  runApp(CampusClosetApp(renter: renter1, user: user1));
import 'package:campus_closet/accounts/profile/screen/profile/edit_profile.dart';

void main() {
  runApp(CampusClosetApp(renter: renter1, user: dummyUsers[0]));
}

class CampusClosetApp extends StatelessWidget {
  final Renter renter;
  final User user;

  const CampusClosetApp({super.key, required this.renter, required this.user});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Closet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
      ),
      home: RenterDashboard(renter: renter, user: user),
    );
  }
}

class RenterDashboard extends StatelessWidget {
  final Renter renter;
  final User user;

  const RenterDashboard({super.key, required this.renter, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(16),
          width: 350,
          decoration: BoxDecoration(
            color: const Color(0xFF1B263B),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome, ${user.name} 👕',
                style: const TextStyle(
                  color: Color(0xFF00FFC6),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage your items, requests, and earnings.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),

              // Clickable info stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildClickableStat(
                    context,
                    value: '${renter.itemListed}',
                    label: 'Items Listed',
                    page: const PlaceholderPage(title: 'Your Items'),
                  ),
                  _buildClickableStat(
                    context,
                    value: 'RM${renter.earnings.toStringAsFixed(2)}',
                    label: 'Earnings',
                    page: const PlaceholderPage(title: 'Earnings Details'),
                  ),
                  _buildClickableStat(
                    context,
                    value: '${renter.pendingRequests}',
                    label: 'Requests',
                    page: const PlaceholderPage(title: 'Pending Requests'),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Action Buttons
              _menuButton(context, 'Add New Item', Icons.add),
              _menuButton(context, 'View Rental Requests', Icons.inventory),
              _menuButton(context, 'Transaction History', Icons.receipt_long),
              _menuButton(context, 'Help & Support', Icons.help_outline),

              const SizedBox(height: 20),

              // Back to Profile button
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => ProfileScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B4D8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Back to Profile 👤',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Campus Closet © 2025',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Normal menu button
  static Widget _menuButton(BuildContext context, String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PlaceholderPage(title: title)),
          );
        },
        icon: Icon(icon, color: Colors.white),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E4057),
          minimumSize: const Size(double.infinity, 50),
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Clickable stats box
  static Widget _buildClickableStat(
    BuildContext context, {
    required String value,
    required String label,
    required Widget page,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2E4057),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder page for navigation
class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B263B),
        title: Text(title),
      ),
      body: Center(
        child: Text(
          '$title Page',
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}
