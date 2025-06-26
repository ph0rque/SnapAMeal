import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:snapameal/pages/select_friends_page.dart';
import 'package:snapameal/services/story_service.dart';
import 'package:video_player/video_player.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:snapameal/design_system/snap_ui.dart';
import '../models/fasting_session.dart';

class PreviewPage extends StatefulWidget {
  const PreviewPage({
    super.key,
    required this.picture,
    this.isVideo = false,
    this.onStoryPosted,
    this.fastingSession,
    this.isFastingProgressSnap = false,
    this.isFastingCompletionSnap = false,
  });

  final XFile picture;
  final bool isVideo;
  final VoidCallback? onStoryPosted;
  final FastingSession? fastingSession;
  final bool isFastingProgressSnap;
  final bool isFastingCompletionSnap;

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  final StoryService _storyService = StoryService();
  int _durationInSeconds = 3;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _videoController = VideoPlayerController.file(File(widget.picture.path))
        ..initialize().then((_) {
          setState(() {});
          _videoController!.setLooping(true);
          _videoController!.play();
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: widget.isVideo
                ? (_videoController?.value.isInitialized ?? false)
                    ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    : const Center(child: CircularProgressIndicator())
                : Image.file(
                    File(widget.picture.path),
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(EvaIcons.close, color: SnapUIColors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          // Fasting context overlay
          if (widget.fastingSession != null)
            Positioned(
              top: 80,
              left: 20,
              right: 20,
              child: _buildFastingContextOverlay(),
            ),
          
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: widget.onStoryPosted != null
                ? _buildStoryPostButton()
                : _buildSnapOptions(),
          )
        ],
      ),
    );
  }

  Widget _buildStoryPostButton() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Duration selector for stories
          if (!widget.isVideo) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(EvaIcons.clockOutline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Duration:',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _showTimerSelectionDialog(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_durationInSeconds s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          // Post button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: SnapUIColors.accentPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: () async {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );
                
                try {
                  final duration = widget.isVideo ? 5 : _durationInSeconds; // Video stories are always 5 seconds
                  await _storyService.postStory(widget.picture.path, widget.isVideo, duration: duration);
                  
                  if (!mounted) return;
                  Navigator.of(context).pop(); // Close loading dialog
                  
                  if (widget.onStoryPosted != null) {
                    widget.onStoryPosted!();
                  }
                  
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.isVideo ? "Video" : "Photo"} story posted successfully!'),
                      backgroundColor: SnapUIColors.accentPurple,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  Navigator.of(context).pop(); // Close loading dialog
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to post story. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(EvaIcons.plusCircleOutline),
                  const SizedBox(width: 8),
                  Text(
                    'Post to Your Story${widget.isVideo ? " (5s)" : ""}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapOptions() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Text(
              '$_durationInSeconds',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            onPressed: () => _showTimerSelectionDialog(context),
          ),
          IconButton(
            icon: const Icon(EvaIcons.edit2Outline, color: SnapUIColors.white),
            onPressed: () {
              // TODO: Implement editing features
            },
          ),
          IconButton(
            icon: const Icon(EvaIcons.paperPlaneOutline, color: SnapUIColors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SelectFriendsPage(
                    imagePath: widget.picture.path,
                    duration: _durationInSeconds,
                    isVideo: widget.isVideo,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showTimerSelectionDialog(BuildContext context) async {
    final selectedDuration = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Select View Duration'),
          children: List.generate(10, (index) {
            final duration = index + 1;
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, duration),
              child: Text('$duration seconds'),
            );
          }),
        );
      },
    );

    if (selectedDuration != null) {
      setState(() {
        _durationInSeconds = selectedDuration;
      });
    }
  }

  /// Build fasting context overlay
  Widget _buildFastingContextOverlay() {
    if (widget.fastingSession == null) return SizedBox.shrink();

    String title;
    String subtitle;
    Color backgroundColor;
    IconData icon;

    if (widget.isFastingCompletionSnap) {
      title = 'Fasting Completed! 🎉';
      subtitle = 'Celebrate your achievement!';
      backgroundColor = Colors.green;
      icon = Icons.celebration;
    } else if (widget.isFastingProgressSnap) {
      final progress = (widget.fastingSession!.progressPercentage * 100).toInt();
      title = 'Fasting Progress: $progress%';
      subtitle = 'Keep going strong! 💪';
      backgroundColor = Colors.blue;
      icon = Icons.trending_up;
    } else {
      title = 'Fasting Session Active';
      subtitle = widget.fastingSession!.typeDescription;
      backgroundColor = Colors.orange;
      icon = Icons.timer;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 