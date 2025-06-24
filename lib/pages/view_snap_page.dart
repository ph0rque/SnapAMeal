import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:screenshot_callback/screenshot_callback.dart';
import 'package:snapameal/services/snap_service.dart';
import 'package:video_player/video_player.dart';

class ViewSnapPage extends StatefulWidget {
  final DocumentSnapshot snap;
  final bool isReplay;

  const ViewSnapPage({super.key, required this.snap, this.isReplay = false});

  @override
  State<ViewSnapPage> createState() => _ViewSnapPageState();
}

class _ViewSnapPageState extends State<ViewSnapPage> {
  late Timer _timer;
  final SnapService _snapService = SnapService();
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  final ScreenshotCallback _screenshotCallback = ScreenshotCallback();

  @override
  void initState() {
    super.initState();
    final data = widget.snap.data() as Map<String, dynamic>;
    final duration = data['duration'] as int;
    _isVideo = data['isVideo'] ?? false;

    if (_isVideo) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(data['imageUrl']))
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play();
        });
    }

    _timer = Timer(Duration(seconds: duration), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
    _markSnapAsViewed();

    _screenshotCallback.addListener(() {
      _snapService.notifySenderOfScreenshot(widget.snap);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The sender has been notified of your screenshot.')),
      );
    });
  }

  Future<void> _markSnapAsViewed() async {
    if (widget.isReplay) {
      await widget.snap.reference.update({'replayed': true});
    } else {
      await widget.snap.reference.update({'isViewed': true});
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _videoController?.dispose();
    _screenshotCallback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.snap.data() as Map<String, dynamic>;
    final imageUrl = data['imageUrl'] as String;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _isVideo
            ? (_videoController?.value.isInitialized ?? false)
                ? AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  )
                : const CircularProgressIndicator()
            : Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
      ),
    );
  }
} 