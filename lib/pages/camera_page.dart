import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:snapameal/pages/preview_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  int _selectedCameraIndex = 0;
  bool _isRecording = false;
  bool _noCamerasAvailable = false;

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
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.flash_off, color: Colors.white),
                          onPressed: () {
                            // TODO: Implement flash control
                          },
                        ),
                        GestureDetector(
                          onTap: _takePicture,
                          onLongPressStart: (_) => _startVideoRecording(),
                          onLongPressEnd: (_) => _stopVideoRecording(),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isRecording ? Colors.red : Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cameraswitch, color: Colors.white),
                          onPressed: _switchCamera,
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
    print("Saving file to permanent path: $newPath");
    await file.saveTo(newPath);
    return XFile(newPath);
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      if (!mounted) return;

      final savedImage = await _saveFilePermanently(image);

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PreviewPage(picture: savedImage, isVideo: false),
        ),
      );
    } catch (e) {
      print(e);
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
      print(e);
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

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PreviewPage(picture: savedFile, isVideo: true),
        ),
      );
    } catch (e) {
      print(e);
      return;
    }
  }
} 