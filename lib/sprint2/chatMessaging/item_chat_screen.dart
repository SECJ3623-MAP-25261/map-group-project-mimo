// lib/sprint2/chatMessaging/item_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import 'package:profile_managemenr/services/auth_service.dart';

class ItemChatScreen extends StatefulWidget {
  final String chatId;
  final String itemId;
  final String itemName;
  final String renterId;
  final String renterName;
  final String renteeId;
  final String renteeName;

  const ItemChatScreen({
    super.key,
    required this.chatId,
    required this.itemId,
    required this.itemName,
    required this.renterId,
    required this.renterName,
    required this.renteeId,
    required this.renteeName,
  });

  /// Helper to build a consistent chatId when starting a new chat:
  /// e.g. ItemChatScreen.buildChatId(itemId, renterId, renteeId)
  static String buildChatId(String itemId, String renterId, String renteeId) {
    // You can change this pattern if you want, but keep it unique & stable.
    return '${itemId}_$renterId\_$renteeId';
  }

  @override
  State<ItemChatScreen> createState() => _ItemChatScreenState();
}

class _ItemChatScreenState extends State<ItemChatScreen> {
  final _controller = TextEditingController();
  final _auth = AuthService();

  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _auth.userId;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final userId = _currentUserId;
    final text = _controller.text.trim();

    if (userId == null || text.isEmpty) return;

    final now = DateTime.now();

    final chatDoc =
        FirebaseFirestore.instance.collection('item_chats').doc(widget.chatId);
    final messagesCol = chatDoc.collection('messages');

    try {
      // 1. Add message
      await messagesCol.add({
        'text': text,
        'senderId': userId,
        'createdAt': now,
      });

      // 2. Update chat meta document
      await chatDoc.set({
        'itemId': widget.itemId,
        'itemName': widget.itemName,
        'renterId': widget.renterId,
        'renterName': widget.renterName,
        'renteeId': widget.renteeId,
        'renteeName': widget.renteeName,
        'participants': [widget.renterId, widget.renteeId],
        'lastMessage': text,
        'updatedAt': now,
      }, SetOptions(merge: true));

      _controller.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _currentUserId;
    final isRenter = userId == widget.renterId;
    final otherName = isRenter ? widget.renteeName : widget.renterName;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.accentColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat with $otherName',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              widget.itemName,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: AppColors.lightBackground,
      body: Column(
        children: [
          // MESSAGES LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('item_chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Failed to load messages.'),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Start the conversation!'),
                  );
                }

                return ListView.builder(
                  reverse: true, // newest at bottom visually
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                        docs[index].data() as Map<String, dynamic>? ?? {};
                    final msgText = data['text'] ?? '';
                    final senderId = data['senderId'] ?? '';
                    final createdAt = data['createdAt'];

                    final isMe = senderId == userId;

                    String timeText = '';
                    if (createdAt is Timestamp) {
                      final dt = createdAt.toDate();
                      final hh = dt.hour.toString().padLeft(2, '0');
                      final mm = dt.minute.toString().padLeft(2, '0');
                      timeText = '$hh:$mm';
                    }

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        constraints: const BoxConstraints(maxWidth: 280),
                        decoration: BoxDecoration(
                          color: isMe
                              ? AppColors.accentColor
                              : AppColors.lightCardBackground,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msgText,
                              style: TextStyle(
                                color: isMe ? Colors.white : AppColors.lightTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeText,
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe
                                    ? Colors.white70
                                    : AppColors.lightHintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // INPUT FIELD
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.lightCardBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: AppColors.accentColor,
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
