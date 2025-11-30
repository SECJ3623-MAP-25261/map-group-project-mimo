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

            String timeText = '';
            if (updatedAt is Timestamp) {
              final dt = updatedAt.toDate();
              final hh = dt.hour.toString().padLeft(2, '0');
              final mm = dt.minute.toString().padLeft(2, '0');
              timeText = '$hh:$mm';
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
