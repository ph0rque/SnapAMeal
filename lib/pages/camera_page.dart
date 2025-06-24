import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:snapameal/pages/preview_page.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:snapameal/design_system/snap_ui.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key, required this.cameras, this.onStoryPosted});

  final List<CameraDescription> cameras;
  final VoidCallback? onStoryPosted;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  int _selectedCameraIndex = 0;
  bool _isRecording = false;
  bool _noCamerasAvailable = false;
  bool _flashOn = false;

  @override
  void initState() {
    super.initState();
    if (widget.cameras.isEmpty) {
      setState(() {
        _noCamerasAvailable = true;
      });
      return;
    }
    _initializeCamera();
  }

  void _initializeCamera() {
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.cameras[_selectedCameraIndex],
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  void _switchCamera() {
    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % widget.cameras.length;
      _initializeCamera();
    });
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_noCamerasAvailable) {
      return const Scaffold(
        body: Center(
          child: Text("No cameras available."),
        ),
      );
    }
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: Icon(
                      _flashOn ? EvaIcons.flash : EvaIcons.flashOff,
                      color: SnapUIColors.white,
                    ),
                    onPressed: _toggleFlash,
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: IconButton(
                    icon: const Icon(EvaIcons.flip2, color: SnapUIColors.white),
                    onPressed: _switchCamera,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: SnapUIColors.black.withAlpha(128),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: _takePicture,
                          onLongPressStart: (_) => _startVideoRecording(),
                          onLongPressEnd: (_) => _stopVideoRecording(),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isRecording ? SnapUIColors.accentRed : SnapUIColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Future<XFile> _saveFilePermanently(XFile file) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String newPath = p.join(appDir.path, p.basename(file.path));
            debugPrint("Saving file to permanent path: $newPath");
    await file.saveTo(newPath);
    return XFile(newPath);
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      if (!mounted) return;

            final savedImage = await _saveFilePermanently(image);
      
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PreviewPage(
            picture: savedImage, 
            isVideo: false,
            onStoryPosted: widget.onStoryPosted,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
  }

  Future<void> _startVideoRecording() async {
    if (!_controller.value.isInitialized) {
      return;
    }
    setState(() {
      _isRecording = true;
    });
    try {
      await _controller.startVideoRecording();
    } catch (e) {
      debugPrint("Error starting video recording: $e");
      return;
    }
  }

  Future<void> _stopVideoRecording() async {
    if (!_controller.value.isRecordingVideo) {
      return;
    }

    try {
      final file = await _controller.stopVideoRecording();
      setState(() {
        _isRecording = false;
      });
      if (!mounted) return;

      final savedFile = await _saveFilePermanently(file);

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PreviewPage(
            picture: savedFile, 
            isVideo: true,
            onStoryPosted: widget.onStoryPosted,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error stopping video recording: $e");
      return;
    }
  }

  void _toggleFlash() {
    if (_controller.value.flashMode == FlashMode.off ||
        _controller.value.flashMode == FlashMode.auto) {
      _controller.setFlashMode(FlashMode.torch).then((_) {
        if (mounted) {
          setState(() {
            _flashOn = true;
          });
        }
      });
    } else {
      _controller.setFlashMode(FlashMode.off).then((_) {
        if (mounted) {
          setState(() {
            _flashOn = false;
          });
        }
      });
    }
  }
} 