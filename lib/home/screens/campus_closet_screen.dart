import 'package:flutter/material.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../core/widgets/empty_state_widget.dart';
import '../core/widgets/loading_widget.dart';
import '../core/widgets/error_widget.dart';
import '../widgets/filter_chip_list.dart';
import '../widgets/item_grid_card.dart';
import '../models/item_model.dart';
import '../screens/item_detail_screen.dart';
import 'package:profile_managemenr/services/item_service.dart';
import 'package:profile_managemenr/sprint2/Rentee/searchRentee/search.dart';
import 'package:profile_managemenr/sprint2/AIChatbot/aichatbotscreen.dart';

class CampusClosetScreen extends StatefulWidget {
  const CampusClosetScreen({super.key});

  @override
  State<CampusClosetScreen> createState() => _CampusClosetScreenState();
}

class _CampusClosetScreenState extends State<CampusClosetScreen> {
  String _activeFilter = 'all';
  final ItemService _itemService = ItemService();

  void _onItemTap(ItemModel item) {
    if (item.renterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Item missing renter info.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(item: item.toDetailMap()),
      ),
    );
  }

  // Calculate responsive grid columns based on screen width
  int _getGridCrossAxisCount(double screenWidth) {
    if (screenWidth < 340) return 1; // Very small phones - single column
    if (screenWidth < 400) return 2; // Small phones - 2 columns
    if (screenWidth < 600) return 2; // Regular phones - 2 columns
    return 3; // Tablets - 3 columns
  }

  // Calculate responsive aspect ratio
  double _getGridAspectRatio(double screenWidth) {
    if (screenWidth < 340) return 0.85; // Taller cards for single column
    if (screenWidth < 360) return 0.72; // Compact aspect for small screens
    return 0.75; // Standard aspect ratio
  }

  // Calculate responsive spacing
  double _getGridSpacing(double screenWidth) {
    if (screenWidth < 340) return 8.0;
    if (screenWidth < 360) return 10.0;
    return 12.0;
  }

  // Calculate responsive padding
  double _getGridPadding(double screenWidth) {
    if (screenWidth < 340) return 8.0;
    if (screenWidth < 360) return 12.0;
    return 16.0;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: _buildAppBar(context, isSmallScreen),
      body: Column(
        children: [
          FilterChipList(
            filters: AppConstants.categories,
            activeFilter: _activeFilter,
            onFilterChanged: (filter) => setState(() => _activeFilter = filter),
          ),
          Divider(
            thickness: 2,
            height: 2,
            color: AppColors.lightCardBackground,
          ),
          Expanded(
            child: StreamBuilder<List<ItemModel>>(
              stream: _itemService.getItemsStream(
                category: _activeFilter == 'all' ? null : _activeFilter,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget(message: 'Loading items...');
                }

                if (snapshot.hasError) {
                  return ErrorDisplayWidget(
                    error: snapshot.error.toString(),
                    onRetry: () => setState(() {}),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.shopping_bag_outlined,
                    message: 'No items found in this category',
                    actionLabel: 'View All Items',
                    onActionPressed: () {
                      setState(() => _activeFilter = 'all');
                    },
                  );
                }

                final items = snapshot.data!;

                return _buildResponsiveGrid(items, screenWidth);
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isSmallScreen) {
    return AppBar(
      backgroundColor: AppColors.accentColor,
      elevation: 0,
      title: Text(
        'Campus Closet',
        style: TextStyle(
          color: Colors.white,
          fontSize: isSmallScreen ? 18 : 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.search_rounded,
            color: Colors.white,
            size: isSmallScreen ? 22 : 24,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchPage()),
            );
          },
          tooltip: 'Search',
        ),
        IconButton(
          icon: Icon(
            Icons.message_rounded,
            color: Colors.white,
            size: isSmallScreen ? 22 : 24,
          ),
          onPressed: () => Navigator.pushNamed(context, '/messages'),
          tooltip: 'Messages',
        ),
        IconButton(
          icon: Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: isSmallScreen ? 22 : 24,
          ),
          onPressed: () => Navigator.pushNamed(context, '/profile'),
          tooltip: 'Profile',
        ),
        // Example: Add to your AppBar actions or as FAB
        IconButton(
           icon: const Icon(Icons.smart_toy_rounded, color: Colors.white),
            onPressed: () {
              Navigator.push(
               context,
              MaterialPageRoute(
              builder: (context) => const AIChatbotScreen(),
          ),
    );
  },
  tooltip: 'AI Assistant',
)
      ],
    );
  }

  Widget _buildResponsiveGrid(List<ItemModel> items, double screenWidth) {
    final crossAxisCount = _getGridCrossAxisCount(screenWidth);
    final aspectRatio = _getGridAspectRatio(screenWidth);
    final spacing = _getGridSpacing(screenWidth);
    final padding = _getGridPadding(screenWidth);

    // For single column layout on very small screens
    if (crossAxisCount == 1) {
      return ListView.builder(
        padding: EdgeInsets.all(padding),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: spacing),
            child: ItemGridCard(
              item: items[index],
              onTap: () => _onItemTap(items[index]),
            ),
          );
        },
      );
    }

    // Grid layout for 2+ columns
    return GridView.builder(
      padding: EdgeInsets.all(padding),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ItemGridCard(
          item: items[index],
          onTap: () => _onItemTap(items[index]),
        );
      },
    );
  }
}