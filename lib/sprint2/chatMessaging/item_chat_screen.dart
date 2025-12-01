// lib/sprint2/chatMessaging/item_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import 'package:profile_managemenr/services/auth_service.dart';
import 'package:profile_managemenr/services/message_service.dart';

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

  static String buildChatId(String itemId, String userId1, String userId2) {
    final sorted = [userId1, userId2]..sort();
    return '$itemId|${sorted[0]}|${sorted[1]}';
  }

  @override
  State<ItemChatScreen> createState() => _ItemChatScreenState();
}

class _ItemChatScreenState extends State<ItemChatScreen> {
  final _controller = TextEditingController();
  final _messageService = MessageService();
  final _scrollController = ScrollController();
  
  String? _currentUserId;
  bool _isSending = false;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Debounce timer to prevent duplicate sends
  DateTime? _lastSendTime;
  static const _sendDebounceMs = 500;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!mounted || !_scrollController.hasClients) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _initializeChat() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    _currentUserId = auth.userId;

    if (_currentUserId == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'No user ID found. Please log in.';
      });
      return;
    }

    print('🚀 Initializing chat for user: $_currentUserId');
    print('📋 Chat ID received: ${widget.chatId}');
    print('📋 Item ID: ${widget.itemId}');
    print('👨‍💼 Renter: ${widget.renterId} (${widget.renterName})');
    print('👩‍💼 Rentee: ${widget.renteeId} (${widget.renteeName})');
    
    // Validate chatId format
    final chatIdParts = widget.chatId.split('|');
    if (chatIdParts.length != 3) {
      print('⚠️ WARNING: Chat ID format may be malformed!');
      print('   Expected "itemId|userId1|userId2", got: ${widget.chatId}');
      print('   Chat ID has ${chatIdParts.length} parts instead of 3');
      print('   Will attempt to use it anyway (backwards compatibility)');
    } else {
      print('✅ Chat ID format valid: itemId=${chatIdParts[0]}, user1=${chatIdParts[1]}, user2=${chatIdParts[2]}');
    }

    // Validate user is a participant
    final participants = [widget.renterId, widget.renteeId];
    print('👥 Participants list: $participants');
    if (!participants.contains(_currentUserId)) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'You are not a participant in this chat.\n\n'
                       'Your ID: $_currentUserId\n'
                       'Renter: ${widget.renterId}\n'
                       'Rentee: ${widget.renteeId}';
      });
      return;
    }

    final success = await _messageService.ensureChatExists(
      chatId: widget.chatId,
      itemId: widget.itemId,
      itemName: widget.itemName,
      renterId: widget.renterId,
      renterName: widget.renterName,
      renteeId: widget.renteeId,
      renteeName: widget.renteeName,
      participants: participants,
      currentUserId: _currentUserId!,
    );

    print('✅ ensureChatExists returned: $success');

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (!success) {
        _errorMessage = 'Cannot access this chat. You may not be a participant.\n\n'
                       'Debug Info:\n'
                       'ChatID: ${widget.chatId}\n'
                       'Current User: $_currentUserId\n'
                       'Participants: $participants';
      }
    });

    if (success) {
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    // Debounce check
    final now = DateTime.now();
    if (_lastSendTime != null && 
        now.difference(_lastSendTime!).inMilliseconds < _sendDebounceMs) {
      return;
    }
    
    if (_isSending) return;
    
    final userId = _currentUserId;
    final text = _controller.text.trim();

    if (userId == null || text.isEmpty) return;

    setState(() {
      _isSending = true;
    });
    
    _lastSendTime = now;

    final result = await _messageService.sendMessage(
      chatId: widget.chatId,
      text: text,
      senderId: userId,
      participants: [widget.renterId, widget.renteeId],
    );

    if (!mounted) return;

    setState(() {
      _isSending = false;
    });

    if (result.success) {
      _controller.clear();
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to send message'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  String _formatMessageTime(Timestamp? timestamp) {
    if (timestamp == null) return '...';
    
    final dt = timestamp.toDate();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMessageBubble(DocumentSnapshot doc, bool isMe) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return const SizedBox.shrink();
    
    final msgText = data['text'] ?? '';
    final isDeleted = data['deleted'] == true;
    final createdAt = data['createdAt'] as Timestamp?;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.lightHintColor.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 18,
                color: AppColors.lightTextColor,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              constraints: const BoxConstraints(maxWidth: 280),
              decoration: BoxDecoration(
                color: isMe ? AppColors.accentColor : AppColors.lightCardBackground,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    isDeleted ? 'Message deleted' : msgText,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppColors.lightTextColor,
                      fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : AppColors.lightHintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading chat...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.errorColor),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.errorColor,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeChat,
                child: const Text('Retry'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _messageService.getMessagesStream(widget.chatId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.errorColor),
                const SizedBox(height: 16),
                const Text('Failed to load messages.'),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.lightHintColor),
                SizedBox(height: 16),
                Text(
                  'No messages yet.\nStart the conversation!',
                  style: TextStyle(color: AppColors.lightHintColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;

        // Scroll to bottom only on first load or when user is near bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scrollController.hasClients) return;
          
          final position = _scrollController.position;
          final isNearBottom = position.maxScrollExtent - position.pixels < 100;
          
          if (isNearBottom || docs.length == 1) {
            _scrollToBottom();
          }
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>?;
            final senderId = data?['senderId'] ?? '';
            final isMe = senderId == _currentUserId;
            
            return _buildMessageBubble(doc, isMe);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRenter = _currentUserId == widget.renterId;
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
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              widget.itemName,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: AppColors.lightBackground,
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(),
          ),
          if (_errorMessage == null)
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
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        enabled: !_isSending,
                      ),
                    ),
                    IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      color: _isSending ? AppColors.lightHintColor : AppColors.accentColor,
                      onPressed: _isSending ? null : _sendMessage,
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