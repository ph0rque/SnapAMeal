import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:snapameal/pages/select_friends_page.dart';
import 'package:video_player/video_player.dart';

class PreviewPage extends StatefulWidget {
  const PreviewPage({super.key, required this.picture, this.isVideo = false});

  final XFile picture;
  final bool isVideo;

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
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
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Text(
                      '$_durationInSeconds',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => _showTimerSelectionDialog(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () {
                      // TODO: Implement editing features
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SelectFriendsPage(
                            picture: widget.picture,
                            duration: _durationInSeconds,
                            isVideo: widget.isVideo,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          )
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
} 