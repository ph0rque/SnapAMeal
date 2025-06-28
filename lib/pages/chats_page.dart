import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:snapameal/design_system/snap_ui.dart';
import 'package:snapameal/pages/chat_page.dart';
import 'package:snapameal/pages/new_chat_page.dart';
import 'package:snapameal/services/chat_service.dart';
import 'package:snapameal/services/friend_service.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final ChatService _chatService = ChatService();
  final FriendService _friendService = FriendService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    final difference = now.difference(messageTime);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // Format as date for older messages
      return '${messageTime.month}/${messageTime.day}/${messageTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SnapUI.appBar(title: 'Chats'),
      body: _buildChatList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewChatPage()),
          );
        },
        child: const Icon(EvaIcons.messageCircleOutline),
      ),
    );
  }

  Widget _buildChatList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getChatsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading chats.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No chats yet.'));
        }

        // Sort chats by last message timestamp (most recent first)
        final sortedDocs = snapshot.data!.docs.toList();
        sortedDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>?;
          final bData = b.data() as Map<String, dynamic>?;

          final aTimestamp = aData?['lastMessageTimestamp'] as Timestamp?;
          final bTimestamp = bData?['lastMessageTimestamp'] as Timestamp?;

          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;

          return bTimestamp.compareTo(aTimestamp); // Most recent first
        });

        return ListView(
          children: sortedDocs.map((doc) {
            return _buildChatListItem(doc);
          }).toList(),
        );
      },
    );
  }

  Widget _buildChatListItem(DocumentSnapshot chatDoc) {
    final chatData = chatDoc.data() as Map<String, dynamic>?;
    if (chatData == null) return const SizedBox.shrink();

    final members = List<String>.from(chatData['members']);
    final isGroup = chatData['isGroup'] as bool;
    final currentUserId = _auth.currentUser!.uid;

    String title = 'Group Chat';
    if (!isGroup) {
      final otherUserId = members.firstWhere((id) => id != currentUserId);
      return StreamBuilder<DocumentSnapshot>(
        stream: _friendService.getFriendDocStream(otherUserId),
        builder: (context, friendSnapshot) {
          if (!friendSnapshot.hasData) {
            return const ListTile(title: Text("Loading..."));
          }
          final streakData =
              friendSnapshot.data!.data() as Map<String, dynamic>?;
          final streakCount = streakData?['streakCount'] ?? 0;

          return FutureBuilder<DocumentSnapshot>(
            future: _friendService.getUserData(otherUserId),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) {
                return const ListTile(title: Text("Loading..."));
              }
              final friendData =
                  userSnapshot.data!.data() as Map<String, dynamic>?;
              if (friendData == null) return const SizedBox.shrink();

              title = friendData['username'] ?? 'User';
              final imageUrl = friendData['profileImageUrl'] as String?;

              final lastMessageTimestamp =
                  chatData['lastMessageTimestamp'] as Timestamp?;
              final timestampText = _formatTimestamp(lastMessageTimestamp);

              return ListTile(
                leading: SnapAvatar(imageUrl: imageUrl, name: title),
                title: Text(title),
                subtitle: timestampText.isNotEmpty
                    ? Text('Last message: $timestampText')
                    : null,
                trailing: streakCount > 0
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🔥 $streakCount'),
                          if (timestampText.isNotEmpty)
                            Text(
                              timestampText,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      )
                    : (timestampText.isNotEmpty
                          ? Text(
                              timestampText,
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          : null),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        chatRoomId: chatDoc.id,
                        recipientId: otherUserId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      );
    } else {
      // For group chats, show member count and timestamp
      final lastMessageTimestamp =
          chatData['lastMessageTimestamp'] as Timestamp?;
      final timestampText = _formatTimestamp(lastMessageTimestamp);

      return ListTile(
        leading: const SnapAvatar(name: "Group", isGroup: true),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${members.length} members'),
            if (timestampText.isNotEmpty) Text('Last message: $timestampText'),
          ],
        ),
        trailing: timestampText.isNotEmpty
            ? Text(timestampText, style: Theme.of(context).textTheme.bodySmall)
            : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(chatRoomId: chatDoc.id),
            ),
          );
        },
      );
    }
  }
}
