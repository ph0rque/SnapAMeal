import 'package:flutter/material.dart';
import 'package:snapameal/services/friend_service.dart';

class UserSearchWidget extends StatefulWidget {
  const UserSearchWidget({super.key});

  @override
  State<UserSearchWidget> createState() => _UserSearchWidgetState();
}

class _UserSearchWidgetState extends State<UserSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FriendService _friendService = FriendService();
  Stream<List<Map<String, dynamic>>>? _usersStream;
  final Set<String> _sentRequests = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _usersStream = _friendService.searchUsers(_searchController.text);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _sendFriendRequest(String receiverId) async {
    await _friendService.sendFriendRequest(receiverId);
    setState(() {
      _sentRequests.add(receiverId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Find Friends", style: TextStyle(fontWeight: FontWeight.bold)),
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Search for friends by username...',
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder(
            stream: _usersStream,
            builder: (context, snapshot) {
              if (_searchController.text.isEmpty) {
                return const Center(child: Text('Enter a username to find friends.'));
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading users.'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
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
          ),
        ),
      ],
    );
  }
} 