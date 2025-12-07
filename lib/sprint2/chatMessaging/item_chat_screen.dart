// lib/sprint2/chatMessaging/item_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import 'package:profile_managemenr/services/auth_service.dart';
import 'package:profile_managemenr/services/message_service.dart';
import 'dart:convert';

class ItemChatScreen extends StatefulWidget {
  final String chatId;
  final String itemId;
  final String itemName;
  final String renterId;
  final String renterName;
  final String renteeId;
  final String renteeName;
  final List<dynamic>? itemImages;

  const ItemChatScreen({
    super.key,
    required this.chatId,
    required this.itemId,
    required this.itemName,
    required this.renterId,
    required this.renterName,
    required this.renteeId,
    required this.renteeName,
    this.itemImages,
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
  int _currentImageIndex = 0;
  
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
    
    final chatIdParts = widget.chatId.split('|');
    if (chatIdParts.length != 3) {
      print('⚠️ WARNING: Chat ID format may be malformed!');
    }

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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  String _formatMessageTime(Timestamp? timestamp) {
    if (timestamp == null) return '...';
    final dt = timestamp.toDate();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMessageBubble(DocumentSnapshot doc, bool isMe, bool isSmallScreen, bool isVerySmallScreen) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return const SizedBox.shrink();
    
    final msgText = data['text'] ?? '';
    final isDeleted = data['deleted'] == true;
    final createdAt = data['createdAt'] as Timestamp?;
    
    final avatarSize = isVerySmallScreen ? 28.0 : 32.0;
    final maxBubbleWidth = isVerySmallScreen ? 240.0 : (isSmallScreen ? 260.0 : 280.0);
    final fontSize = isVerySmallScreen ? 14.0 : 15.0;
    final timeSize = isVerySmallScreen ? 9.0 : 10.0;
    
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 3 : 4,
        horizontal: isSmallScreen ? 6 : 8,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: AppColors.lightHintColor.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_rounded,
                size: isVerySmallScreen ? 16 : 18,
                color: AppColors.lightTextColor,
              ),
            ),
            SizedBox(width: isSmallScreen ? 6 : 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: isVerySmallScreen ? 6 : 8,
                horizontal: isVerySmallScreen ? 10 : 12,
              ),
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
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
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 3,
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
                      fontSize: fontSize,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(createdAt),
                    style: TextStyle(
                      fontSize: timeSize,
                      color: isMe ? Colors.white70 : AppColors.lightHintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) SizedBox(width: isSmallScreen ? 6 : 8),
        ],
      ),
    );
  }

  Widget _buildItemDetails(bool isSmallScreen, bool isVerySmallScreen) {
    final hasImages = widget.itemImages != null && widget.itemImages!.isNotEmpty;
    final firstImage = hasImages ? widget.itemImages![0] : null;

    final containerPadding = isVerySmallScreen ? 12.0 : (isSmallScreen ? 14.0 : 16.0);
    final titleSize = isVerySmallScreen ? 16.0 : (isSmallScreen ? 17.0 : 18.0);
    final imageHeight = isVerySmallScreen ? 100.0 : (isSmallScreen ? 110.0 : 120.0);
    final metaSize = isVerySmallScreen ? 12.0 : (isSmallScreen ? 13.0 : 14.0);

    return Container(
      margin: EdgeInsets.all(isSmallScreen ? 8 : 12),
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Name
          Text(
            widget.itemName,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: AppColors.lightTextColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(height: isSmallScreen ? 10 : 12),
          
          // Item Image
          if (hasImages) ...[
            GestureDetector(
              onTap: () => _showFullScreenImage(firstImage.toString()),
              child: Container(
                height: imageHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: firstImage is String && firstImage.startsWith('http')
                      ? Image.network(
                          firstImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.image_not_supported_rounded),
                        )
                      : Image.memory(
                          base64Decode(firstImage.toString()),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.image_not_supported_rounded),
                        ),
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 6 : 8),
            // Image counter if multiple images
            if (widget.itemImages!.length > 1)
              Center(
                child: Text(
                  'View ${widget.itemImages!.length} photos',
                  style: TextStyle(
                    color: AppColors.accentColor,
                    fontSize: isVerySmallScreen ? 11 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            SizedBox(height: isSmallScreen ? 8 : 12),
          ],
          
          // Participants Info
          Row(
            children: [
              Icon(
                Icons.person_rounded,
                size: isVerySmallScreen ? 14 : 16,
                color: AppColors.lightHintColor,
              ),
              SizedBox(width: isSmallScreen ? 6 : 8),
              Flexible(
                child: Text(
                  'With ${widget.renterName}',
                  style: TextStyle(
                    color: AppColors.lightTextColor,
                    fontSize: metaSize,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(String imageData) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 1.0,
                maxScale: 4.0,
                child: imageData.startsWith('http')
                    ? Image.network(imageData, fit: BoxFit.contain)
                    : Image.memory(base64Decode(imageData), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(bool isSmallScreen, bool isVerySmallScreen) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.accentColor),
            SizedBox(height: isSmallScreen ? 12 : 16),
            Text(
              'Loading chat...',
              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
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
                _errorMessage!,
                style: TextStyle(
                  color: AppColors.errorColor,
                  fontSize: isSmallScreen ? 13 : 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              ElevatedButton(
                onPressed: _initializeChat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentColor,
                ),
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
          return Center(
            child: CircularProgressIndicator(color: AppColors.accentColor),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: isSmallScreen ? 48 : 56,
                    color: AppColors.errorColor,
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scrollController.hasClients) return;
          final isNearBottom = _scrollController.position.maxScrollExtent - 
                               _scrollController.position.pixels < 100;
          if (isNearBottom || docs.length == 1) {
            _scrollToBottom();
          }
        });

        return ListView.builder(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 6 : 8,
            horizontal: isSmallScreen ? 8 : 12,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>?;

            if (data == null) return const SizedBox.shrink();

            final senderId = data['senderId'] ?? '';
            final isMe = senderId == _currentUserId;

            final bool isDeleted = data['deleted'] == true;
            final String messageId = doc.id;

            return GestureDetector(
              onLongPress: (!isMe || isDeleted || _currentUserId == null)
                  ? null
                  : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text('Delete message?'),
                          content: const Text(
                            'This will mark the message as deleted for everyone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        final success = await _messageService.deleteMessage(
                          widget.chatId,
                          messageId,
                          _currentUserId!,
                        );

                        if (!success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('You can only delete your own messages.'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      }
                    },
              child: _buildMessageBubble(doc, isMe, isSmallScreen, isVerySmallScreen),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isVerySmallScreen = screenWidth < 340;
    
    final isRenter = _currentUserId == widget.renterId;
    final otherName = isRenter ? widget.renteeName : widget.renterName;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.accentColor,
        elevation: 0,
        title: Text(
          'Chat with $otherName',
          style: TextStyle(
            color: Colors.white,
            fontSize: isVerySmallScreen ? 15 : (isSmallScreen ? 16 : 17),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            size: isSmallScreen ? 20 : 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: AppColors.lightBackground,
      body: Column(
        children: [
          // Item details at top
          _buildItemDetails(isSmallScreen, isVerySmallScreen),
          
          // Messages
          Expanded(
            child: _buildMessagesList(isSmallScreen, isVerySmallScreen),
          ),
          
          // Input field
          if (_errorMessage == null)
            SafeArea(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 6 : 8,
                  vertical: isSmallScreen ? 6 : 8,
                ),
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
                        style: TextStyle(
                          fontSize: isVerySmallScreen ? 14 : 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            fontSize: isVerySmallScreen ? 14 : 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 10 : 12,
                            vertical: 8,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        enabled: !_isSending,
                      ),
                    ),
                    IconButton(
                      icon: _isSending
                          ? SizedBox(
                              width: isVerySmallScreen ? 18 : 20,
                              height: isVerySmallScreen ? 18 : 20,
                              child: const CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              Icons.send_rounded,
                              size: isVerySmallScreen ? 20 : 22,
                            ),
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