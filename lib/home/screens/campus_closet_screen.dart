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
import 'package:profile_managemenr/sprint2/searchRentee/search.dart';

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
        const SnackBar(content: Text('Item missing renter info.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(item: item.toMap()),
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.message, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/messages'),
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
          FilterChipList(
            filters: AppConstants.categories,
            activeFilter: _activeFilter,
            onFilterChanged: (filter) => setState(() => _activeFilter = filter),
          ),
          const Divider(thickness: 2, color: AppColors.lightCardBackground),
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

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: AppConstants.gridCrossAxisCount,
                    childAspectRatio: AppConstants.gridChildAspectRatio,
                    crossAxisSpacing: AppConstants.gridCrossAxisSpacing,
                    mainAxisSpacing: AppConstants.gridMainAxisSpacing,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return ItemGridCard(
                      item: items[index],
                      onTap: () => _onItemTap(items[index]),
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