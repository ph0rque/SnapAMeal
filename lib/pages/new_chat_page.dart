import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:snapameal/design_system/snap_ui.dart';
import 'package:snapameal/pages/chat_page.dart';
import 'package:snapameal/services/chat_service.dart';
import 'package:snapameal/services/friend_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key});

  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  final FriendService _friendService = FriendService();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<String> _selectedFriendIds = [];

  void _onStartChat() async {
    if (_selectedFriendIds.isEmpty) {
      return;
    }

    String chatRoomId;

    if (_selectedFriendIds.length == 1) {
      // One-on-one chat
      final otherUserId = _selectedFriendIds.first;
      final currentUser = _auth.currentUser!;

      List<String> ids = [currentUser.uid, otherUserId];
      ids.sort();
      String potentialChatRoomId = ids.join('_');

      // Check if current user is a demo user
      final userEmail = _auth.currentUser?.email;
      final isDemoUser = userEmail != null && (
        userEmail == 'alice.demo@example.com' ||
        userEmail == 'bob.demo@example.com' ||
        userEmail == 'charlie.demo@example.com'
      );
      
      final collectionName = isDemoUser ? 'demo_chat_rooms' : 'chat_rooms';

      // Check if a chat room already exists
      final chatRoomDoc = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(potentialChatRoomId)
          .get();

      if (chatRoomDoc.exists) {
        chatRoomId = potentialChatRoomId;
      } else {
        // Create a new one-on-one chat room (as a "group" of 2)
        chatRoomId = await _chatService.createGroupChat([otherUserId]);
      }

      final friendData = await _friendService.getUserData(otherUserId);
      (friendData.data() as Map<String, dynamic>)['username'] ?? 'Friend';
    } else {
      // Group chat
      chatRoomId = await _chatService.createGroupChat(_selectedFriendIds);
    }

    if (!mounted) return;
    Navigator.pop(context); // Pop this page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatPage(chatRoomId: chatRoomId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Chat")),
      body: StreamBuilder<List<String>>(
        stream: _friendService.getFriendsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading friends.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('You have no friends to chat with.'),
            );
          }

          final friendIds = snapshot.data!;

          return ListView.builder(
            itemCount: friendIds.length,
            itemBuilder: (context, index) {
              final friendId = friendIds[index];
              final isSelected = _selectedFriendIds.contains(friendId);

              return FutureBuilder<DocumentSnapshot>(
                future: _friendService.getUserData(friendId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text("Loading..."));
                  }
                  final friendData =
                      userSnapshot.data!.data() as Map<String, dynamic>;

                  return CheckboxListTile(
                    secondary: SnapAvatar(
                      imageUrl: friendData['profileImageUrl'],
                      name: friendData['username'],
                    ),
                    title: Text(friendData['username'] ?? 'No username'),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedFriendIds.add(friendId);
                        } else {
                          _selectedFriendIds.remove(friendId);
                        }
                      });
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: _selectedFriendIds.isNotEmpty
          ? FloatingActionButton(
              onPressed: _onStartChat,
              child: const Icon(EvaIcons.arrowForwardOutline),
            )
          : null,
    );
  }
}
