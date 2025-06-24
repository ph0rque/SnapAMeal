import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:snapameal/design_system/snap_ui.dart';
import 'package:snapameal/services/friend_service.dart';

class SnapUserSearch extends StatefulWidget {
  const SnapUserSearch({super.key});

  @override
  State<SnapUserSearch> createState() => _SnapUserSearchState();
}

class _SnapUserSearchState extends State<SnapUserSearch> {
  final TextEditingController _searchController = TextEditingController();
  final FriendService _friendService = FriendService();
  Stream<List<Map<String, dynamic>>>? _usersStream;
  final Set<String> _sentRequests = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        if (_searchController.text.isNotEmpty) {
          _usersStream = _friendService.searchUsers(_searchController.text);
        } else {
          _usersStream = null;
        }
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
        Padding(
          padding: const EdgeInsets.all(SnapUIDimensions.spacingS),
          child: SnapTextField(
            controller: _searchController,
            hintText: 'Search for friends...',
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: SnapUIDimensions.spacingS),
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
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var user = users[index];
                    final isRequestSent = _sentRequests.contains(user['uid']);
                    return ListTile(
                      leading: SnapAvatar(
                        name: user['username'],
                        imageUrl: user['profileImageUrl'],
                      ),
                      title: Text(user['username']),
                      subtitle: Text(user['email']),
                      trailing: IconButton(
                        icon: isRequestSent
                            ? const Icon(EvaIcons.checkmark, color: SnapUIColors.accentGreen)
                            : const Icon(EvaIcons.personAddOutline),
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
        ),
      ],
    );
  }
} 