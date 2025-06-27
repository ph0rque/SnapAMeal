import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapameal/design_system/snap_ui.dart';
import 'package:snapameal/services/story_service.dart';
import 'package:snapameal/services/friend_service.dart';
import 'package:video_player/video_player.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import '../utils/logger.dart';

class StoryViewPage extends StatefulWidget {
  final String userId;
  const StoryViewPage({super.key, required this.userId});

  @override
  State<StoryViewPage> createState() => _StoryViewPageState();
}

class _StoryViewPageState extends State<StoryViewPage>
    with TickerProviderStateMixin {
  final StoryService _storyService = StoryService();
  final FriendService _friendService = FriendService();
  late PageController _pageController;
  late AnimationController _progressController;
  late AnimationController _loadingController;
  List<DocumentSnapshot> _stories = [];
  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController = AnimationController(vsync: this);
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _loadStories();
  }

  void _loadStories() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final storiesSnapshot = await _storyService
          .getStoriesForUserStream(widget.userId)
          .first;

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

        if (validStories.isNotEmpty) {
          setState(() {
            _stories = validStories;
            _isLoading = false;
          });
          _startStory();
        } else {
          // No valid stories
          _handleError("No recent stories available");
        }
      } else {
        // No stories at all
        _handleError("No stories found");
      }
    } catch (e) {
      Logger.d('StoryViewPage: Error loading stories: $e');
      _handleError("Failed to load stories");
    }
  }

  void _handleError(String message) {
    setState(() {
      _isLoading = false;
      _hasError = true;
      _errorMessage = message;
    });

    // Auto-close after showing error
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _startStory() async {
    if (_stories.isEmpty || _currentIndex >= _stories.length) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final currentStoryData =
        _stories[_currentIndex].data() as Map<String, dynamic>?;

    if (currentStoryData == null) {
      _handleError("Story data unavailable");
      return;
    }

    // Stop current progress and reset
    _progressController.stop();
    _progressController.reset();

    final type =
        currentStoryData['type'] ??
        (currentStoryData['isVideo'] == true ? 'video' : 'image');
    final duration = currentStoryData['duration'] ?? 5;

    try {
      if (type == 'video') {
        await _initializeVideo(currentStoryData);
      } else {
        // For images, use the specified duration
        _progressController.duration = Duration(seconds: duration);
        _progressController.forward();
      }
    } catch (e) {
      Logger.d('StoryViewPage: Error starting story: $e');
      _nextStory(); // Skip to next story on error
    }

    _progressController.addStatusListener(_onProgressComplete);
  }

  Future<void> _initializeVideo(Map<String, dynamic> storyData) async {
    try {
      _videoController?.dispose();

      final videoUrl = storyData['mediaUrl'] as String;
      Logger.d('StoryViewPage: Initializing video: $videoUrl');

      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      await _videoController!.initialize();

      if (!mounted) return;

      setState(() {});

      // Set progress duration to video duration
      final videoDuration = _videoController!.value.duration;
      _progressController.duration = videoDuration;

      // Start video playback
      await _videoController!.play();
      _progressController.forward();

      Logger.d('StoryViewPage: Video initialized and playing');
    } catch (e) {
      Logger.d('StoryViewPage: Error initializing video: $e');
      // Fallback to default duration if video fails
      _progressController.duration = const Duration(seconds: 5);
      _progressController.forward();
    }
  }

  void _onProgressComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_isPaused) {
      _nextStory();
    }
  }

  void _nextStory() {
    _progressController.removeStatusListener(_onProgressComplete);

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
    _progressController.removeStatusListener(_onProgressComplete);

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

  void _pauseStory() {
    setState(() {
      _isPaused = true;
    });
    _progressController.stop();
    _videoController?.pause();
    HapticFeedback.lightImpact();
  }

  void _resumeStory() {
    setState(() {
      _isPaused = false;
    });
    _progressController.forward();
    _videoController?.play();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.removeStatusListener(_onProgressComplete);
    _progressController.dispose();
    _loadingController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_hasError) {
      return _buildErrorScreen();
    }

    if (_stories.isEmpty) {
      return _buildNoStoriesScreen();
    }

    return _buildStoryView();
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: SnapUIColors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _loadingController,
              child: const Icon(
                EvaIcons.refreshOutline,
                color: SnapUIColors.white,
                size: 48,
              ),
              builder: (context, child) {
                return Transform.rotate(
                  angle: _loadingController.value * 2.0 * 3.14159,
                  child: child,
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading stories...',
              style: TextStyle(color: SnapUIColors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: SnapUIColors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              EvaIcons.alertTriangleOutline,
              color: SnapUIColors.accentRed,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: SnapUIColors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Closing automatically...',
              style: TextStyle(color: SnapUIColors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoStoriesScreen() {
    return Scaffold(
      backgroundColor: SnapUIColors.black,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(EvaIcons.imageOutline, color: SnapUIColors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              'No stories available',
              style: TextStyle(color: SnapUIColors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryView() {
    return GestureDetector(
      onTapUp: (details) {
        final width = MediaQuery.of(context).size.width;
        if (details.globalPosition.dx < width / 3) {
          _previousStory();
        } else if (details.globalPosition.dx > width * 2 / 3) {
          _nextStory();
        } else {
          // Middle tap - pause/resume
          if (_isPaused) {
            _resumeStory();
          } else {
            _pauseStory();
          }
        }
      },
      onLongPressStart: (_) => _pauseStory(),
      onLongPressEnd: (_) => _resumeStory(),
      child: Scaffold(
        backgroundColor: SnapUIColors.black,
        body: Stack(
          children: [
            // Main story content
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
              itemBuilder: (context, index) => _buildStoryContent(index),
            ),

            // Progress indicators
            _buildProgressIndicators(),

            // User info header
            _buildUserHeader(),

            // Pause indicator
            if (_isPaused) _buildPauseIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryContent(int index) {
    if (index >= _stories.length) return const SizedBox.shrink();

    final story = _stories[index].data() as Map<String, dynamic>?;
    if (story == null) return const SizedBox.shrink();

    final type =
        story['type'] ?? (story['isVideo'] == true ? 'video' : 'image');
    final mediaUrl = story['mediaUrl'] as String?;

    if (mediaUrl == null) {
      return const Center(
        child: Icon(
          EvaIcons.alertTriangleOutline,
          color: SnapUIColors.white,
          size: 48,
        ),
      );
    }

    if (type == 'video') {
      return _buildVideoContent();
    } else {
      return _buildImageContent(mediaUrl);
    }
  }

  Widget _buildVideoContent() {
    if (_videoController?.value.isInitialized ?? false) {
      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(color: SnapUIColors.white),
      );
    }
  }

  Widget _buildImageContent(String imageUrl) {
    return Center(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(color: SnapUIColors.white),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(
            EvaIcons.alertTriangleOutline,
            color: SnapUIColors.white,
            size: 48,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicators() {
    return Positioned(
      top: 50,
      left: 10,
      right: 10,
      child: Row(
        children: _stories.asMap().entries.map((entry) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  double value;
                  if (entry.key == _currentIndex) {
                    value = _progressController.value;
                  } else if (entry.key < _currentIndex) {
                    value = 1.0;
                  } else {
                    value = 0.0;
                  }

                  return LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                    minHeight: 3,
                  );
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUserHeader() {
    if (_stories.isEmpty || _currentIndex >= _stories.length)
      return const SizedBox.shrink();

    final story = _stories[_currentIndex].data() as Map<String, dynamic>?;
    if (story == null) return const SizedBox.shrink();

    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: Column(
        children: [
          FutureBuilder<DocumentSnapshot>(
            future: _friendService.getUserData(
              story['senderId'] ?? widget.userId,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();

              final userData = snapshot.data!.data() as Map<String, dynamic>?;
              final username = userData?['username'] ?? 'Unknown User';

              return Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: SnapUIColors.greyLight,
                    child: const Icon(
                      EvaIcons.personOutline,
                      color: SnapUIColors.greyDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              username,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildPermanenceBadge(story),
                          ],
                        ),
                        Text(
                          _getTimeAgo(story['timestamp'] as Timestamp?),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildEngagementActions(story),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          _buildEngagementStats(story),
        ],
      ),
    );
  }

  Widget _buildPermanenceBadge(Map<String, dynamic> story) {
    final permanence = story['permanence'] as Map<String, dynamic>?;
    final tier = permanence?['tier'] as String?;

    if (tier == null || tier == 'standard') return const SizedBox.shrink();

    Color badgeColor;
    IconData badgeIcon;

    switch (tier) {
      case 'weekly':
        badgeColor = Colors.amber;
        badgeIcon = Icons.star;
        break;
      case 'monthly':
        badgeColor = Colors.purple;
        badgeIcon = Icons.auto_awesome;
        break;
      case 'milestone':
        badgeColor = Colors.orange;
        badgeIcon = Icons.emoji_events;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 12, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            tier.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementActions(Map<String, dynamic> story) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _handleEngagement('likes'),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _handleEngagement('shares'),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildEngagementStats(Map<String, dynamic> story) {
    final engagement = story['engagement'] as Map<String, dynamic>? ?? {};
    final permanence = story['permanence'] as Map<String, dynamic>?;

    final views = engagement['views'] as int? ?? 0;
    final likes = engagement['likes'] as int? ?? 0;
    final comments = engagement['comments'] as int? ?? 0;
    final shares = engagement['shares'] as int? ?? 0;

    // Show permanence info if story is extended
    final isExtended = permanence?['isExtended'] as bool? ?? false;
    final expiresAt = permanence?['expiresAt'] as Timestamp?;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildEngagementStat(Icons.visibility, views),
          const SizedBox(width: 12),
          _buildEngagementStat(Icons.favorite, likes),
          const SizedBox(width: 12),
          _buildEngagementStat(Icons.comment, comments),
          const SizedBox(width: 12),
          _buildEngagementStat(Icons.share, shares),
          if (isExtended && expiresAt != null) ...[
            const SizedBox(width: 12),
            const Icon(Icons.access_time, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              _getTimeUntilExpiry(expiresAt),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEngagementStat(IconData icon, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _handleEngagement(String engagementType) async {
    if (_stories.isEmpty || _currentIndex >= _stories.length) return;

    final storyId = _stories[_currentIndex].id;
    final storyOwnerId = widget.userId;

    try {
      await _storyService.updateStoryEngagement(
        storyOwnerId,
        storyId,
        engagementType,
      );

      // Provide haptic feedback
      HapticFeedback.lightImpact();

      // Show visual feedback
      _showEngagementFeedback(engagementType);
    } catch (e) {
      Logger.d('Error updating engagement: $e');
    }
  }

  void _showEngagementFeedback(String engagementType) {
    IconData icon;
    Color color;

    switch (engagementType) {
      case 'likes':
        icon = Icons.favorite;
        color = Colors.red;
        break;
      case 'shares':
        icon = Icons.share;
        color = Colors.blue;
        break;
      default:
        return;
    }

    // Show animated feedback
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Icon(icon, color: color, size: 64),
            );
          },
          onEnd: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  String _getTimeUntilExpiry(Timestamp expiresAt) {
    final now = DateTime.now();
    final expiry = expiresAt.toDate();
    final difference = expiry.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h left';
    } else {
      return '${difference.inMinutes}m left';
    }
  }

  Widget _buildPauseIndicator() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: const Center(
          child: Icon(Icons.pause, color: Colors.white, size: 64),
        ),
      ),
    );
  }

  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final storyTime = timestamp.toDate();
    final difference = now.difference(storyTime);

    if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}
