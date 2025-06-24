import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:snapameal/services/story_service.dart';
import 'package:video_player/video_player.dart';

class StoryViewPage extends StatefulWidget {
  final String userId;
  const StoryViewPage({super.key, required this.userId});

  @override
  State<StoryViewPage> createState() => _StoryViewPageState();
}

class _StoryViewPageState extends State<StoryViewPage> with SingleTickerProviderStateMixin {
  final StoryService _storyService = StoryService();
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

  Future<void> _loadStories() async {
    final storiesSnapshot = await _storyService.getStoriesForUserStream(widget.userId).first;
    setState(() {
      _stories = storiesSnapshot.docs;
    });
    if (_stories.isNotEmpty) {
      _playStory(_stories[_currentIndex]);
    }
  }

  void _playStory(DocumentSnapshot story) {
    _animationController.stop();
    _animationController.reset();

    final data = story.data() as Map<String, dynamic>;
    if (data['isVideo']) {
      _videoController?.dispose();
      _videoController = VideoPlayerController.networkUrl(Uri.parse(data['mediaUrl']))
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play();
          _animationController.duration = _videoController!.value.duration;
          _animationController.forward();
        });
    } else {
      _animationController.duration = const Duration(seconds: 5);
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
      Navigator.of(context).pop();
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

    final currentStory = _stories[_currentIndex].data() as Map<String, dynamic>;

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
                _playStory(_stories[index]);
              },
              itemBuilder: (context, index) {
                final story = _stories[index].data() as Map<String, dynamic>;
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
                            backgroundColor: Colors.grey.withOpacity(0.5),
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