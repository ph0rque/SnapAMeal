import 'package:snapameal/pages/ar_camera_page.dart';
import 'package:snapameal/pages/friends_page.dart';
import 'package:snapameal/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:snapameal/services/snap_service.dart';
import 'package:snapameal/pages/view_snap_page.dart';
import 'package:snapameal/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:snapameal/pages/story_view_page.dart';
import 'package:snapameal/services/friend_service.dart';
import 'package:snapameal/services/story_service.dart';
import 'package:snapameal/pages/chats_page.dart';
import 'package:snapameal/design_system/snap_ui.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';

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
            icon: const Icon(EvaIcons.personAddOutline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FriendsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(EvaIcons.logOutOutline),
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
            icon: Icon(EvaIcons.homeOutline),
            activeIcon: Icon(EvaIcons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(EvaIcons.cameraOutline),
            activeIcon: Icon(EvaIcons.camera),
            label: 'Camera',
          ),
          BottomNavigationBarItem(
            icon: Icon(EvaIcons.messageSquareOutline),
            activeIcon: Icon(EvaIcons.messageSquare),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(EvaIcons.peopleOutline),
            activeIcon: Icon(EvaIcons.people),
            label: 'Friends',
          ),
           BottomNavigationBarItem(
            icon: Icon(EvaIcons.compassOutline),
            activeIcon: Icon(EvaIcons.compass),
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
                _navigateToStoryView(userId);
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
                                ? Border.all(color: SnapUIColors.accentPurple, width: 3)
                                : null,
                          ),
                          child: CircleAvatar(
                            radius: 28,
                            backgroundColor: isMyStory ? SnapUIColors.accentBlue : SnapUIColors.greyLight,
                            child: isMyStory
                                ? const Icon(EvaIcons.plus,
                                    size: 35, color: SnapUIColors.white)
                                : const Icon(EvaIcons.personOutline,
                                    size: 35, color: SnapUIColors.greyDark),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isMyStory ? 'My Story' : username,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }),
          );
        });
  }

  void _navigateToStoryView(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryViewPage(userId: userId),
      ),
    );
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

        final docs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return FutureBuilder<DocumentSnapshot>(
              future: _snapService.getSenderData(doc.id),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const ListTile(
                    title: Text("..."),
                    leading: Icon(Icons.person),
                  );
                }
                final senderData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final snapData = doc.data() as Map<String, dynamic>;
                final isViewed = snapData['isViewed'] ?? false;
                return ListTile(
                  leading: Icon(
                    isViewed ? EvaIcons.doneAllOutline : EvaIcons.emailOutline,
                    color:
                        isViewed ? SnapUIColors.grey : SnapUIColors.accentRed,
                  ),
                  title: Text(
                    isViewed
                        ? "Snap from ${senderData['username']}"
                        : "New Snap from ${senderData['username']}",
                  ),
                  subtitle: Text(isViewed ? 'Tap to replay' : 'Tap to view'),
                  onTap: () {
                    _viewSnap(doc.id, snapData);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _viewSnap(String snapId, Map<String, dynamic> snapData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewSnapPage(
          snapId: snapId,
          snapData: snapData,
        ),
      ),
    );
  }
} 