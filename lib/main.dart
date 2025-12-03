import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart'; // Added Provider

import 'package:profile_managemenr/accounts/authentication/login.dart';
import 'package:profile_managemenr/accounts/registration/registration_app.dart';
import 'package:profile_managemenr/accounts/profile/screen/profile/profile.dart';
import 'package:profile_managemenr/sprint2/Booking%20Rentee/booking.dart';
import 'package:profile_managemenr/sprint2/ReportCenter/report_center.dart';
import 'package:profile_managemenr/sprint2/chatMessaging/item_chat_list_view.dart';
import 'package:profile_managemenr/sprint2/chatMessaging/item_chat_screen.dart';
import 'package:profile_managemenr/services/auth_service.dart'; // Added AuthService import
import 'package:profile_managemenr/services/user_service.dart';

import 'firebase_options.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import 'package:profile_managemenr/welcome_page.dart';
import 'dart:convert';
import 'package:profile_managemenr/sprint2/renter_dashboard/review_view_renter.dart';
import 'package:profile_managemenr/sprint2/searchRentee/search.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Wrap with MultiProvider
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
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
          '/profile': (context) => const ProfileScreen(),
          '/booking': (context) => const BookingScreen(),
          '/report': (context) => const ReportCenterScreen(),
          '/messages': (context) => const ItemChatListView(),
          '/search' : (context) => const SearchPage(),
        },
      ),
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


class ItemDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<dynamic> get _images {
    final images = widget.item['images'] as List<dynamic>?;
    return images ?? [];
  }

  Widget _buildImageItem(dynamic imageData) {
    if (imageData == null) {
      return Container(
        color: Colors.grey[200],
        child: const Icon(Icons.image, size: 60, color: Colors.grey),
      );
    }

    if (imageData is String) {
      if (imageData.startsWith('http')) {
        return Image.network(
          imageData,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Icon(Icons.image_not_supported, size: 60),
            );
          },
        );
      } else {
        // Base64
        try {
          return Image.memory(
            base64Decode(imageData),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                child: const Icon(Icons.image_not_supported, size: 60),
              );
            },
          );
        } catch (e) {
          return Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 60),
          );
        }
      }
    }

    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.image, size: 60, color: Colors.grey),
    );
  }

  Future<Map<String, dynamic>> _getReviewStats() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('itemId', isEqualTo: widget.item['id'])
          .get();

      if (snapshot.docs.isEmpty) {
        return {'count': 0, 'average': 0.0};
      }

      int total = snapshot.docs.length;
      double sum = 0;

      for (var doc in snapshot.docs) {
        sum += (doc['rating'] as int);
      }

      return {
        'count': total,
        'average': sum / total,
      };
    } catch (e) {
      return {'count': 0, 'average': 0.0};
    }
  }

  Widget _buildReviewsSummary() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getReviewStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;
        final count = stats['count'] as int;
        final average = stats['average'] as double;

        if (count == 0) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightCardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightBorderColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.rate_review_outlined,
                    color: AppColors.lightHintColor),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'No reviews yet',
                    style: TextStyle(
                      color: AppColors.lightHintColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewViewRenterScreen(
                          itemId: widget.item['id'],
                          itemName: widget.item['name'] ?? 'Item',
                        ),
                      ),
                    );
                  },
                  child: const Text('View'),
                ),
              ],
            ),
          );
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReviewViewRenterScreen(
                  itemId: widget.item['id'],
                  itemName: widget.item['name'] ?? 'Item',
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lightCardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightBorderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 24),
                      const SizedBox(width: 4),
                      Text(
                        average.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$count review${count != 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightTextColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tap to see all reviews',
                        style: TextStyle(
                          color: AppColors.lightHintColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.lightHintColor),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final renterId = widget.item['renterId'] as String?;
    final renterName = widget.item['renterName'] as String? ?? 'Renter';
    final images = _images;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.accentColor,
        title: Text(widget.item['name'] ?? 'Item'),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // IMAGE CAROUSEL
              if (images.isNotEmpty) ...[
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification notification) {
                      return notification is UserScrollNotification;
                    },
                    child: GestureDetector(
                      onHorizontalDragStart: (_) {},
                      onHorizontalDragUpdate: (_) {},
                      onHorizontalDragEnd: (_) {},
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: images.length,
                              onPageChanged: (index) {
                                setState(() => _currentPage = index);
                              },
                              itemBuilder: (context, index) {
                                return _buildImageItem(images[index]);
                              },
                            ),
                          ),
                          // Indicator dots
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(images.length, (index) {
                                  return Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _currentPage == index
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.5),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Name & Price
              Text(
                widget.item['name'] ?? 'Unnamed Item',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.lightTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "RM${(widget.item['pricePerDay'] ?? 0).toStringAsFixed(2)}/day",
                style: const TextStyle(
                  color: AppColors.accentColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Reviews Summary
              _buildReviewsSummary(),
              const SizedBox(height: 16),

              // Details
              if (widget.item['category'] != null || widget.item['size'] != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightCardBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (widget.item['category'] != null) ...[
                        const Icon(Icons.category, size: 16, color: AppColors.lightHintColor),
                        const SizedBox(width: 4),
                        Text(
                          widget.item['category'],
                          style: const TextStyle(color: AppColors.lightTextColor),
                        ),
                      ],
                      if (widget.item['category'] != null && widget.item['size'] != null)
                        const SizedBox(width: 16),
                      if (widget.item['size'] != null) ...[
                        const Icon(Icons.straighten, size: 16, color: AppColors.lightHintColor),
                        const SizedBox(width: 4),
                        Text(
                          widget.item['size'],
                          style: const TextStyle(color: AppColors.lightTextColor),
                        ),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // Description
              if (widget.item['description'] != null &&
                  widget.item['description'].toString().isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.item['description'],
                      style: const TextStyle(
                        color: AppColors.lightTextColor,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // Action Buttons
              if (user != null && renterId != null && renterId != user.uid) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingScreen(itemData: widget.item),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Book Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final sorted = [user.uid, renterId]..sort();
                      final chatId = '${widget.item['id']}|${sorted[0]}|${sorted[1]}';
                      final renteeName = await getCurrentUserFullName();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ItemChatScreen(
                            chatId: chatId,
                            itemId: widget.item['id'],
                            itemName: widget.item['name'] ?? 'Item',
                            renterId: renterId,
                            renterName: renterName,
                            renteeId: user.uid,
                            renteeName: renteeName,
                            itemImages: widget.item['images'],
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Message Renter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentColor,
                      side: const BorderSide(color: AppColors.accentColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ] else if (renterId == user?.uid)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.accentColor),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This is your item',
                          style: TextStyle(color: AppColors.accentColor),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.login, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Please log in to book or message',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
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

  Stream<QuerySnapshot> _getItemsStream() {
    if (_activeFilter == 'all') {
      return FirebaseFirestore.instance.collection('items').snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('items')
          .where('category', isEqualTo: _activeFilter)
          .snapshots();
    }
  }

  void _onItemTap(Map<String, dynamic> item) {
    if (item['renterId'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item missing renter info.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(item: item),
      ),
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
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: (){
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context)=> const SearchPage()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.message, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/messages');
            },
            tooltip: 'Messages',
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            tooltip: 'Profile',
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

          // Items Grid
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

                    final images = data['images'] as List<dynamic>?;
                    final imageData = images != null && images.isNotEmpty
                        ? images[0]
                        : null;

                    // Build full item data including renter info
                    final itemData = {
                      'id': doc.id,
                      'name': data['name'] ?? 'Unnamed Item',
                      'pricePerDay': data['pricePerDay'] ?? 0.0,
                      'price': data['pricePerDay'] ?? 0.0,
                      'category': data['category'] ?? 'Other',
                      'image': imageData,
                      'images': images ?? [],
                      'description': data['description'] ?? '',
                      'size': data['size'] ?? '',
                      'renterId': data['renterId'],
                      'renterName': data['renterName'],
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
                                            errorBuilder: (context, error, stackTrace) =>
                                                Container(
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.image_not_supported, size: 40),
                                            ),
                                          )
                                        : Image.memory(
                                            base64Decode(imageData),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                Container(
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.image_not_supported, size: 40),
                                            ),
                                          ))
                                    : Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                      ),
                              ),
                            ),
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
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
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