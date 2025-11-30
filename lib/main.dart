import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:profile_managemenr/accounts/authentication/login.dart';
import 'package:profile_managemenr/accounts/registration/registration_app.dart';
import 'package:profile_managemenr/accounts/profile/screen/profile/profile.dart';
import 'package:profile_managemenr/sprint2/Booking%20Rentee/booking.dart';
import 'package:profile_managemenr/sprint2/ReportCenter/report_center.dart';

import 'firebase_options.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import 'package:profile_managemenr/welcome_page.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Closet',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const CampusClosetScreen(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegistrationApp(),
        '/profile': (context) => ProfileScreen(),
        '/booking': (context) => const BookingScreen(),
        '/report': (context) => const ReportCenterScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const CampusClosetScreen();
        }

        return const WelcomeScreen();
      },
    );
  }
}

// ------------------------------
// HOME PAGE
// ------------------------------

class CampusClosetScreen extends StatefulWidget {
  const CampusClosetScreen({super.key});

  @override
  State<CampusClosetScreen> createState() => _CampusClosetScreenState();
}

class _CampusClosetScreenState extends State<CampusClosetScreen> {
  String _activeFilter = 'all';

  final List<String> _filters = [
    'all',
    'Shirt',
    'Pants',
    'Dress',
    'Jacket',
    'Traditional Wear',
    'Sportswear',
    'Formal',
    'Accessories',
    'Other',
  ];

  // Stream to fetch items from Firestore
  Stream<QuerySnapshot> _getItemsStream() {
    if (_activeFilter == 'all') {
      return FirebaseFirestore.instance
          .collection('items')
          .snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('items')
          .where('category', isEqualTo: _activeFilter)
          .snapshots();
    }
  }

  void _onItemTap(Map<String, dynamic> item) {
    Navigator.pushNamed(
      context,
      '/booking',
      arguments: item,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.accentColor,
        elevation: 0,
        title: const Text(
          'Campus Closet',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Buttons
          SizedBox(
            height: 55,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final f = _filters[index];
                final label = f == 'all' ? 'All' : f;
                final isActive = _activeFilter == f;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive
                          ? AppColors.accentColor
                          : AppColors.lightCardBackground,
                      foregroundColor: isActive
                          ? Colors.white
                          : AppColors.lightTextColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () => setState(() => _activeFilter = f),
                    child: Text(label),
                  ),
                );
              },
            ),
          ),
          const Divider(thickness: 2, color: AppColors.lightCardBackground),

          // Items Grid from Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getItemsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No items found.",
                      style: TextStyle(
                        color: AppColors.lightHintColor,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                final items = snapshot.data!.docs;

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final doc = items[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    // Get first image (base64 or URL)
                    final images = data['images'] as List<dynamic>?;
                    final imageData = images != null && images.isNotEmpty
                        ? images[0]
                        : null;

                    // Prepare item data for booking
                    final itemData = {
                      'id': doc.id,
                      'name': data['name'] ?? 'Unnamed Item',
                      'price': data['pricePerDay']?.toDouble() ?? 0.0,
                      'category': data['category'] ?? 'Other',
                      'image': imageData,
                      'description': data['description'] ?? '',
                      'size': data['size'] ?? '',
                    };

                    return GestureDetector(
                      onTap: () => _onItemTap(itemData),
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
                            // Image
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: imageData != null
                                    ? (imageData is String && imageData.startsWith('http')
                                        ? Image.network(
                                            imageData,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.image_not_supported,
                                                  size: 40,
                                                ),
                                              );
                                            },
                                          )
                                        : Image.memory(
                                            base64Decode(imageData),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.image_not_supported,
                                                  size: 40,
                                                ),
                                              );
                                            },
                                          ))
                                    : Container(
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.image,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      ),
                              ),
                            ),

                            // Name
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                data['name'] ?? 'Unnamed Item',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.lightTextColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Price
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: Text(
                                "RM${(data['pricePerDay'] ?? 0).toStringAsFixed(2)}/day",
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
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}