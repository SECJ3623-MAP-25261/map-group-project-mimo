// lib/services/message_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Result class for better error handling
class MessageResult {
  final bool success;
  final String? error;
  
  MessageResult.success() : success = true, error = null;
  MessageResult.failure(this.error) : success = false;
}

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Constants
  static const int maxMessageLength = 1000;
  static const int defaultPageSize = 50;
  static const int loadMoreSize = 25;
  static const int minParticipants = 2;

  /// Send a new message with validation and batch write
  Future<MessageResult> sendMessage({
    required String chatId,
    required String text,
    required String senderId,
    required List<String> participants,
  }) async {
    // Input validation
    final trimmedText = text.trim();
    
    if (trimmedText.isEmpty) {
      return MessageResult.failure('Message cannot be empty');
    }
    
    if (trimmedText.length > maxMessageLength) {
      return MessageResult.failure('Message too long (max $maxMessageLength characters)');
    }
    
    if (participants.isEmpty || participants.length < minParticipants) {
      return MessageResult.failure('Invalid participants');
    }
    
    if (!participants.contains(senderId)) {
      return MessageResult.failure('Sender not in participants list');
    }

    try {
      final chatDoc = _firestore.collection('item_chats').doc(chatId);
      final batch = _firestore.batch();
      
      // Add message
      final messagesCol = chatDoc.collection('messages');
      final messageRef = messagesCol.doc();
      batch.set(messageRef, {
        'text': trimmedText,
        'senderId': senderId,
        'createdAt': FieldValue.serverTimestamp(),
        'participants': participants,
        'status': 'sent',
        'type': 'text',
      });

      // Update chat metadata - use merge to avoid errors if doc doesn't exist
      batch.set(chatDoc, {
        'lastMessage': trimmedText,
        'lastSender':senderId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
      return MessageResult.success();
    } catch (e) {
      _logError('Error sending message', e);
      return MessageResult.failure('Failed to send message: ${e.toString()}');
    }
  }

  /// Get messages stream for a chat (ordered oldest to newest for chat UI)
  Stream<QuerySnapshot> getMessagesStream(String chatId) {
    try {
      return _firestore
          .collection('item_chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .snapshots()
          .handleError((error) {
        _logError('Error in messages stream', error);
      });
    } catch (e) {
      _logError('Error creating messages stream', e);
      rethrow;
    }
  }

  /// Enhanced method to ensure chat exists with proper error handling
  /// ONLY allows the renter (item owner) and rentee (person messaging) to access the chat
  Future<bool> ensureChatExists({
    required String chatId,
    required String itemId,
    required String itemName,
    required String renterId,
    required String renterName,
    required String renteeId,
    required String renteeName,
    required List<String> participants,
    required String currentUserId,
  }) async {
    // STRICT VALIDATION: Only allow renter or rentee to access
    if (currentUserId != renterId && currentUserId != renteeId) {
      _logError('User $currentUserId is not the renter ($renterId) or rentee ($renteeId)');
      return false;
    }
    
    // Validation
    if (participants.isEmpty || participants.length < minParticipants) {
      _logError('Invalid participants list: $participants');
      return false;
    }
    
    if (!participants.contains(currentUserId)) {
      _logError('User $currentUserId is not in participants: $participants');
      return false;
    }

    final chatDoc = _firestore.collection('item_chats').doc(chatId);

    try {
      // Use transaction to safely create or verify chat
      final result = await _firestore.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(chatDoc);
        
        if (!snapshot.exists) {
          _logInfo('Creating new chat: $chatId');
          
          // Create chat with current timestamp
          final now = Timestamp.now();
          transaction.set(chatDoc, {
            'itemId': itemId,
            'itemName': itemName,
            'renterId': renterId,
            'renterName': renterName,
            'renteeId': renteeId,
            'renteeName': renteeName,
            'participants': participants,
            'lastMessage': '',
            'lastSender': '',
            'updatedAt': now,
            'createdAt': now,
          });
          
          _logSuccess('Chat will be created: $chatId');
          return true;
        }
        
        // Chat exists - verify user has access
        _logInfo('Chat already exists: $chatId');
        final data = snapshot.data();
        
        if (data == null) {
          _logError('Chat data is null');
          return false;
        }
        
        // Try to get participants - be lenient if not found (handles old malformed chats)
        final existingParticipants = (data['participants'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList();
        
        // If no participants array, check renterId and renteeId fields
        if (existingParticipants == null || existingParticipants.isEmpty) {
          _logInfo('No participants array, checking renterId/renteeId fields');
          final chatRenterId = data['renterId']?.toString() ?? '';
          final chatRenteeId = data['renteeId']?.toString() ?? '';
          
          if (chatRenterId.isEmpty && chatRenteeId.isEmpty) {
            _logError('No valid participant information found');
            return false;
          }
          
          // Check if current user matches either renterId or renteeId
          if (currentUserId == chatRenterId || currentUserId == chatRenteeId) {
            _logSuccess('User has access via renterId/renteeId match');
            
            // Update the document to include participants array for future use
            transaction.update(chatDoc, {
              'participants': [chatRenterId, chatRenteeId],
            });
            
            return true;
          }
          
          _logError('User $currentUserId does not match renterId ($chatRenterId) or renteeId ($chatRenteeId)');
          return false;
        }
        
        // Standard participant check
        if (!existingParticipants.contains(currentUserId)) {
          _logError('User $currentUserId not in existing participants: $existingParticipants');
          return false;
        }
        
        _logSuccess('User has access to chat');
        return true;
      });
      
      return result;
      
    } catch (e) {
      _logError('Error ensuring chat exists', e);
      return false;
    }
  }

  /// Debug method to check chat access and permissions
  Future<Map<String, dynamic>> debugChatAccess(String chatId, String userId) async {
    try {
      final chatDoc = _firestore.collection('item_chats').doc(chatId);
      final snapshot = await chatDoc.get();
      
      if (!snapshot.exists) {
        return {
          'exists': false,
          'error': 'Chat document does not exist',
          'chatId': chatId,
          'userId': userId,
        };
      }
      
      final data = snapshot.data();
      if (data == null) {
        return {
          'exists': true,
          'error': 'Chat data is null',
          'chatId': chatId,
          'userId': userId,
        };
      }
      
      final participants = (data['participants'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [];
      
      final hasAccess = participants.contains(userId);
      
      return {
        'exists': true,
        'hasAccess': hasAccess,
        'participants': participants,
        'currentUser': userId,
        'chatData': {
          'itemId': data['itemId'],
          'itemName': data['itemName'],
          'renterId': data['renterId'],
          'renteeId': data['renteeId'],
        },
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'chatId': chatId,
        'userId': userId,
      };
    }
  }

  /// Get messages with pagination (for future optimization)
  Stream<QuerySnapshot> getMessagesStreamPaginated(
    String chatId, {
    int limit = defaultPageSize,
  }) {
    return _firestore
        .collection('item_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .limit(limit)
        .snapshots();
  }

  /// Load more messages for pagination
  Future<QuerySnapshot> loadMoreMessages(
    String chatId,
    DocumentSnapshot lastDocument, {
    int limit = loadMoreSize,
  }) {
    return _firestore
        .collection('item_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .startAfterDocument(lastDocument)
        .limit(limit)
        .get();
  }

  /// Get unread messages count for a chat
  /// Fixed to work without composite index
  Stream<int> getUnreadCount(String chatId, String userId, [Timestamp? lastSeen]) {
    final compareTime = lastSeen ?? 
        Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30)));
    
    return _firestore
        .collection('item_chats')
        .doc(chatId)
        .collection('messages')
        .where('createdAt', isGreaterThan: compareTime)
        .snapshots()
        .map((snapshot) {
          // Filter out messages from current user in memory
          return snapshot.docs
              .where((doc) {
                final data = doc.data() as Map<String, dynamic>?;
                return data?['senderId'] != userId;
              })
              .length;
        });
  }

  /// Delete a message (soft delete - marks as deleted)
  Future<bool> deleteMessage(String chatId, String messageId, String userId) async {
    try {
      final messageRef = _firestore
          .collection('item_chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);
      
      final snapshot = await messageRef.get();
      if (!snapshot.exists) return false;
      
      final data = snapshot.data();
      if (data?['senderId'] != userId) {
        _logError('User $userId cannot delete message sent by ${data?['senderId']}');
        return false;
      }
      
      await messageRef.update({
        'deleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      _logError('Error deleting message', e);
      return false;
    }
  }

  // Logging helpers
  void _logInfo(String message) {
    print('ℹ️ [MessageService] $message');
  }

  void _logSuccess(String message) {
    print('✅ [MessageService] $message');
  }

  void _logError(String message, [Object? error]) {
    print('❌ [MessageService] $message${error != null ? ': $error' : ''}');
  }
}