import 'package:snapameal/pages/ar_camera_page.dart';
import 'package:snapameal/pages/friends_page.dart';
import 'package:snapameal/pages/chat_page.dart';
import 'package:snapameal/pages/camera_page.dart';
import 'package:snapameal/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:snapameal/main.dart';
import 'package:snapameal/services/snap_service.dart';
import 'package:snapameal/pages/view_snap_page.dart';
import 'package:snapameal/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:snapameal/pages/story_view_page.dart';
import 'package:snapameal/services/friend_service.dart';
import 'package:snapameal/services/story_service.dart';
import 'package:snapameal/pages/chats_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final SnapService _snapService = SnapService();
  final NotificationService _notificationService = NotificationService();
  final FriendService _friendService = FriendService();
  final StoryService _storyService = StoryService();

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == 1) { // Middle button for camera
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ARCameraPage()),
      );
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openCameraForSnap() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ARCameraPage()),
    );
  }

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
        title: const Text("SnapAMeal"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FriendsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Camera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Friends',
          ),
           BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Discover',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildMainContent();
      case 2:
        return const ChatsPage();
      case 3:
        return const FriendsPage(); // Your friends page/widget
      case 4:
         return const Center(child: Text("Discover Page")); // Placeholder
      default:
        return _buildMainContent();
    }
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildStoryReel(),
        Expanded(child: _buildSnapList()),
      ],
    );
  }

  Widget _buildStoryReel() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: StreamBuilder<List<String>>(
        stream: _friendService.getFriendsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final friendIds = snapshot.data!;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: friendIds.length + 1, // +1 for My Story
            itemBuilder: (context, index) {
              if (index == 0) {
                // My Story circle
                return _buildStoryCircle(
                  userId: FirebaseAuth.instance.currentUser!.uid,
                  isMyStory: true,
                );
              }
              // Friend story circles
              final friendId = friendIds[index - 1];
              return _buildStoryCircle(userId: friendId);
            },
          );
        },
      ),
    );
  }

  Widget _buildStoryCircle({required String userId, bool isMyStory = false}) {
    return StreamBuilder<QuerySnapshot>(
        stream: _storyService.getStoriesForUserStream(userId),
        builder: (context, storySnapshot) {
          final hasStories =
              storySnapshot.hasData && storySnapshot.data!.docs.isNotEmpty;

          return GestureDetector(
            onTap: () {
              if (isMyStory) {
                _openStoryCamera();
              } else if (hasStories) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => StoryViewPage(userId: userId)));
              }
            },
            child: FutureBuilder<DocumentSnapshot>(
                future: _friendService.getUserData(userId),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: CircleAvatar(radius: 35),
                    );
                  }

                  final username =
                      (userSnapshot.data!.data() as Map<String, dynamic>)['username'] ?? 'User';

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: hasStories
                                ? Border.all(color: Colors.pinkAccent, width: 3)
                                : null,
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: isMyStory ? Colors.blueAccent : Colors.grey[300],
                            child: isMyStory
                                ? const Icon(Icons.add,
                                    size: 35, color: Colors.white)
                                : const Icon(Icons.person,
                                    size: 35, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isMyStory ? 'My Story' : username,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  );
                }),
          );
        });
  }

  void _openStoryCamera() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ARCameraPage()),
    );
  }

  Widget _buildSnapList() {
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