import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:profile_managemenr/accounts/authentication/login.dart';
import 'package:profile_managemenr/accounts/registration/registration_app.dart';
import 'package:profile_managemenr/accounts/profile/screen/profile/profile.dart';
import 'package:profile_managemenr/sprint2/Booking%20Rentee/booking.dart';

import 'firebase_options.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import 'package:profile_managemenr/welcome_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
    'all', 'tops', 'bottoms', 'dresses', 'outerwear', 'shoes'
  ];

  // -------------------------------
  // 🔹 HARDCODED ITEMS
  // -------------------------------
  final List<Map<String, dynamic>> items = [
    {
      'name': 'Casual T-Shirt',
      'price': 15.00,
      'category': 'tops',
      'image': 'https.com/ODL8Zfw.png'
    },
    {
      'name': 'Blue Jeans',
      'price': 30.00,
      'category': 'bottoms',
      'image': 'https://i.imgur.com/JqKDZGb.png'
    },
    {
      'name': 'Floral Dress',
      'price': 45.00,
      'category': 'dresses',
      'image': 'https://i.imgur.com/eCzq41n.png'
    },
    {
      'name': 'Black Hoodie',
      'price': 28.00,
      'category': 'outerwear',
      'image': 'https://i.imgur.com/1J4fO8b.png'
    },
    {
      'name': 'White Sneakers',
      'price': 50.00,
      'category': 'shoes',
      'image': 'https://i.imgur.com/xZJrXTS.png'
    },
  ];

  // Filtered list
  List<Map<String, dynamic>> get filteredItems {
    if (_activeFilter == 'all') return items;
    return items.where((item) => item['category'] == _activeFilter).toList();
  }

  // Function to handle item tap
  void _onItemTap(Map<String, dynamic> item) {
    Navigator.pushNamed(
      context,
      '/booking',
      arguments: item, // Pass the item data to BookingScreen
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
          // -------------------------------
          // 🔹 FILTER BUTTONS
          // -------------------------------
          SizedBox(
            height: 55,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final f = _filters[index];
                final label = f[0].toUpperCase() + f.substring(1);
                final isActive = _activeFilter == f;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive
                          ? AppColors.accentColor
                          : AppColors.lightCardBackground,
                      foregroundColor:
                          isActive ? Colors.white : AppColors.lightTextColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onPressed: () => setState(() => _activeFilter = f),
                    child: Text(label),
                  ),
                );
              },
            ),
          ),

          const Divider(thickness: 2, color: AppColors.lightCardBackground),

          // -------------------------------
          // 🔹 ITEMS LIST
          // -------------------------------
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(
                    child: Text(
                      "No items found.",
                      style: TextStyle(
                        color: AppColors.lightHintColor,
                        fontSize: 16,
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];

                      return GestureDetector(
                        onTap: () => _onItemTap(item),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.lightCardBackground,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Image
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16)),
                                  child: Image.network(
                                    item['image'],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                              // Name
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  item['name'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.lightTextColor,
                                  ),
                                ),
                              ),

                              // Price
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  "RM${item['price'].toStringAsFixed(2)}",
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
                  ),
          ),
        ],
      ),
    );
  }
}