import 'package:snapameal/pages/ar_camera_page.dart';
import 'package:snapameal/pages/simple_camera_page.dart';
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
import 'package:cached_network_image/cached_network_image.dart';

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
      _showCameraOptions();
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showCameraOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Camera Mode',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('AR Camera'),
              subtitle: const Text('Face filters and effects'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ARCameraPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Simple Camera'),
              subtitle: const Text('Basic photo and video capture'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SimpleCameraPage()),
                );
              },
            ),
          ],
        ),
      ),
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
            final snapData = doc.data() as Map<String, dynamic>;
            final senderId = snapData['senderId'] as String;
            final isVideo = snapData['isVideo'] ?? false;
            
            return FutureBuilder<DocumentSnapshot>(
              future: _friendService.getUserData(senderId),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const ListTile(
                    title: Text("..."),
                    leading: Icon(Icons.person),
                  );
                }
                
                final senderData = userSnapshot.data!.data() as Map<String, dynamic>;
                final isViewed = snapData['isViewed'] ?? false;
                final username = senderData['username'] ?? 'Unknown';
                
                return _buildSnapListItem(
                  doc: doc,
                  snapData: snapData,
                  username: username,
                  isViewed: isViewed,
                  isVideo: isVideo,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSnapListItem({
    required DocumentSnapshot doc,
    required Map<String, dynamic> snapData,
    required String username,
    required bool isViewed,
    required bool isVideo,
  }) {
    // Get media URL (prioritize mediaUrl over imageUrl for backward compatibility)
    final mediaUrl = snapData['mediaUrl'] ?? snapData['imageUrl'] as String?;
    final thumbnailUrl = snapData['thumbnailUrl'] as String?;
    
    // Use thumbnail for videos, media URL for photos
    final displayUrl = isVideo && thumbnailUrl != null ? thumbnailUrl : mediaUrl;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isViewed ? SnapUIColors.greyLight : SnapUIColors.white,
        boxShadow: [
          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: _buildSnapThumbnail(
          displayUrl: displayUrl,
          isVideo: isVideo,
          isViewed: isViewed,
        ),
        title: Text(
          isViewed ? "Snap from $username" : "New Snap from $username",
          style: TextStyle(
            fontWeight: isViewed ? FontWeight.normal : FontWeight.bold,
            color: isViewed ? SnapUIColors.greyDark : SnapUIColors.black,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              isVideo ? EvaIcons.videoOutline : EvaIcons.cameraOutline,
              size: 16,
              color: SnapUIColors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              isViewed ? 'Tap to replay' : 'Tap to view',
              style: TextStyle(
                color: SnapUIColors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
        trailing: Icon(
          isViewed ? EvaIcons.doneAllOutline : EvaIcons.emailOutline,
          color: isViewed ? SnapUIColors.grey : SnapUIColors.accentRed,
          size: 20,
        ),
        onTap: () => _viewSnap(doc, snapData),
      ),
    );
  }

  Widget _buildSnapThumbnail({
    required String? displayUrl,
    required bool isVideo,
    required bool isViewed,
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: SnapUIColors.greyLight,
      ),
      child: Stack(
        children: [
          // Thumbnail image
          if (displayUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: displayUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 60,
                  height: 60,
                  color: SnapUIColors.greyLight,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: SnapUIColors.grey,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 60,
                  height: 60,
                  color: SnapUIColors.greyLight,
                  child: const Icon(
                    EvaIcons.imageOutline,
                    color: SnapUIColors.grey,
                    size: 24,
                  ),
                ),
              ),
            )
          else
            // Fallback when no URL available
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: SnapUIColors.greyLight,
              ),
              child: Icon(
                isVideo ? EvaIcons.videoOutline : EvaIcons.imageOutline,
                color: SnapUIColors.grey,
                size: 24,
              ),
            ),
          
          // Video play indicator overlay
          if (isVideo)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          
          // Viewed indicator
          if (isViewed)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: SnapUIColors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _viewSnap(DocumentSnapshot snap, Map<String, dynamic> snapData) {
    final isViewed = snapData['isViewed'] ?? false;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewSnapPage(
          snap: snap,
          isReplay: isViewed,
        ),
      ),
    );
  }
} 