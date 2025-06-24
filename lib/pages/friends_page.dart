import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:snapameal/services/friend_service.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  // text controller
  final TextEditingController _searchController = TextEditingController();
  final FriendService _friendService = FriendService();

  Stream<List<Map<String, dynamic>>>? _usersStream;
  final Set<String> _sentRequests = {};

  void _onSearchChanged(String query) {
    setState(() {
      _usersStream = _friendService.searchUsers(query);
    });
  }

  void _sendFriendRequest(String receiverId) async {
    await _friendService.sendFriendRequest(receiverId);
    setState(() {
      _sentRequests.add(receiverId);
    });
  }

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
            const Text("Find Friends", style: TextStyle(fontWeight: FontWeight.bold)),
            // search bar
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search for friends by username...',
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 20),
            
            // list of users
            Expanded(
              child: _buildUserSearchList(),
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
                        onPressed: () {
                          _friendService.acceptFriendRequest(senderId);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          _friendService.declineFriendRequest(senderId);
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

  Widget _buildUserSearchList() {
    return StreamBuilder(
      stream: _usersStream,
      builder: (context, snapshot) {
        // error
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading users.'));
        }

        // loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // no data
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No users found.'));
        }

        var users = snapshot.data!;

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            var user = users[index];
            final isRequestSent = _sentRequests.contains(user['uid']);

            return ListTile(
              title: Text(user['username']),
              subtitle: Text(user['email']),
              trailing: IconButton(
                icon: isRequestSent
                    ? const Icon(Icons.check)
                    : const Icon(Icons.person_add),
                onPressed: isRequestSent
                    ? null
                    : () => _sendFriendRequest(user['uid']),
              ),
            );
          },
        );
      },
    );
  }
} 