import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:snapameal/services/story_service.dart';
import 'package:snapameal/services/friend_service.dart';
import 'package:video_player/video_player.dart';

class StoryViewPage extends StatefulWidget {
  final String userId;
  const StoryViewPage({super.key, required this.userId});

  @override
  State<StoryViewPage> createState() => _StoryViewPageState();
}

class _StoryViewPageState extends State<StoryViewPage> with SingleTickerProviderStateMixin {
  final StoryService _storyService = StoryService();
  final FriendService _friendService = FriendService();
  late PageController _pageController;
  late AnimationController _animationController;
  List<DocumentSnapshot> _stories = [];
  int _currentIndex = 0;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(vsync: this);

    _loadStories();
  }

  void _loadStories() async {
    final storiesSnapshot = await _storyService.getStoriesForUserStream(widget.userId).first;

    if (!mounted) return;

    if (storiesSnapshot.docs.isNotEmpty) {
      final now = Timestamp.now();
      final validStories = storiesSnapshot.docs.where((story) {
        final data = story.data() as Map<String, dynamic>?;
        if (data == null || data['timestamp'] == null) return false;
        final timestamp = data['timestamp'] as Timestamp;
        return now.toDate().difference(timestamp.toDate()).inHours < 24;
      }).toList();

      if (!mounted) return;

      setState(() {
        _stories = validStories;
        if (_stories.isNotEmpty) {
          _startStory();
        } else {
          // No valid stories, pop back
          if (mounted) Navigator.of(context).pop();
        }
      });
    } else {
      // No stories at all, pop back
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _startStory() {
    if (_stories.isEmpty || _currentIndex >= _stories.length) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final currentStoryData = _stories[_currentIndex].data() as Map<String, dynamic>?;

    if (currentStoryData == null) {
      // If story data is somehow null, pop
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final type = currentStoryData['type'];
    final duration = (currentStoryData['duration'] ?? 5) * 1000;

    _animationController.stop();
    _animationController.reset();

    if (type == 'video') {
      _videoController?.dispose();
      _videoController = VideoPlayerController.networkUrl(Uri.parse(currentStoryData['mediaUrl']))
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play();
          _animationController.duration = _videoController!.value.duration;
          _animationController.forward();
        });
    } else {
      _animationController.duration = Duration(milliseconds: duration);
      _animationController.forward();
    }

    _animationController.addStatusListener(_onAnimationStatusChange);
  }
  
  void _onAnimationStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _nextStory();
    }
  }

  void _nextStory() {
    if (_currentIndex < _stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      // Finished all stories
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.removeStatusListener(_onAnimationStatusChange);
    _animationController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_stories.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentStory = _stories[_currentIndex].data() as Map<String, dynamic>?;

    if (currentStory == null) {
      // Pop immediately if the story data is null
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const Scaffold(
        body: Center(child: Text("Story data is unavailable.", style: TextStyle(color: Colors.white))),
      );
    }



    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width / 3) {
            _previousStory();
          } else {
            _nextStory();
          }
        },
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _stories.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _startStory();
              },
              itemBuilder: (context, index) {
                if (index >= _stories.length) return const SizedBox.shrink();
                final story = _stories[index].data() as Map<String, dynamic>?;
                
                if (story == null) return const SizedBox.shrink();

                final timestamp = story['timestamp'] as Timestamp?;
                if (timestamp == null) return const SizedBox.shrink();

                return FutureBuilder<DocumentSnapshot>(
                  future: _friendService.getUserData(story['senderId']),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return const Center(child: Text("Error loading user data"));
                    } else {
                      final userData = snapshot.data?.data() as Map<String, dynamic>?;
                      if (userData == null) {
                        return const Center(child: Text("User data is unavailable"));
                      }

                      if (story['isVideo']) {
                        return (_videoController?.value.isInitialized ?? false)
                            ? Center(
                                child: AspectRatio(
                                  aspectRatio: _videoController!.value.aspectRatio,
                                  child: VideoPlayer(_videoController!),
                                ),
                              )
                            : const Center(child: CircularProgressIndicator());
                      } else {
                        return CachedNetworkImage(
                          imageUrl: story['mediaUrl'],
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        );
                      }
                    }
                  },
                );
              },
            ),
            Positioned(
              top: 40,
              left: 10,
              right: 10,
              child: Row(
                children: _stories.asMap().entries.map((entry) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return LinearProgressIndicator(
                            value: entry.key == _currentIndex ? _animationController.value : (entry.key < _currentIndex ? 1.0 : 0.0),
                            backgroundColor: Colors.grey.withValues(alpha: 0.5),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          );
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 