import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:snapameal/pages/chat_page.dart';
import 'package:snapameal/pages/new_chat_page.dart';
import 'package:snapameal/services/chat_service.dart';
import 'package:snapameal/services/friend_service.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final ChatService _chatService = ChatService();
  final FriendService _friendService = FriendService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: _buildChatList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewChatPage()),
          );
        },
        child: const Icon(Icons.add),
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

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            return _buildChatListItem(doc);
          }).toList(),
        );
      },
    );
  }

  Widget _buildChatListItem(DocumentSnapshot chatDoc) {
    final chatData = chatDoc.data() as Map<String, dynamic>;
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

          final streakCount = (friendSnapshot.data!.data() as Map<String, dynamic>)['streakCount'] ?? 0;

          return FutureBuilder<DocumentSnapshot>(
            future: _friendService.getUserData(otherUserId),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) {
                return const ListTile(title: Text("Loading..."));
              }
              final friendData = userSnapshot.data!.data() as Map<String, dynamic>;
              title = friendData['username'] ?? 'User';
              return ListTile(
                title: Text(title),
                trailing: streakCount > 0 ? Text('🔥 $streakCount') : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChatPage(chatRoomId: chatDoc.id, chatTitle: title),
                    ),
                  );
                },
              );
            },
          );
        }
      );
    } else {
      // For group chats, you might want to show member count or other info
      return ListTile(
        title: Text(title),
        subtitle: Text('${members.length} members'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ChatPage(chatRoomId: chatDoc.id, chatTitle: title),
            ),
          );
        },
      );
    }
  }
} 