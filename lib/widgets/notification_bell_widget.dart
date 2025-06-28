import 'dart:async';
import 'package:flutter/material.dart';
import '../design_system/snap_ui.dart';
import '../services/in_app_notification_service.dart';
import '../services/friend_service.dart';
import '../pages/chat_page.dart';
import '../pages/health_groups_page.dart';
import '../utils/logger.dart';

class NotificationBellWidget extends StatefulWidget {
  const NotificationBellWidget({super.key});

  @override
  State<NotificationBellWidget> createState() => _NotificationBellWidgetState();
}

class _NotificationBellWidgetState extends State<NotificationBellWidget> {
  final InAppNotificationService _notificationService = InAppNotificationService();
  final FriendService _friendService = FriendService();
  int _unreadCount = 0;
  List<InAppNotification> _notifications = [];
  bool _isClearing = false;
  StreamSubscription<int>? _unreadCountSubscription;
  StreamSubscription<List<InAppNotification>>? _notificationsSubscription;

  @override
  void initState() {
    super.initState();
    _setupUnreadCountListener();
    _setupNotificationsListener();
  }

  @override
  void dispose() {
    _unreadCountSubscription?.cancel();
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  void _setupUnreadCountListener() {
    _unreadCountSubscription = _notificationService.getCombinedUnreadCountStream().listen(
      (count) {
        if (mounted) {
          setState(() {
            _unreadCount = count;
          });
        }
      },
      onError: (error) {
        Logger.d('Error in unread count stream: $error');
      },
    );
  }

  void _setupNotificationsListener() {
    _notificationsSubscription = _notificationService.getNotificationsStream().listen(
      (notifications) {
        if (mounted) {
          setState(() {
            _notifications = notifications;
          });
        }
      },
      onError: (error) {
        Logger.d('Error in notifications stream: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
            return PopupMenuButton<InAppNotification>(
          icon: Stack(
            children: [
              const Icon(Icons.notifications_outlined),
              if (_unreadCount > 0 || _isClearing)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: SnapColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: _isClearing
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
            ],
          ),
      offset: const Offset(0, 50),
      itemBuilder: (context) {
        if (!mounted) return [];
        return _buildNotificationItems(context);
      },
      onSelected: (notification) {
        if (mounted) {
          _handleNotificationTap(context, notification);
        }
      },
    );
  }

  List<PopupMenuEntry<InAppNotification>> _buildNotificationItems(BuildContext context) {
    return [
      // Header
      PopupMenuItem<InAppNotification>(
        enabled: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Notifications',
              style: SnapTypography.heading3.copyWith(
                color: SnapColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: _isClearing ? null : () async {
                setState(() {
                  _isClearing = true;
                });
                Navigator.pop(context);
                await _notificationService.clearAllNotifications();
                if (mounted) {
                  setState(() {
                    _isClearing = false;
                  });
                }
              },
              child: Text(
                'Clear all',
                style: SnapTypography.caption.copyWith(
                  color: _isClearing ? SnapColors.textSecondary : SnapColors.primaryYellow,
                ),
              ),
            ),
          ],
        ),
      ),
      const PopupMenuDivider(),
      
      // Notifications list
      ...(_buildNotificationsList()),
      
      // No notifications message if empty
      if (_buildNotificationsList().isEmpty && _unreadCount == 0)
        PopupMenuItem<InAppNotification>(
          enabled: false,
          child: Column(
            children: [
              const SizedBox(height: 20),
              Icon(
                Icons.notifications_none,
                size: 48,
                color: SnapColors.textSecondary,
              ),
              const SizedBox(height: 8),
              Text(
                'No notifications',
                style: SnapTypography.body.copyWith(
                  color: SnapColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
    ];
  }

    List<PopupMenuItem<InAppNotification>> _buildNotificationsList() {
    try {
      // Show real notifications from the database
      if (_notifications.isEmpty) {
        return [
          PopupMenuItem<InAppNotification>(
            enabled: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'No notifications',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ];
      }
      
      return _notifications.map((notification) => 
        _buildNotificationItem(notification)
      ).toList();
    } catch (e) {
      Logger.d('Error building notifications list: $e');
      return [];
    }
  }

  PopupMenuItem<InAppNotification> _buildNotificationItem(InAppNotification notification) {
    return PopupMenuItem<InAppNotification>(
      value: notification,
      child: _buildNotificationTile(notification),
    );
  }

  Widget _buildNotificationTile(InAppNotification notification) {
    IconData icon;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.friendRequest:
        icon = Icons.person_add;
        iconColor = SnapColors.primaryYellow;
        break;
      case NotificationType.unreadMessage:
        icon = Icons.message;
        iconColor = SnapColors.accentGreen;
        break;
      case NotificationType.groupInvitation:
        icon = Icons.group_add;
        iconColor = SnapColors.accentPurple;
        break;
      case NotificationType.groupMessage:
        icon = Icons.group;
        iconColor = SnapColors.accentBlue;
        break;
      case NotificationType.aiAdvice:
        icon = Icons.psychology;
        iconColor = SnapColors.accentPurple;
        break;
    }

    final timeAgo = _formatTimeAgo(notification.timestamp);

    return Container(
      width: 300, // Fixed width for consistency
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: SnapTypography.body.copyWith(
                    color: SnapColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  notification.message,
                  style: SnapTypography.caption.copyWith(
                    color: SnapColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  timeAgo,
                  style: SnapTypography.caption.copyWith(
                    color: SnapColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: SnapColors.primaryYellow,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${difference.inDays ~/ 7}w ago';
    }
  }

  void _handleNotificationTap(BuildContext context, InAppNotification notification) {
    try {
      // Mark notification as read
      _notificationService.markAsRead(notification.id);

      // Handle different notification types
      switch (notification.type) {
        case NotificationType.friendRequest:
          _handleFriendRequestTap(context, notification);
          break;
        case NotificationType.unreadMessage:
          _handleMessageTap(context, notification);
          break;
        case NotificationType.groupInvitation:
          _handleGroupInvitationTap(context, notification);
          break;
        case NotificationType.groupMessage:
          _handleGroupMessageTap(context, notification);
          break;
        case NotificationType.aiAdvice:
          _handleAIAdviceTap(context, notification);
          break;
      }
    } catch (e) {
      Logger.d('Error handling notification tap: $e');
    }
  }

  void _handleFriendRequestTap(BuildContext context, InAppNotification notification) {
    // Show friend request dialog or navigate to friends page
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SnapColors.backgroundLight,
        title: Text(
          'Friend Request',
          style: SnapTypography.heading3.copyWith(
            color: SnapColors.textPrimary,
          ),
        ),
        content: Text(
          notification.message,
          style: SnapTypography.body.copyWith(
            color: SnapColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Decline friend request
              final senderId = notification.data['sender_id'] as String;
              _friendService.declineFriendRequest(senderId);
            },
            child: Text(
              'Decline',
              style: SnapTypography.body.copyWith(
                color: SnapColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Accept friend request
              final senderId = notification.data['sender_id'] as String;
              _friendService.acceptFriendRequest(senderId);
            },
            child: Text(
              'Accept',
              style: SnapTypography.body.copyWith(
                color: SnapColors.primaryYellow,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMessageTap(BuildContext context, InAppNotification notification) {
    // Navigate to chat page
    final chatRoomId = notification.data['chat_room_id'] as String;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatRoomId: chatRoomId,
          recipientId: notification.data['sender_id'] as String,
        ),
      ),
    );
  }

  void _handleGroupInvitationTap(BuildContext context, InAppNotification notification) {
    // Navigate to health groups page or show group invitation dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HealthGroupsPage(),
      ),
    );
  }

  void _handleGroupMessageTap(BuildContext context, InAppNotification notification) {
    // Navigate to group chat
    final chatRoomId = notification.data['chat_room_id'] as String;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatRoomId: chatRoomId,
          recipientId: null, // null for group chats
        ),
      ),
    );
  }

  void _handleAIAdviceTap(BuildContext context, InAppNotification notification) {
    // Handle AI advice notification - could navigate to AI advice page
    Logger.d('AI advice notification tapped: ${notification.message}');
  }
} 