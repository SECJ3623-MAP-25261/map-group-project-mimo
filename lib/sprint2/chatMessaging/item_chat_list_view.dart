// lib/sprint2/chatMessaging/item_chat_list_view.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import 'package:profile_managemenr/services/auth_service.dart';
//import 'package:profile_managemenr/services/message_service.dart';
import 'item_chat_screen.dart';

class ItemChatListView extends StatefulWidget {
  const ItemChatListView({super.key});

  @override
  State<ItemChatListView> createState() => _ItemChatListViewState();
}

class _ItemChatListViewState extends State<ItemChatListView> {
  int _selectedIndex = 0; // 0 = Rentals (as renter), 1 = Bookings (as rentee)

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isVerySmallScreen = screenWidth < 340;

    return Scaffold(
      appBar: _buildAppBar(context, isSmallScreen),
      backgroundColor: AppColors.lightBackground,
      body: Column(
        children: [
          // Toggle Buttons
          _buildToggleButtons(isSmallScreen, isVerySmallScreen),
          SizedBox(height: isSmallScreen ? 8 : 16),
          // Chat list content
          Expanded(
            child: _selectedIndex == 0
                ? _RenterChatList(
                    isSmallScreen: isSmallScreen,
                    isVerySmallScreen: isVerySmallScreen,
                  )
                : _RenteeChatList(
                    isSmallScreen: isSmallScreen,
                    isVerySmallScreen: isVerySmallScreen,
                  ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isSmallScreen) {
    return AppBar(
      title: Text(
        'Messages',
        style: TextStyle(
          fontSize: isSmallScreen ? 18 : 20,
        ),
      ),
      backgroundColor: AppColors.accentColor,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            Icons.person_rounded,
            size: isSmallScreen ? 22 : 24,
          ),
          onPressed: () {
            final auth = Provider.of<AuthService>(context, listen: false);
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Current User'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User ID: ${auth.userId ?? "Not logged in"}'),
                    Text('Email: ${auth.userEmail ?? "No email"}'),
                    if (auth.userId != null) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Logged in and ready to chat!',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildToggleButtons(bool isSmallScreen, bool isVerySmallScreen) {
    final horizontalPadding = isVerySmallScreen ? 12.0 : 16.0;
    final iconSize = isVerySmallScreen ? 16.0 : 18.0;
    final textSize = isVerySmallScreen ? 13.0 : 14.0;
    final buttonPadding = isVerySmallScreen ? 12.0 : 16.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: ToggleButtons(
              isSelected: [_selectedIndex == 0, _selectedIndex == 1],
              onPressed: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              borderRadius: BorderRadius.circular(12),
              selectedColor: Colors.white,
              fillColor: AppColors.accentColor,
              color: AppColors.lightTextColor,
              borderColor: AppColors.lightBorderColor,
              selectedBorderColor: AppColors.accentColor,
              borderWidth: 2,
              constraints: BoxConstraints(
                minHeight: isVerySmallScreen ? 42 : 48,
                minWidth: (MediaQuery.of(context).size.width - horizontalPadding * 2) / 2 - 2,
              ),
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: buttonPadding, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_rounded, size: iconSize),
                      SizedBox(width: isVerySmallScreen ? 4 : 8),
                      Flexible(
                        child: Text(
                          'My Rentals',
                          style: TextStyle(fontSize: textSize),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: buttonPadding, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_rounded, size: iconSize),
                      SizedBox(width: isVerySmallScreen ? 4 : 8),
                      Flexible(
                        child: Text(
                          'My Bookings',
                          style: TextStyle(fontSize: textSize),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Chat List for RENTER (people messaging you about your items)
class _RenterChatList extends StatelessWidget {
  final bool isSmallScreen;
  final bool isVerySmallScreen;

  const _RenterChatList({
    required this.isSmallScreen,
    required this.isVerySmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final currentUserId = auth.userId;

    if (currentUserId == null) {
      return _buildNotLoggedIn(isSmallScreen);
    }

    final stream = FirebaseFirestore.instance
        .collection('item_chats')
        .where('renterId', isEqualTo: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading('Loading your rentals...', isSmallScreen);
        }

        if (snapshot.hasError) {
          print('❌ Renter chat list error: ${snapshot.error}');
          return _buildError(
            snapshot.error.toString(),
            currentUserId,
            'Failed to load your rental conversations',
            isSmallScreen,
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildNoMessages(
            'No one has messaged you about your items yet.',
            currentUserId,
            Icons.home_rounded,
            isSmallScreen,
          );
        }

        final docs = snapshot.data!.docs;
        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 8 : 12,
          ),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 0),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildChatListItem(
              data,
              doc.id,
              currentUserId,
              context,
              isRenterView: true,
              isSmallScreen: isSmallScreen,
              isVerySmallScreen: isVerySmallScreen,
            );
          },
        );
      },
    );
  }

  Widget _buildLoading(String message, bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.accentColor),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            message,
            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedIn(bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.login_rounded,
              size: isSmallScreen ? 56 : 64,
              color: AppColors.lightHintColor,
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'Please log in to see your messages',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: AppColors.lightHintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error, String userId, String title, bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: isSmallScreen ? 56 : 64,
              color: AppColors.errorColor,
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              title,
              style: TextStyle(
                color: AppColors.errorColor,
                fontSize: isSmallScreen ? 14 : 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'User: $userId',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'Error: ${error.length > 100 ? error.substring(0, 100) + '...' : error}',
              style: const TextStyle(
                color: AppColors.errorColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMessages(String message, String userId, IconData icon, bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isSmallScreen ? 56 : 64,
              color: AppColors.lightHintColor,
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              message,
              style: TextStyle(
                color: AppColors.lightHintColor,
                fontSize: isSmallScreen ? 14 : 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'User: $userId',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.lightHintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Chat List for RENTEE (your conversations about items you want to rent)
class _RenteeChatList extends StatelessWidget {
  final bool isSmallScreen;
  final bool isVerySmallScreen;

  const _RenteeChatList({
    required this.isSmallScreen,
    required this.isVerySmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final currentUserId = auth.userId;

    if (currentUserId == null) {
      return _buildNotLoggedIn(isSmallScreen);
    }

    final stream = FirebaseFirestore.instance
        .collection('item_chats')
        .where('renteeId', isEqualTo: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading('Loading your bookings...', isSmallScreen);
        }

        if (snapshot.hasError) {
          print('❌ Rentee chat list error: ${snapshot.error}');
          return _buildError(
            snapshot.error.toString(),
            currentUserId,
            'Failed to load your booking conversations',
            isSmallScreen,
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildNoMessages(
            'You haven\'t messaged any renters yet.\nStart by browsing items!',
            currentUserId,
            Icons.shopping_bag_rounded,
            isSmallScreen,
          );
        }

        final docs = snapshot.data!.docs;
        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 8 : 12,
          ),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 0),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildChatListItem(
              data,
              doc.id,
              currentUserId,
              context,
              isRenterView: false,
              isSmallScreen: isSmallScreen,
              isVerySmallScreen: isVerySmallScreen,
            );
          },
        );
      },
    );
  }

  Widget _buildLoading(String message, bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.accentColor),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            message,
            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedIn(bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.login_rounded,
              size: isSmallScreen ? 56 : 64,
              color: AppColors.lightHintColor,
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'Please log in to see your messages',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: AppColors.lightHintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error, String userId, String title, bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: isSmallScreen ? 56 : 64,
              color: AppColors.errorColor,
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              title,
              style: TextStyle(
                color: AppColors.errorColor,
                fontSize: isSmallScreen ? 14 : 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'User: $userId',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'Error: ${error.length > 100 ? error.substring(0, 100) + '...' : error}',
              style: const TextStyle(
                color: AppColors.errorColor,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMessages(String message, String userId, IconData icon, bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isSmallScreen ? 56 : 64,
              color: AppColors.lightHintColor,
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              message,
              style: TextStyle(
                color: AppColors.lightHintColor,
                fontSize: isSmallScreen ? 14 : 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'User: $userId',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.lightHintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Shared chat list item builder
Widget _buildChatListItem(
  Map<String, dynamic> data,
  String chatId,
  String currentUserId,
  BuildContext context, {
  required bool isRenterView,
  required bool isSmallScreen,
  required bool isVerySmallScreen,
}) {
  final itemName = data['itemName'] ?? 'Item';
  final lastMessage = data['lastMessage'] ?? '';
  final renterId = data['renterId'] ?? '';
  final renterName = data['renterName'] ?? 'Renter';
  final renteeId = data['renteeId'] ?? '';
  final renteeName = data['renteeName'] ?? 'Rentee';
  final updatedAt = data['updatedAt'] as Timestamp?;
  final lastSenderId = data['lastSender'] ?? '';

  final otherName = isRenterView ? renteeName : renterName;
  final isLastSenderMe = lastSenderId == currentUserId;
  final lastSenderName = isLastSenderMe
      ? 'You'
      : lastSenderId == renterId
          ? renterName
          : renteeName;

  final horizontalMargin = isVerySmallScreen ? 8.0 : (isSmallScreen ? 12.0 : 16.0);
  final verticalMargin = isSmallScreen ? 6.0 : 8.0;
  final avatarSize = isVerySmallScreen ? 44.0 : (isSmallScreen ? 48.0 : 50.0);
  final iconSize = isVerySmallScreen ? 22.0 : 24.0;
  final titleSize = isVerySmallScreen ? 15.0 : 16.0;
  final subtitleSize = isVerySmallScreen ? 12.0 : 13.0;
  final metaSize = isVerySmallScreen ? 10.0 : 11.0;

  return Card(
    margin: EdgeInsets.symmetric(
      horizontal: horizontalMargin,
      vertical: verticalMargin,
    ),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: isVerySmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 8 : 12,
      ),
      leading: Container(
        width: avatarSize,
        height: avatarSize,
        decoration: BoxDecoration(
          color: AppColors.accentColor.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isRenterView ? Icons.person_rounded : Icons.shopping_bag_rounded,
          color: AppColors.accentColor,
          size: iconSize,
        ),
      ),
      title: Text(
        itemName,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: titleSize,
          color: AppColors.lightTextColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: isSmallScreen ? 4 : 6),
          Text(
            lastMessage.isEmpty ? 'No messages yet' : '$lastSenderName: $lastMessage',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.lightHintColor,
              height: 1.3,
              fontSize: subtitleSize,
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: isRenterView ? 'From: ' : 'To: ',
                  style: TextStyle(
                    color: AppColors.lightHintColor,
                    fontSize: metaSize,
                  ),
                ),
                TextSpan(
                  text: otherName,
                  style: TextStyle(
                    color: AppColors.lightTextColor,
                    fontSize: metaSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      trailing: Text(
        _formatTime(updatedAt),
        style: TextStyle(
          fontSize: metaSize,
          color: AppColors.lightHintColor,
        ),
      ),
      onTap: () async {
        print('💬 Opening chat: $chatId for user: $currentUserId');

        List<dynamic> itemImages = [];
        try {
          final itemId = data['itemId'] ?? '';
          if (itemId.isNotEmpty) {
            final itemDoc = await FirebaseFirestore.instance
                .collection('items')
                .doc(itemId)
                .get();

            if (itemDoc.exists) {
              final itemData = itemDoc.data();
              itemImages = itemData?['images'] as List<dynamic>? ?? [];
            }
          }
        } catch (e) {
          print('Error fetching item images: $e');
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItemChatScreen(
              chatId: chatId,
              itemId: data['itemId'] ?? '',
              itemName: itemName,
              renterId: renterId,
              renterName: renterName,
              renteeId: renteeId,
              renteeName: renteeName,
              itemImages: itemImages,
            ),
          ),
        );
      },
    ),
  );
}

// Helper method
String _formatTime(Timestamp? timestamp) {
  if (timestamp == null) return '';
  final dt = timestamp.toDate();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDate = DateTime(dt.year, dt.month, dt.day);
  if (messageDate == today) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } else {
    return '${dt.day}/${dt.month}';
  }
}