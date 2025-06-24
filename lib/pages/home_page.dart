import 'package:snapameal/pages/friends_page.dart';
import 'package:snapameal/pages/chat_page.dart';
import 'package:snapameal/pages/camera_page.dart';
import 'package:snapameal/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:snapameal/main.dart';
import 'package:snapameal/services/snap_service.dart';
import 'package:snapameal/pages/view_snap_page.dart';
import 'package:snapameal/services/notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final SnapService _snapService = SnapService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
  }

  void logout() {
    _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey,
        elevation: 0,
        actions: [
          // Friends button
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FriendsPage()),
              );
            },
            icon: const Icon(Icons.people),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CameraPage(cameras: cameras)),
              );
            },
            icon: const Icon(Icons.camera_alt),
          ),
          // Logout button
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _buildSnapsList(),
    );
  }

  Widget _buildSnapsList() {
    return StreamBuilder(
      stream: _snapService.getSnapsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading snaps"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No new snaps!"));
        }

        return ListView(
          children: snapshot.data!.docs
              .map((doc) => _buildSnapListItem(doc))
              .toList(),
        );
      },
    );
  }

  Widget _buildSnapListItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isViewed = data['isViewed'] ?? false;

    return FutureBuilder<DocumentSnapshot>(
      future: _authService.getUserData(data['senderId']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            leading: const Icon(Icons.photo_camera_back),
            title: const Text("Loading..."),
            onTap: () {},
          );
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return ListTile(
            leading: const Icon(Icons.photo_camera_back),
            title: const Text("New Snap from an unknown user"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewSnapPage(snap: doc),
                ),
              );
            },
          );
        }
        final senderData = snapshot.data!.data() as Map<String, dynamic>;
        return ListTile(
          leading: Icon(
            isViewed ? Icons.replay : Icons.photo_camera_back,
            color: isViewed ? Colors.grey : Colors.red,
          ),
          title: Text(
            isViewed
                ? "Replay snap from ${senderData['username']}"
                : "New Snap from ${senderData['username']}",
          ),
          onTap: () async {
            if (isViewed) {
              // Handle replay logic
              bool canReplay = await _authService.canUserReplay();
              if (canReplay) {
                await _authService.useReplayCredit();
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewSnapPage(snap: doc, isReplay: true),
                  ),
                );
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("You can only replay one snap per day.")),
                );
              }
            } else {
              // Handle first view
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewSnapPage(snap: doc, isReplay: false),
                ),
              );
            }
          },
        );
      },
    );
  }
} 