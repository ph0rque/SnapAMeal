import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/content_filter_service.dart';
import '../utils/logger.dart';
import '../services/fasting_service.dart';
import '../models/fasting_session.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ContentFilterService? _contentFilterService;
  final FastingService? _fastingService;

  ChatService({
    ContentFilterService? contentFilterService,
    FastingService? fastingService,
  }) : _contentFilterService = contentFilterService,
       _fastingService = fastingService;

  // Get chat stream for the current user
  Stream<QuerySnapshot> getChatsStream() {
    final String currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection('chat_rooms')
        .where('members', arrayContains: currentUserId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }

  // Get message stream for a specific chat room
  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Send a message to a specific chat room
  Future<void> sendMessage(String chatRoomId, String message) async {
    final String currentUserId = _auth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();

    await _firestore
        .collection('chat_rooms')
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
    await _firestore.collection('chat_rooms').doc(chatRoomId).update({
      'lastMessageTimestamp': timestamp,
    });
  }

  // Create a new group chat
  Future<String> createGroupChat(List<String> memberIds) async {
    final String currentUserId = _auth.currentUser!.uid;
    if (!memberIds.contains(currentUserId)) {
      memberIds.add(currentUserId);
    }

    final chatRoomRef = await _firestore.collection('chat_rooms').add({
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

    final querySnapshot = await _firestore
        .collection('chat_rooms')
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
    await for (final snapshot
        in _firestore
            .collection('chat_rooms')
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
        final currentSession = await _fastingService.getCurrentSession();

        // Filter messages based on fasting state
        final filteredMessages = await _contentFilterService.filterChatMessages(
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
      final currentSession = await _fastingService.getCurrentSession();
      if (currentSession?.isActive != true) {
        return false;
      }

      final result = await _contentFilterService.shouldFilterContent(
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
      final currentSession = await _fastingService.getCurrentSession();
      if (currentSession?.isActive != true) {
        return null;
      }

      // Use content filter to get alternative content
      final result = await _contentFilterService.shouldFilterContent(
        content: originalMessage,
        contentType: ContentType.chat,
        fastingSession: currentSession!,
      );

      if (result.shouldFilter && result.category != null) {
        final alternative = await _contentFilterService
            .generateAlternativeContent(result.category!, currentSession);

        return alternative.description;
      }

      return null;
    } catch (e) {
      Logger.d('Error generating alternative message: $e');
      return null;
    }
  }

  /// Create health-focused group chat
  Future<String> createHealthGroupChat(
    List<String> memberIds,
    String groupName,
    String healthCategory, // e.g., 'fasting', 'weight-loss', 'fitness'
  ) async {
    final String currentUserId = _auth.currentUser!.uid;
    if (!memberIds.contains(currentUserId)) {
      memberIds.add(currentUserId);
    }

    final chatRoomRef = await _firestore.collection('chat_rooms').add({
      'members': memberIds,
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

    return chatRoomRef.id;
  }

  /// Get health group stats
  Future<Map<String, dynamic>> getHealthGroupStats(String chatRoomId) async {
    try {
      // Get group info
      final groupDoc = await _firestore
          .collection('chat_rooms')
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
}
