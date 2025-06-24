import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:snapameal/design_system/snap_ui.dart';
import 'package:snapameal/pages/chat_page.dart';
import 'package:snapameal/services/friend_service.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final FriendService _friendService = FriendService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Search for Friends", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            SnapUserSearch(),
            const SizedBox(height: 20),
            Text("My Friends", style: Theme.of(context).textTheme.titleLarge),
            Expanded(child: _buildFriendsList()),
            const SizedBox(height: 20),
            Text("Friend Requests", style: Theme.of(context).textTheme.titleLarge),
            Expanded(child: _buildFriendRequestList()),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList() {
    return StreamBuilder<List<String>>(
      stream: _friendService.getFriendsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('You have no friends yet.');
        }

        final friendIds = snapshot.data!;
        return ListView.builder(
          physics: const ClampingScrollPhysics(),
          itemCount: friendIds.length,
          itemBuilder: (context, index) {
            final friendId = friendIds[index];
            return FutureBuilder<DocumentSnapshot>(
              future: _friendService.getUserData(friendId),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const ListTile(title: Text("..."));
                }
                final friendData = userSnapshot.data!.data() as Map<String, dynamic>?;
                if (friendData == null) {
                  return const ListTile(title: Text("Friend data missing"));
                }
                return ListTile(
                  title: Text(friendData['username'] ?? 'No name'),
                  leading: SnapAvatar(
                    name: friendData['username'],
                    imageUrl: friendData['profileImageUrl'],
                  ),
                  onTap: () {
                    _navigateToChat(friendId);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _navigateToChat(String friendId) async {
    final chatRoomId =
        await _friendService.getOrCreateOneOnOneChatRoom(friendId);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          chatRoomId: chatRoomId,
          recipientId: friendId,
        ),
      ),
    );
  }

  Widget _buildFriendRequestList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _friendService.getFriendRequests(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Text('No pending friend requests.');
        }

        return ListView(
          physics: const ClampingScrollPhysics(),
          children: snapshot.data!.docs.map((doc) {
            final request = doc.data() as Map<String, dynamic>;
            final senderId = request['senderId'];

            return FutureBuilder<DocumentSnapshot>(
              future: _friendService.getUserData(senderId),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(title: Text("Loading..."));
                }
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const ListTile(title: Text("Unknown user"));
                }

                final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                if (userData == null) {
                  return const ListTile(title: Text("User data missing"));
                }

                return ListTile(
                  title: Text(userData['username'] ?? 'No name'),
                  leading: SnapAvatar(
                    name: userData['username'],
                    imageUrl: userData['profileImageUrl'],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(EvaIcons.checkmark, color: SnapUIColors.accentGreen),
                        onPressed: () async {
                          await _friendService.acceptFriendRequest(senderId);
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(EvaIcons.close, color: SnapUIColors.accentRed),
                        onPressed: () async {
                          await _friendService.declineFriendRequest(senderId);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _handleSendFriendRequest(String email) async {
    try {
      await _friendService.sendFriendRequest(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Friend request sent!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send friend request: $e")),
        );
      }
    }
  }
} 