// lib/sprint2/chatMessaging/item_chat_list_view.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import 'package:profile_managemenr/services/auth_service.dart';
import 'package:profile_managemenr/services/message_service.dart';
import 'item_chat_screen.dart';

class ItemChatListView extends StatelessWidget {
  const ItemChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppColors.accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
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
      ),
      backgroundColor: AppColors.lightBackground,
      body: const _ChatListContent(),
    );
  }
}

class _ChatListContent extends StatelessWidget {
  const _ChatListContent();

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

    print('📱 Building chat list for user: $currentUserId');

    if (currentUserId == null) {
      return _buildNotLoggedIn();
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
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading messages...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          print('❌ Chat list error: ${snapshot.error}');
          return _buildError(snapshot.error.toString(), currentUserId);
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildNoMessages(currentUserId);
        }

        final docs = snapshot.data!.docs;
        print('✅ Loaded ${docs.length} chats for user: $currentUserId');

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return _buildChatListItem(data, doc.id, currentUserId, context);
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
              'Failed to load conversations',
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

  Widget _buildNoMessages(String userId) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.lightHintColor),
            const SizedBox(height: 16),
            const Text(
              'No messages yet.\nStart by messaging a renter/rentee.',
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

  Widget _buildChatListItem(
      Map<String, dynamic> data, String chatId, String currentUserId, BuildContext context) {
    final itemName = data['itemName'] ?? 'Item';
    final lastMessage = data['lastMessage'] ?? '';
    final renterId = data['renterId'] ?? '';
    final renterName = data['renterName'] ?? 'Renter';
    final renteeId = data['renteeId'] ?? '';
    final renteeName = data['renteeName'] ?? 'Rentee';
    final updatedAt = data['updatedAt'] as Timestamp?;

    final isRenter = renterId == currentUserId;
    final otherName = isRenter ? renteeName : renterName;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.accentColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.chat_bubble_outline,
          color: AppColors.accentColor,
          size: 20,
        ),
      ),
      title: Text(
        itemName,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        '$otherName: $lastMessage',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.lightHintColor,
        ),
      ),
      trailing: Text(
        _formatTime(updatedAt),
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.lightHintColor,
        ),
      ),
      onTap: () {
        print('💬 Opening chat: $chatId for user: $currentUserId');
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
  }
}