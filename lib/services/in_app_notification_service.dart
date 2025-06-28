import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';

enum NotificationType {
  friendRequest,
  unreadMessage,
  groupInvitation,
  groupMessage,
  aiAdvice,
}

class InAppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final bool isRead;

  InAppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.data,
    this.isRead = false,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'data': data,
      'is_read': isRead,
    };
  }

  static InAppNotification fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InAppNotification(
      id: doc.id,
      type: NotificationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => NotificationType.friendRequest,
      ),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      isRead: data['is_read'] ?? false,
    );
  }

  InAppNotification copyWith({
    bool? isRead,
  }) {
    return InAppNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      timestamp: timestamp,
      data: data,
      isRead: isRead ?? this.isRead,
    );
  }
}

class InAppNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Stream controller for manual refresh triggers
  final StreamController<void> _refreshTrigger = StreamController<void>.broadcast();

  String? get currentUserId => _auth.currentUser?.uid;

  String get _notificationsCollection => 'notifications';
  
  String get _friendRequestsCollection => 'friend_requests';
    
  String get _chatRoomsCollection => 'chat_rooms';

  /// Get notifications stream for current user
  Stream<List<InAppNotification>> getNotificationsStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    try {
      return _firestore
          .collection(_notificationsCollection)
          .where('user_id', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => InAppNotification.fromFirestore(doc))
              .toList())
          .handleError((error) {
            Logger.d('Error in notifications stream: $error');
            return <InAppNotification>[];
          });
    } catch (e) {
      Logger.d('Error setting up notifications stream: $e');
      return Stream.value(<InAppNotification>[]);
    }
  }

  /// Get unread notification count
  Stream<int> getUnreadCountStream() {
    return getNotificationsStream().map((notifications) => 
        notifications.where((n) => !n.isRead).length);
  }

  /// Get combined unread count from multiple sources
  Stream<int> getCombinedUnreadCountStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value(0);

    // Create a stream controller to manage the stream
    late StreamController<int> controller;
    Timer? timer;
    StreamSubscription? refreshSubscription;

    Future<void> updateCount() async {
      if (controller.isClosed) return;
      
      try {
        final count = await _getCombinedCount();
        if (!controller.isClosed) {
          controller.add(count);
        }
      } catch (e) {
        Logger.d('Error updating count: $e');
        if (!controller.isClosed) {
          controller.add(0);
        }
      }
    }

    controller = StreamController<int>(
      onListen: () async {
        // Emit initial value immediately
        await updateCount();

        // Set up periodic updates (more frequent for better responsiveness)
        timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
          await updateCount();
        });

        // Listen for manual refresh triggers
        refreshSubscription = _refreshTrigger.stream.listen((_) async {
          await updateCount();
        });
      },
      onCancel: () {
        timer?.cancel();
        refreshSubscription?.cancel();
        controller.close();
      },
    );

    return controller.stream;
  }

  /// Manually trigger a refresh of the unread count
  void refreshUnreadCount() {
    _refreshTrigger.add(null);
  }

  /// Dispose resources when service is no longer needed
  void dispose() {
    _refreshTrigger.close();
  }

  /// Create test notifications for testing purposes
  Future<void> createTestNotifications() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      // Check if user already has notifications
      final existingNotifications = await _firestore
          .collection(_notificationsCollection)
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (existingNotifications.docs.isNotEmpty) {
        Logger.d('User already has notifications, skipping test creation');
        return;
      }

      // Create some test notifications
      final batch = _firestore.batch();
      final now = DateTime.now();

      // Friend request notification
      final friendRequestNotification = InAppNotification(
        id: 'test_friend_request_$userId',
        type: NotificationType.friendRequest,
        title: 'New Friend Request',
        message: 'Someone wants to be your friend',
        timestamp: now.subtract(const Duration(hours: 2)),
        data: {
          'sender_id': 'test_sender_id',
          'sender_name': 'Test Friend',
          'action_type': 'friend_request',
        },
        isRead: false,
      );

      // Message notification
      final messageNotification = InAppNotification(
        id: 'test_message_$userId',
        type: NotificationType.unreadMessage,
        title: 'New Message',
        message: 'You have a new message',
        timestamp: now.subtract(const Duration(minutes: 30)),
        data: {
          'sender_id': 'test_sender_id',
          'sender_name': 'Test Sender',
          'chat_room_id': 'test_chat_room',
          'action_type': 'open_chat',
        },
        isRead: false,
      );

      // AI advice notification
      final aiAdviceNotification = InAppNotification(
        id: 'test_ai_advice_$userId',
        type: NotificationType.aiAdvice,
        title: 'New Health Insight',
        message: 'Check out your latest health insights',
        timestamp: now.subtract(const Duration(hours: 1)),
        data: {
          'advice_type': 'health_insight',
          'action_type': 'view_advice',
        },
        isRead: false,
      );

      // Add to batch
      batch.set(
        _firestore.collection(_notificationsCollection).doc('test_friend_request_$userId'),
        {
          'user_id': userId,
          ...friendRequestNotification.toFirestore(),
        },
      );

      batch.set(
        _firestore.collection(_notificationsCollection).doc('test_message_$userId'),
        {
          'user_id': userId,
          ...messageNotification.toFirestore(),
        },
      );

      batch.set(
        _firestore.collection(_notificationsCollection).doc('test_ai_advice_$userId'),
        {
          'user_id': userId,
          ...aiAdviceNotification.toFirestore(),
        },
      );

      await batch.commit();
      Logger.d('Created test notifications for user $userId');
    } catch (e) {
      Logger.d('Error creating test notifications: $e');
    }
  }

  /// Helper method to get combined count
  Future<int> _getCombinedCount() async {
    try {
      final futures = await Future.wait([
        _getUnreadFriendRequestsCount(),
        _getUnreadMessagesCount(),
        _getUnreadNotificationsCount(),
      ]).timeout(const Duration(seconds: 10));
      
      final friendRequests = futures[0];
      final messages = futures[1]; 
      final notifications = futures[2];
      final total = friendRequests + messages + notifications;
      
      return total;
    } catch (e) {
      Logger.d('Error getting combined unread count: $e');
      return 0; // Return 0 on error to prevent UI issues
    }
  }

  /// Create a new notification
  Future<void> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      final notification = InAppNotification(
        id: '', // Will be set by Firestore
        type: type,
        title: title,
        message: message,
        timestamp: DateTime.now(),
        data: data,
      );

      final docData = notification.toFirestore();
      docData['user_id'] = userId; // Add user_id field

      await _firestore
          .collection(_notificationsCollection)
          .add(docData);

      Logger.d('Created notification for user $userId: $title');
    } catch (e) {
      Logger.d('Error creating notification: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .update({'is_read': true});
      
      // Trigger immediate refresh of unread count
      refreshUnreadCount();
    } catch (e) {
      Logger.d('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read (notifications only, not friend requests or messages)
  Future<void> markAllAsRead() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final unreadNotifications = await _firestore
          .collection(_notificationsCollection)
          .where('user_id', isEqualTo: userId)
          .where('is_read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'is_read': true});
      }
      await batch.commit();

      Logger.d('Marked ${unreadNotifications.docs.length} notifications as read for user $userId');
      
      // Trigger immediate refresh of unread count
      refreshUnreadCount();
    } catch (e) {
      Logger.d('Error marking all notifications as read: $e');
    }
  }

  /// Clear all types of notifications (notifications, friend requests, and mark messages as viewed)
  Future<void> clearAllNotifications() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final batch = _firestore.batch();
      int totalCleared = 0;

      // 1. Mark all notifications as read
      final unreadNotifications = await _firestore
          .collection(_notificationsCollection)
          .where('user_id', isEqualTo: userId)
          .where('is_read', isEqualTo: false)
          .get();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'is_read': true});
        totalCleared++;
      }

      // 2. Accept all pending friend requests (this clears them from unread count)
      final pendingRequests = await _firestore
          .collection(_friendRequestsCollection)
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      for (final doc in pendingRequests.docs) {
        batch.update(doc.reference, {'status': 'declined'}); // Decline to clear from count
        totalCleared++;
      }

      // 3. Mark all unread messages as viewed
      final chatRoomsSnapshot = await _firestore
          .collection(_chatRoomsCollection)
          .where('members', arrayContains: userId)
          .get();

      for (final chatRoom in chatRoomsSnapshot.docs) {
        final unreadMessages = await _firestore
            .collection(_chatRoomsCollection)
            .doc(chatRoom.id)
            .collection('messages')
            .where('senderId', isNotEqualTo: userId)
            .where('isViewed', isEqualTo: false)
            .get();
        
        for (final message in unreadMessages.docs) {
          batch.update(message.reference, {'isViewed': true});
          totalCleared++;
        }
      }

      await batch.commit();
      Logger.d('Cleared $totalCleared total notifications/messages for user $userId');
      
      // Trigger immediate refresh of unread count
      refreshUnreadCount();
    } catch (e) {
      Logger.d('Error clearing all notifications: $e');
    }
  }

  /// Delete old notifications (older than 30 days)
  Future<void> cleanupOldNotifications() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final oldNotifications = await _firestore
          .collection(_notificationsCollection)
          .where('user_id', isEqualTo: userId)
          .where('timestamp', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final batch = _firestore.batch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      Logger.d('Cleaned up ${oldNotifications.docs.length} old notifications');
    } catch (e) {
      Logger.d('Error cleaning up old notifications: $e');
    }
  }

  // Helper methods for counting specific notification types

  Future<int> _getUnreadFriendRequestsCount() async {
    final userId = currentUserId;
    if (userId == null) return 0;

    try {
      final snapshot = await _firestore
          .collection(_friendRequestsCollection)
          .where('receiverId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      Logger.d('Error getting unread friend requests count: $e');
      return 0;
    }
  }

  Future<int> _getUnreadMessagesCount() async {
    final userId = currentUserId;
    if (userId == null) return 0;

    try {
      // Get all chat rooms user is a member of
      final chatRoomsSnapshot = await _firestore
          .collection(_chatRoomsCollection)
          .where('members', arrayContains: userId)
          .get();

      int totalUnreadCount = 0;

      for (final chatRoom in chatRoomsSnapshot.docs) {
        final messagesSnapshot = await _firestore
            .collection(_chatRoomsCollection)
            .doc(chatRoom.id)
            .collection('messages')
            .where('senderId', isNotEqualTo: userId)
            .where('isViewed', isEqualTo: false)
            .get();
        
        totalUnreadCount += messagesSnapshot.docs.length;
      }

      return totalUnreadCount;
    } catch (e) {
      Logger.d('Error getting unread messages count: $e');
      return 0;
    }
  }

  Future<int> _getUnreadNotificationsCount() async {
    final userId = currentUserId;
    if (userId == null) return 0;

    try {
      final snapshot = await _firestore
          .collection(_notificationsCollection)
          .where('user_id', isEqualTo: userId)
          .where('is_read', isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      Logger.d('Error getting unread notifications count: $e');
      return 0;
    }
  }

  /// Create friend request notification
  Future<void> createFriendRequestNotification({
    required String receiverId,
    required String senderName,
    required String senderId,
  }) async {
    await createNotification(
      userId: receiverId,
      type: NotificationType.friendRequest,
      title: 'New Friend Request',
      message: '$senderName wants to be your friend',
      data: {
        'sender_id': senderId,
        'sender_name': senderName,
        'action_type': 'friend_request',
      },
    );
  }

  /// Create message notification
  Future<void> createMessageNotification({
    required String receiverId,
    required String senderName,
    required String senderId,
    required String chatRoomId,
    required String messagePreview,
  }) async {
    await createNotification(
      userId: receiverId,
      type: NotificationType.unreadMessage,
      title: 'New Message',
      message: '$senderName: $messagePreview',
      data: {
        'sender_id': senderId,
        'sender_name': senderName,
        'chat_room_id': chatRoomId,
        'action_type': 'open_chat',
      },
    );
  }

  /// Create group invitation notification
  Future<void> createGroupInvitationNotification({
    required String receiverId,
    required String groupName,
    required String groupId,
    required String inviterName,
  }) async {
    await createNotification(
      userId: receiverId,
      type: NotificationType.groupInvitation,
      title: 'Group Invitation',
      message: '$inviterName invited you to join $groupName',
      data: {
        'group_id': groupId,
        'group_name': groupName,
        'inviter_name': inviterName,
        'action_type': 'group_invitation',
      },
    );
  }
} 