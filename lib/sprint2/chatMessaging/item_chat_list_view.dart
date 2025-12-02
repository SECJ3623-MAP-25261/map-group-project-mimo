// lib/sprint2/chatMessaging/item_chat_list_view.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import 'package:profile_managemenr/services/auth_service.dart';
import 'item_chat_screen.dart';

class ItemChatListView extends StatelessWidget {
  const ItemChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final currentUserId = auth.userId;

    if (currentUserId == null) {
      return const Center(
        child: Text('Please log in to see your messages.'),
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('item_chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load conversations.'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No messages yet.\nStart by messaging a renter/rentee.'),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final chatId = doc.id;
            final itemName = data['itemName'] ?? 'Item';
            final lastMessage = data['lastMessage'] ?? '';
            final renterId = data['renterId'] ?? '';
            final renterName = data['renterName'] ?? 'Renter';
            final renteeId = data['renteeId'] ?? '';
            final renteeName = data['renteeName'] ?? 'Rentee';
            final updatedAt = data['updatedAt'];

            final isRenter = renterId == currentUserId;
            final otherName = isRenter ? renteeName : renterName;

<<<<<<< Updated upstream
            String timeText = '';
            if (updatedAt is Timestamp) {
              final dt = updatedAt.toDate();
              final hh = dt.hour.toString().padLeft(2, '0');
              final mm = dt.minute.toString().padLeft(2, '0');
              timeText = '$hh:$mm';
=======
  Widget _buildNoMessages(String message, String userId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home, size: 64, color: AppColors.lightHintColor),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: AppColors.lightHintColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'User: $userId',
              style: const TextStyle(
                fontSize: 12, 
                color: AppColors.lightHintColor
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔥 Chat List for RENTEE (your conversations about items you want to rent)
class _RenteeChatList extends StatelessWidget {
  const _RenteeChatList();

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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final currentUserId = auth.userId;

    if (currentUserId == null) {
      return _buildNotLoggedIn();
    }

    // 🔥 Query: Get chats where current user is the RENTEE
    final stream = FirebaseFirestore.instance
        .collection('item_chats')
        .where('renteeId', isEqualTo: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading your bookings...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          print('❌ Rentee chat list error: ${snapshot.error}');
          return _buildError(snapshot.error.toString(), currentUserId);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildNoMessages(
            'You haven\'t messaged any renters yet.\nStart by browsing items!',
            currentUserId,
          );
        }

        final docs = snapshot.data!.docs;
        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildChatListItem(
              data,
              doc.id,
              currentUserId,
              context,
              isRenterView: false,
            );
          },
        );
      },
    );
  }

  Widget _buildNotLoggedIn() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 64, color: AppColors.lightHintColor),
            SizedBox(height: 16),
            Text(
              'Please log in to see your messages',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.lightHintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error, String userId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.errorColor),
            const SizedBox(height: 16),
            const Text(
              'Failed to load your booking conversations',
              style: TextStyle(
                color: AppColors.errorColor,
                fontSize: 16,
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

  Widget _buildNoMessages(String message, String userId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_bag, size: 64, color: AppColors.lightHintColor),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: AppColors.lightHintColor,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'User: $userId',
              style: const TextStyle(
                fontSize: 12, 
                color: AppColors.lightHintColor
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔥 Shared chat list item builder
Widget _buildChatListItem(
    Map<String, dynamic> data,
    String chatId,
    String currentUserId,
    BuildContext context,
    {required bool isRenterView}) {
  final itemName = data['itemName'] ?? 'Item';
  final lastMessage = data['lastMessage'] ?? '';
  final renterId = data['renterId'] ?? '';
  final renterName = data['renterName'] ?? 'Renter';
  final renteeId = data['renteeId'] ?? '';
  final renteeName = data['renteeName'] ?? 'Rentee';
  final updatedAt = data['updatedAt'] as Timestamp?;

  final lastSenderId = data['lastSender'] ?? '';
  // Determine the other person's name based on view
  final otherName = isRenterView ? renteeName : renterName;
  // Determine if the current user is the last sender
  final isLastSenderMe = lastSenderId == currentUserId;
  // Determine the name of the last sender
  final lastSenderName = isLastSenderMe 
      ? 'You' 
      : lastSenderId == renterId 
          ? renterName
          : renteeName;

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.accentColor.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isRenterView ? Icons.person : Icons.shopping_bag,
          color: AppColors.accentColor,
          size: 24,
        ),
      ),
      title: Text(
        itemName,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: AppColors.lightTextColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lastMessage.isEmpty ? 'No messages yet' : '$lastSenderName: $lastMessage',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.lightHintColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: isRenterView ? 'From: ' : 'To: ',
                  style: const TextStyle(
                    color: AppColors.lightHintColor,
                    fontSize: 11,
                  ),
                ),
                TextSpan(
                  text: otherName,
                  style: const TextStyle(
                    color: AppColors.lightTextColor,
                    fontSize: 11,
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
        style: const TextStyle(
          fontSize: 11,
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
              final itemData = itemDoc.data() as Map<String, dynamic>?;
              itemImages = itemData?['images'] as List<dynamic>? ?? [];
>>>>>>> Stashed changes
            }

            return ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: Text(
                itemName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '$otherName · $lastMessage',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                timeText,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.lightHintColor,
                ),
              ),
              onTap: () {
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
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
