import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:snapameal/design_system/snap_ui.dart';
import 'package:snapameal/services/auth_service.dart';
import 'package:snapameal/services/chat_service.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';

class ChatPage extends StatefulWidget {
  final String chatRoomId;
  final String? recipientId; // Can be null for group chats

  const ChatPage({super.key, required this.chatRoomId, this.recipientId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
        widget.chatRoomId,
        _messageController.text,
      );
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.recipientId != null
            ? StreamBuilder<DocumentSnapshot>(
                stream: _authService.getUserStream(widget.recipientId!),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final user = snapshot.data!.data() as Map<String, dynamic>;
                    return Row(
                      children: [
                        SnapAvatar(
                          imageUrl: user['profileImageUrl'],
                          name: user['username'],
                          radius: 18,
                        ),
                        const SizedBox(width: SnapUIDimensions.spacingS),
                        Text(user['username'] ?? 'Chat'),
                      ],
                    );
                  }
                  return const Text('Chat');
                },
              )
            : const Text('Group Chat'),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildUserInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatService.getMessages(widget.chatRoomId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text("Error");
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading...");
        }

        return ListView(
          children: snapshot.data!.docs
              .map((doc) => _buildMessageItem(doc))
              .toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isCurrentUser = data['senderId'] == _auth.currentUser!.uid;

    return Container(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isCurrentUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          SnapChatBubble(
            message: data["message"],
            isCurrentUser: isCurrentUser,
          ),
        ],
      ),
    );
  }

  Widget _buildUserInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: SnapTextField(
              controller: _messageController,
              hintText: "Send a message...",
              obscureText: false,
            ),
          ),
          IconButton(
            onPressed: sendMessage,
            icon: const Icon(EvaIcons.arrowUpwardOutline),
          ),
        ],
      ),
    );
  }
}
