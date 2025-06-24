import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:snapameal/components/user_search.dart';
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
            const Text("My Friends", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildFriendsList(),
            const SizedBox(height: 20),
            const Text("Friend Requests", style: TextStyle(fontWeight: FontWeight.bold)),
            _buildFriendRequestList(),
            const SizedBox(height: 20),
            const Expanded(
              child: UserSearchWidget(),
            ),
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
          shrinkWrap: true,
          itemCount: friendIds.length,
          itemBuilder: (context, index) {
            final friendId = friendIds[index];
            return FutureBuilder<DocumentSnapshot>(
              future: _friendService.getUserData(friendId),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const ListTile(title: Text("..."));
                }
                final friendData = userSnapshot.data!.data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(friendData['username']),
                  leading: const Icon(Icons.person),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          receiverUsername: friendData['username'],
                          receiverId: friendId,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
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
          shrinkWrap: true,
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

                final userData = userSnapshot.data!.data() as Map<String, dynamic>;

                return ListTile(
                  title: Text(userData['username']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                          await _friendService.acceptFriendRequest(senderId);
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
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
} 