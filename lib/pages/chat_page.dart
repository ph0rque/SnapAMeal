import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:snapameal/components/chat_bubble.dart';
import 'package:snapameal/services/chat_service.dart';

class ChatPage extends StatefulWidget {
  final String receiverUsername;
  final String receiverId;

  const ChatPage({
    super.key,
    required this.receiverUsername,
    required this.receiverId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _chatService.markMessagesAsViewed(widget.receiverId);
  }

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(widget.receiverId, _messageController.text);
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverUsername),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      body: Column(
        children: [
          // display all messages
          Expanded(
            child: _buildMessageList(),
          ),

          // message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getMessages(widget.receiverId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          children:
              snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // is current user
    bool isCurrentUser = data['senderId'] == _auth.currentUser!.uid;

    // align message to the right if sender is current user, otherwise left
    var alignment =
        isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
      alignment: alignment,
      child: ChatBubble(
        message: data['message'],
        isCurrentUser: isCurrentUser,
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Enter a message...',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
} 