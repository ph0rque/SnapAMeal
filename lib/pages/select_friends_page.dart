import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:snapameal/services/friend_service.dart';
import 'package:snapameal/services/snap_service.dart';

class SelectFriendsPage extends StatefulWidget {
  final XFile picture;
  final int duration;
  final bool isVideo;

  const SelectFriendsPage({
    super.key,
    required this.picture,
    required this.duration,
    this.isVideo = false,
  });

  @override
  State<SelectFriendsPage> createState() => _SelectFriendsPageState();
}

class _SelectFriendsPageState extends State<SelectFriendsPage> {
  final FriendService _friendService = FriendService();
  final SnapService _snapService = SnapService();
  final List<String> _selectedFriendIds = [];

  void _onSend() {
    if (_selectedFriendIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one friend.')),
      );
      return;
    }

    _snapService.sendSnap(
      widget.picture.path,
      widget.duration,
      _selectedFriendIds,
      widget.isVideo,
    );
    
    // Pop until we get back to the home page
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Friends'),
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _friendService.getFriendsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading friends.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('You have no friends yet.'));
          }

          final friends = snapshot.data!;

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              final friendData = friend.data() as Map<String, dynamic>;
              final friendId = friend.id;
              final isSelected = _selectedFriendIds.contains(friendId);

              return CheckboxListTile(
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onSend,
        child: const Icon(Icons.send),
      ),
    );
  }
} 