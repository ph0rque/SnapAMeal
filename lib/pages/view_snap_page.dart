import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:screenshot_callback/screenshot_callback.dart'; // Temporarily disabled
// import 'package:snapameal/services/snap_service.dart'; // Temporarily disabled with screenshot detection
import 'package:video_player/video_player.dart';

class ViewSnapPage extends StatefulWidget {
  final DocumentSnapshot snap;
  final bool isReplay;

  const ViewSnapPage({super.key, required this.snap, this.isReplay = false});

  @override
  State<ViewSnapPage> createState() => _ViewSnapPageState();
}

class _ViewSnapPageState extends State<ViewSnapPage> with TickerProviderStateMixin {
  late Timer _timer;
  // final SnapService _snapService = SnapService(); // Temporarily disabled with screenshot detection
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  bool _isPlaying = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isLoading = true;
  // ScreenshotCallback? _screenshotCallback; // Temporarily disabled
  
  // Animation controllers for UI feedback
  late AnimationController _playPauseAnimationController;
  late AnimationController _progressAnimationController;
  late Animation<double> _playPauseAnimation;
  late Animation<double> _progressAnimation;
  
  // Progress tracking
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _showPlayPauseIcon = false;
  Timer? _hideIconTimer;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _playPauseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _playPauseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _playPauseAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeOut,
    ));

    _initializeSnap();
  }

  Future<void> _initializeSnap() async {
    try {
      final data = widget.snap.data() as Map<String, dynamic>;
      final duration = data['duration'] as int;
      _isVideo = data['isVideo'] ?? false;

      if (_isVideo) {
        await _initializeVideo(data);
      } else {
        _isLoading = false;
        setState(() {});
      }

      // Start the snap viewing timer
      _timer = Timer(Duration(seconds: duration), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
      
      _markSnapAsViewed();
      _setupScreenshotDetection();
      
    } catch (e) {
      _handleError('Failed to initialize snap: $e');
    }
  }

  Future<void> _initializeVideo(Map<String, dynamic> data) async {
    try {
      // Use mediaUrl if available, fallback to imageUrl for backward compatibility
      final videoUrl = data['mediaUrl'] ?? data['imageUrl'] as String;
      
      debugPrint('ViewSnapPage: Initializing video from URL: $videoUrl');
      
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      
      await _videoController!.initialize();
      
      if (!mounted) return;
      
      _totalDuration = _videoController!.value.duration;
      _isLoading = false;
      
      // Set up video player listeners
      _videoController!.addListener(_videoListener);
      
      // Start autoplay
      await _startAutoplay();
      
      setState(() {});
      
    } catch (e) {
      _handleError('Failed to load video: $e');
    }
  }

  Future<void> _startAutoplay() async {
    if (_videoController != null && _videoController!.value.isInitialized) {
      await _videoController!.play();
      _isPlaying = true;
      _playPauseAnimationController.forward();
      
      // Start progress animation
      _progressAnimationController.forward();
      
      setState(() {});
      debugPrint('ViewSnapPage: Video autoplay started');
    }
  }

  void _videoListener() {
    if (!mounted || _videoController == null) return;
    
    final value = _videoController!.value;
    
    // Update position tracking
    _currentPosition = value.position;
    
    // Handle video completion
    if (value.position >= value.duration && value.duration.inMilliseconds > 0) {
      _onVideoCompleted();
    }
    
    // Handle errors
    if (value.hasError) {
      _handleError('Video playback error: ${value.errorDescription}');
    }
    
    // Update playing state
    if (_isPlaying != value.isPlaying) {
      _isPlaying = value.isPlaying;
      if (_isPlaying) {
        _playPauseAnimationController.forward();
      } else {
        _playPauseAnimationController.reverse();
      }
    }
    
    setState(() {});
  }

  void _onVideoCompleted() {
    debugPrint('ViewSnapPage: Video playback completed');
    _isPlaying = false;
    _playPauseAnimationController.reverse();
    
    // Reset video to beginning for potential replay
    _videoController?.seekTo(Duration.zero);
    setState(() {});
  }

  void _handleError(String error) {
    debugPrint('ViewSnapPage: Error - $error');
    _hasError = true;
    _errorMessage = error;
    _isLoading = false;
    setState(() {});
  }

  Future<void> _togglePlayPause() async {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    
    try {
      if (_isPlaying) {
        await _videoController!.pause();
        _progressAnimationController.stop();
      } else {
        await _videoController!.play();
        _progressAnimationController.forward();
      }
      
      // Show play/pause feedback
      _showPlayPauseFeedback();
      
      // Haptic feedback
      HapticFeedback.lightImpact();
      
    } catch (e) {
      _handleError('Failed to toggle play/pause: $e');
    }
  }

  void _showPlayPauseFeedback() {
    _showPlayPauseIcon = true;
    setState(() {});
    
    _hideIconTimer?.cancel();
    _hideIconTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        _showPlayPauseIcon = false;
        setState(() {});
      }
    });
  }

  Future<void> _markSnapAsViewed() async {
    try {
      if (widget.isReplay) {
        await widget.snap.reference.update({'replayed': true});
      } else {
        await widget.snap.reference.update({'isViewed': true});
      }
    } catch (e) {
      debugPrint('ViewSnapPage: Error marking snap as viewed: $e');
    }
  }

  void _setupScreenshotDetection() {
    // TODO: Re-implement screenshot detection when package is fixed
    // For now, this functionality is disabled to resolve Android build issues
    debugPrint('ViewSnapPage: Screenshot detection temporarily disabled');
  }

  @override
  void dispose() {
    _timer.cancel();
    _hideIconTimer?.cancel();
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    // _screenshotCallback?.dispose(); // Temporarily disabled
    _playPauseAnimationController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.snap.data() as Map<String, dynamic>;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _isVideo ? _togglePlayPause : null,
        child: Stack(
          children: [
            // Main content
            Center(
              child: _buildMainContent(data),
            ),
            
            // Video controls overlay
            if (_isVideo && !_hasError) ...[
              _buildProgressIndicator(),
              _buildPlayPauseOverlay(),
            ],
            
            // Error overlay
            if (_hasError) _buildErrorOverlay(),
            
            // Loading overlay
            if (_isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(Map<String, dynamic> data) {
    if (_isVideo) {
      if (_hasError) {
        return _buildErrorContent();
      }
      
      if (_videoController?.value.isInitialized ?? false) {
        return AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        );
      }
      
      return const SizedBox.shrink();
    } else {
      // Photo content
      final imageUrl = data['mediaUrl'] ?? data['imageUrl'] as String;
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.white,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorContent();
        },
      );
    }
  }

  Widget _buildProgressIndicator() {
    if (_totalDuration.inMilliseconds == 0) return const SizedBox.shrink();
    
    final progress = _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
    
    return Positioned(
      top: 60,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return Container(
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1.5),
                              color: Colors.white.withValues(alpha: 0.3),
            ),
            child: FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1.5),
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayPauseOverlay() {
    if (!_showPlayPauseIcon) return const SizedBox.shrink();
    
    return Positioned.fill(
      child: Center(
        child: AnimatedBuilder(
          animation: _playPauseAnimation,
          builder: (context, child) {
            return Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Positioned.fill(
      child: Container(
                      color: Colors.black.withValues(alpha: 0.8),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to load content',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.white,
              ),
              SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorContent() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.broken_image,
          color: Colors.white54,
          size: 64,
        ),
        SizedBox(height: 16),
        Text(
          'Content unavailable',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
} 