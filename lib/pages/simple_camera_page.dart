import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'preview_page.dart';
import '../utils/logger.dart';

class SimpleCameraPage extends StatefulWidget {
  const SimpleCameraPage({super.key});

  @override
  State<SimpleCameraPage> createState() => _SimpleCameraPageState();
}

class _SimpleCameraPageState extends State<SimpleCameraPage> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isVideoMode = false;
  int _selectedCameraIndex = 0;
  List<CameraDescription> _cameras = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      Logger.d('Simple Camera: Getting available cameras...');
      _cameras = await availableCameras();
      
      if (_cameras.isEmpty) {
        Logger.d('Simple Camera: No cameras available');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No cameras available on this device.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      Logger.d('Simple Camera: Found ${_cameras.length} cameras');
      await _setupCameraController();
    } catch (e) {
      Logger.d('Simple Camera: Error getting cameras: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera initialization failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _setupCameraController() async {
    try {
      final camera = _cameras[_selectedCameraIndex];
      Logger.d('Simple Camera: Setting up camera ${camera.name}');

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        Logger.d('Simple Camera: Camera initialized successfully');
      }
    } catch (e) {
      Logger.d('Simple Camera: Error setting up camera: $e');
      // Try with fallback settings
      try {
        _cameraController?.dispose();
        _cameraController = CameraController(
          _cameras[_selectedCameraIndex],
          ResolutionPreset.low,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        
        await _cameraController!.initialize();
        
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          Logger.d('Simple Camera: Camera initialized with fallback settings');
        }
      } catch (fallbackError) {
        Logger.d('Simple Camera: Fallback initialization failed: $fallbackError');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Camera setup failed: $fallbackError'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _takePicture() async {
    try {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        Logger.d('Simple Camera: Camera not ready for photo');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera not ready. Please try again.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      Logger.d('Simple Camera: Taking picture...');
      final XFile picture = await _cameraController!.takePicture();
      Logger.d('Simple Camera: Picture taken: ${picture.path}');

      if (!mounted) return;

      // Navigate to preview
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PreviewPage(
            picture: picture,
            isVideo: false,
          ),
        ),
      );
    } catch (e) {
      Logger.d('Simple Camera: Error taking picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startVideoRecording() async {
    try {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        Logger.d('Simple Camera: Camera not ready for video');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera not ready for video recording.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      Logger.d('Simple Camera: Starting video recording...');
      await _cameraController!.startVideoRecording();
      
      setState(() {
        _isRecording = true;
      });
      
      Logger.d('Simple Camera: Video recording started');
    } catch (e) {
      Logger.d('Simple Camera: Error starting video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start video recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopVideoRecording() async {
    try {
      if (_cameraController == null || !_cameraController!.value.isRecordingVideo) {
        setState(() {
          _isRecording = false;
        });
        return;
      }

      Logger.d('Simple Camera: Stopping video recording...');
      final XFile video = await _cameraController!.stopVideoRecording();
      Logger.d('Simple Camera: Video saved: ${video.path}');
      
      setState(() {
        _isRecording = false;
      });

      if (!mounted) return;

      // Navigate to preview
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PreviewPage(
            picture: video,
            isVideo: true,
          ),
        ),
      );
    } catch (e) {
      Logger.d('Simple Camera: Error stopping video: $e');
      setState(() {
        _isRecording = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop video recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _switchCamera() {
    if (_cameras.length > 1) {
      setState(() {
        _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
        _isInitialized = false;
      });
      _setupCameraController();
    }
  }



  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_isInitialized && _cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            const Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Initializing camera...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          // Top controls
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Close button
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                
                // Mode toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _isVideoMode = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: !_isVideoMode ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'PHOTO',
                            style: TextStyle(
                              color: !_isVideoMode ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _isVideoMode = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isVideoMode ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'VIDEO',
                            style: TextStyle(
                              color: _isVideoMode ? Colors.black : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Switch camera button
                if (_cameras.length > 1)
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
                    onPressed: _switchCamera,
                  )
                else
                  const SizedBox(width: 48), // Placeholder for alignment
              ],
            ),
          ),

          // Recording indicator
          if (_isRecording)
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.white, size: 8),
                      SizedBox(width: 6),
                      Text('RECORDING', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom controls
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _isVideoMode
                    ? (_isRecording ? _stopVideoRecording : _startVideoRecording)
                    : _takePicture,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording ? Colors.red : Colors.white,
                    border: _isVideoMode
                        ? Border.all(color: Colors.red, width: 4)
                        : null,
                  ),
                  child: _isVideoMode
                      ? Icon(
                          _isRecording ? Icons.stop : Icons.videocam,
                          color: _isRecording ? Colors.white : Colors.red,
                          size: 35,
                        )
                      : const Icon(Icons.camera_alt, color: Colors.black, size: 35),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 