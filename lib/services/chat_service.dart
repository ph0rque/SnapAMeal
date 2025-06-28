import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/content_filter_service.dart';
import '../utils/logger.dart';
import '../services/fasting_service.dart';
import '../models/fasting_session.dart';
import 'in_app_notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ContentFilterService? _contentFilterService;
  final FastingService? _fastingService;
  final InAppNotificationService _notificationService = InAppNotificationService();

  ChatService({
    ContentFilterService? contentFilterService,
    FastingService? fastingService,
  }) : _contentFilterService = contentFilterService,
       _fastingService = fastingService;

  // Get the appropriate collection name
  String _getChatCollectionName() {
    return 'chat_rooms';
  }

  // Get chat stream for the current user
  Stream<QuerySnapshot> getChatsStream() {
    try {
      final String currentUserId = _auth.currentUser!.uid;
      final collectionName = _getChatCollectionName();
      return _firestore
          .collection(collectionName)
          .where('members', arrayContains: currentUserId)
          .orderBy('lastMessageTimestamp', descending: true)
          .snapshots()
          .handleError((error) {
            if (error.toString().contains('permission-denied')) {
              Logger.d('Permission denied for chat rooms, returning empty stream');
            } else {
              Logger.d('Error in chat rooms stream: $error');
            }
            return null;
          });
    } catch (e) {
      Logger.d('Error setting up chat rooms stream: $e');
      // Return empty stream to avoid crashes
      return const Stream<QuerySnapshot>.empty();
    }
  }

  // Get message stream for a specific chat room
  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    try {
      final collectionName = _getChatCollectionName();
      return _firestore
          .collection(collectionName)
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .handleError((error) {
            if (error.toString().contains('permission-denied')) {
              Logger.d('Permission denied for chat messages, returning empty stream');
            } else {
              Logger.d('Error in chat messages stream: $error');
            }
            return null;
          });
    } catch (e) {
      Logger.d('Error setting up chat messages stream: $e');
      // Return empty stream to avoid crashes
      return const Stream<QuerySnapshot>.empty();
    }
  }

  // Send a message to a specific chat room
  Future<void> sendMessage(String chatRoomId, String message) async {
    try {
      final String currentUserId = _auth.currentUser!.uid;
      final Timestamp timestamp = Timestamp.now();
      final collectionName = _getChatCollectionName();

      // First check if chat room exists, create it if it doesn't
      final chatRoomRef = _firestore.collection(collectionName).doc(chatRoomId);
      final chatRoomDoc = await chatRoomRef.get();
      
      if (!chatRoomDoc.exists) {
        Logger.d('Chat room $chatRoomId does not exist, attempting to create it');
        
        // Try to extract member IDs from chat room ID for fallback creation
        if (chatRoomId.startsWith('chat_') && chatRoomId.contains('_')) {
          final memberIds = chatRoomId.substring(5).split('_'); // Remove 'chat_' prefix
          if (memberIds.length == 2) {
            await chatRoomRef.set({
              'members': memberIds,
              'isGroup': false,
              'createdAt': FieldValue.serverTimestamp(),
              'lastMessage': '',
              'lastMessageTime': FieldValue.serverTimestamp(),
            });
            Logger.d('Successfully created missing chat room: $chatRoomId');
          }
        }
      }

      await _firestore
          .collection(collectionName)
          .doc(chatRoomId)
          .collection('messages')
          .add({
            'senderId': currentUserId,
            'message': message,
            'timestamp': timestamp,
            'isViewed':
                false, // Note: isViewed logic will need to be updated for groups
          });

      // Also update the last message timestamp on the chat room for sorting
      await _firestore.collection(collectionName).doc(chatRoomId).update({
        'lastMessageTimestamp': timestamp,
        'lastMessage': message,
      });

      // Create notifications for other chat members
      try {
        await _createMessageNotifications(
          chatRoomId: chatRoomId,
          senderId: currentUserId,
          messagePreview: message.length > 50 ? '${message.substring(0, 50)}...' : message,
        );
      } catch (e) {
        Logger.d('Error creating message notifications: $e');
        // Don't fail the message send if notification creation fails
      }
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        Logger.d('Permission denied for sending message, message not sent');
        // Don't throw error, just log it
      } else {
        Logger.d('Error sending message: $e');
        rethrow;
      }
    }
  }

  // Create a new group chat
  Future<String> createGroupChat(List<String> memberIds) async {
    final String currentUserId = _auth.currentUser!.uid;
    if (!memberIds.contains(currentUserId)) {
      memberIds.add(currentUserId);
    }

    final collectionName = _getChatCollectionName();
    final chatRoomRef = await _firestore.collection(collectionName).add({
      'members': memberIds,
      'isGroup': memberIds.length > 2,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'createdBy': currentUserId,
    });

    return chatRoomRef.id;
  }

  // Mark messages as viewed
  Future<void> markMessagesAsViewed(String receiverId) async {
    final String currentUserId = _auth.currentUser!.uid;

    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    final collectionName = _getChatCollectionName();
    final querySnapshot = await _firestore
        .collection(collectionName)
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isViewed', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isViewed': true});
    }
    await batch.commit();
  }

  /// Get filtered messages stream for a specific chat room
  Stream<List<DocumentSnapshot>> getFilteredMessages(String chatRoomId) async* {
    final collectionName = _getChatCollectionName();
    await for (final snapshot
        in _firestore
            .collection(collectionName)
            .doc(chatRoomId)
            .collection('messages')
            .orderBy('timestamp', descending: false)
            .snapshots()) {
      if (_contentFilterService == null || _fastingService == null) {
        yield snapshot.docs;
        continue;
      }

      try {
        // Get current fasting session
        final currentSession = await _fastingService!.getCurrentSession();

        // Filter messages based on fasting state
        final filteredMessages = await _contentFilterService!.filterChatMessages(
          snapshot.docs,
          currentSession,
        );

        yield filteredMessages;
      } catch (e) {
        Logger.d('Error filtering chat messages: $e');
        yield snapshot.docs; // Fallback to unfiltered
      }
    }
  }

  /// Check if message should be filtered before sending
  Future<bool> shouldFilterMessage(String message) async {
    if (_contentFilterService == null || _fastingService == null) {
      return false;
    }

    try {
      final currentSession = await _fastingService!.getCurrentSession();
      if (currentSession?.isActive != true) {
        return false;
      }

      final result = await _contentFilterService!.shouldFilterContent(
        content: message,
        contentType: ContentType.chat,
        fastingSession: currentSession!,
      );

      return result.shouldFilter;
    } catch (e) {
      Logger.d('Error checking message filter: $e');
      return false;
    }
  }

  /// Send message with content filtering warning
  Future<Map<String, dynamic>> sendMessageWithFiltering(
    String chatRoomId,
    String message,
  ) async {
    final shouldFilter = await shouldFilterMessage(message);

    if (shouldFilter) {
      // Return filter warning instead of sending
      return {
        'success': false,
        'filtered': true,
        'message':
            'Message contains content that might affect your fasting goals. Consider rephrasing or waiting until your eating window.',
      };
    }

    // Send message normally
    await sendMessage(chatRoomId, message);
    return {
      'success': true,
      'filtered': false,
      'message': 'Message sent successfully',
    };
  }

  /// Get alternative suggestion for filtered message
  Future<String?> getAlternativeMessageSuggestion(
    String originalMessage,
  ) async {
    if (_contentFilterService == null || _fastingService == null) {
      return null;
    }

    try {
      final currentSession = await _fastingService!.getCurrentSession();
      if (currentSession?.isActive != true) {
        return null;
      }

      // Use content filter to get alternative content
      final result = await _contentFilterService!.shouldFilterContent(
        content: originalMessage,
        contentType: ContentType.chat,
        fastingSession: currentSession!,
      );

      if (result.shouldFilter && result.category != null) {
        final alternative = await _contentFilterService!
            .generateAlternativeContent(result.category!, currentSession);

        return alternative.description;
      }

      return null;
    } catch (e) {
      Logger.d('Error generating alternative message: $e');
      return null;
    }
  }

  /// Create health-focused group chat or return existing one
  Future<String> createHealthGroupChat(
    List<String> memberIds,
    String groupName,
    String healthCategory, // e.g., 'fasting', 'weight-loss', 'fitness'
  ) async {
    final String currentUserId = _auth.currentUser!.uid;
    if (!memberIds.contains(currentUserId)) {
      memberIds.add(currentUserId);
    }

    final collectionName = _getChatCollectionName();
    
    // Sort member IDs for consistent searching
    final sortedMemberIds = List<String>.from(memberIds)..sort();
    
    // Check if a health group chat already exists with the same members and name
    try {
      final existingChats = await _firestore
          .collection(collectionName)
          .where('isHealthGroup', isEqualTo: true)
          .where('groupName', isEqualTo: groupName)
          .where('members', isEqualTo: sortedMemberIds)
          .limit(1)
          .get();
      
      if (existingChats.docs.isNotEmpty) {
        Logger.d('Found existing health group chat: ${existingChats.docs.first.id}');
        return existingChats.docs.first.id;
      }
    } catch (e) {
      Logger.d('Error checking for existing health group chat: $e');
      // Continue to create new chat
    }

    // Create new health group chat
    final chatRoomRef = await _firestore.collection(collectionName).add({
      'members': sortedMemberIds,
      'isGroup': true,
      'isHealthGroup': true,
      'groupName': groupName,
      'healthCategory': healthCategory,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'createdBy': currentUserId,
      'settings': {
        'contentFiltering': true,
        'motivationalMode': true,
        'shareProgress': true,
      },
    });

    Logger.d('Created new health group chat: ${chatRoomRef.id}');
    return chatRoomRef.id;
  }

  /// Get health group stats
  Future<Map<String, dynamic>> getHealthGroupStats(String chatRoomId) async {
    try {
      // Get group info
      final collectionName = _getChatCollectionName();
      final groupDoc = await _firestore
          .collection(collectionName)
          .doc(chatRoomId)
          .get();
      final groupData = groupDoc.data();

      if (groupData?['isHealthGroup'] != true) {
        return {};
      }

      final members = List<String>.from(groupData?['members'] ?? []);

      // Get member fasting stats if this is a fasting group
      if (groupData?['healthCategory'] == 'fasting' &&
          _fastingService != null) {
        final memberStats = <Map<String, dynamic>>[];

        for (final memberId in members) {
          try {
            final sessions = await _firestore
                .collection('fasting_sessions')
                .where('userId', isEqualTo: memberId)
                .where('isActive', isEqualTo: true)
                .get();

            if (sessions.docs.isNotEmpty) {
              final sessionData = sessions.docs.first.data();
              sessionData['id'] = sessions.docs.first.id;
              final session = FastingSession.fromMap(sessionData);

              memberStats.add({
                'userId': memberId,
                'isActive': session.isActive,
                'progress': session.progressPercentage,
                'hoursElapsed': session.elapsedTime.inHours,
              });
            }
          } catch (e) {
            Logger.d('Error getting member stats: $e');
          }
        }

        return {
          'totalMembers': members.length,
          'activeFasters': memberStats
              .where((s) => s['isActive'] == true)
              .length,
          'memberStats': memberStats,
        };
      }

      return {
        'totalMembers': members.length,
        'healthCategory': groupData?['healthCategory'],
      };
    } catch (e) {
      Logger.d('Error getting health group stats: $e');
      return {};
    }
  }

  /// Helper method to create message notifications for chat room members
  Future<void> _createMessageNotifications({
    required String chatRoomId,
    required String senderId,
    required String messagePreview,
  }) async {
    try {
      // Get chat room info to find members
      final collectionName = _getChatCollectionName();
      final chatRoomDoc = await _firestore
          .collection(collectionName)
          .doc(chatRoomId)
          .get();

      if (!chatRoomDoc.exists) return;

      final chatRoomData = chatRoomDoc.data() as Map<String, dynamic>;
      final members = List<String>.from(chatRoomData['members'] ?? []);

      // Get sender's info
      final senderDoc = await _firestore.collection('users').doc(senderId).get();
      final senderData = senderDoc.data();
      final senderName = senderData?['username'] ?? senderData?['displayName'] ?? 'Someone';

      // Create notifications for all members except the sender
      if (senderName != 'Someone') { // Only create notifications if we have a valid sender name
        for (final memberId in members) {
          if (memberId != senderId) {
            try {
              await _notificationService.createMessageNotification(
                receiverId: memberId,
                senderName: senderName,
                senderId: senderId,
                chatRoomId: chatRoomId,
                messagePreview: messagePreview,
              );
            } catch (e) {
              Logger.d('Error creating message notification for member $memberId: $e');
            }
          }
        }
      }
    } catch (e) {
      Logger.d('Error creating message notifications: $e');
    }
  }
}
