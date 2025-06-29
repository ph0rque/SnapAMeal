import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:snapameal/pages/preview_page.dart';
import '../utils/logger.dart';
import '../services/ar_filter_service.dart';

class ARCameraPage extends StatefulWidget {
  const ARCameraPage({super.key});

  @override
  State<ARCameraPage> createState() => _ARCameraPageState();
}

class _ARCameraPageState extends State<ARCameraPage> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isDetecting = false;
  List<Face> _faces = [];
  Size? _imageSize;
  final GlobalKey _globalKey = GlobalKey();
  InputImageRotation _rotation = InputImageRotation.rotation270deg;

  final ARFilterService _arFilterService = ARFilterService();
  List<ARFilterConfig> _availableFilters = [];
  int _selectedFilterIndex = 0;
  FitnessARFilterType? _selectedFilterType;

  // Video recording state
  bool _isVideoMode = false;
  bool _isRecording = false;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  static const Duration _maxRecordingDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _initialize();
    _initializeFilters();
  }

  void _initializeFilters() {
    _availableFilters = _arFilterService.getAvailableFilters();
    setState(() {});
  }

  Future<void> _initialize() async {
    // Start with camera initialization only, no face detection initially
    await _initializeCamera();
    setState(() {});
  }

  Future<void> _initializeFaceDetector() async {
    // Only initialize face detector after camera is working and in photo mode
    if (_cameraController != null &&
        _cameraController!.value.isInitialized &&
        !_isVideoMode &&
        _faceDetector == null) {
      try {
        _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            enableLandmarks: true,
            performanceMode: FaceDetectorMode.fast,
          ),
        );

        // Wait before starting image stream
        await Future.delayed(const Duration(milliseconds: 2000));

        if (mounted &&
            _cameraController != null &&
            _cameraController!.value.isInitialized &&
            !_isVideoMode &&
            _cameraController!.value.isStreamingImages == false) {
          try {
            await _cameraController!.startImageStream(_processImage);
          } catch (e) {
            Logger.d('Error starting image stream: $e');
            // Continue without face detection if it fails
          }
        }
      } catch (e) {
        Logger.d('Error initializing face detector: $e');
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      Logger.d('Initializing camera...');
      final cameras = await availableCameras();
      Logger.d('Found ${cameras.length} cameras');
      
      if (cameras.isEmpty) {
        Logger.d('No cameras available');
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

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      Logger.d('Using camera: ${frontCamera.name} (${frontCamera.lensDirection})');

      try {
        // Use conservative camera configuration for maximum compatibility
        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.low, // Use low resolution for better compatibility
          enableAudio: true, // Enable audio for video recording
          imageFormatGroup: ImageFormatGroup.jpeg, // Specify image format
        );

        await _cameraController!.initialize();

        if (mounted &&
            _cameraController != null &&
            _cameraController!.value.isInitialized) {
          setState(() {});

          // Initialize face detection after camera is stable
          await Future.delayed(const Duration(milliseconds: 1000));
          if (mounted) {
            await _initializeFaceDetector();
          }
        }
      } catch (e) {
        Logger.d('Error initializing camera: $e');
        
        // Try with fallback configuration if initial setup fails
        try {
          _cameraController?.dispose();
          _cameraController = CameraController(
            frontCamera,
            ResolutionPreset.low, // Use low resolution as fallback
            enableAudio: false, // Disable audio as fallback
            imageFormatGroup: ImageFormatGroup.jpeg,
          );
          await _cameraController!.initialize();
          
          if (mounted) {
            setState(() {});
            Logger.d('Camera initialized with fallback configuration');
          }
        } catch (fallbackError) {
          Logger.d('Fallback camera initialization also failed: $fallbackError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Camera failed to initialize. Please restart the app.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (outerError) {
      Logger.d('Critical error in camera initialization: $outerError');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera initialization failed: $outerError'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _processImage(CameraImage image) {
    if (!mounted ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }
    if (_isDetecting || _faceDetector == null) return;

    _isDetecting = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage != null && mounted && _faceDetector != null) {
        _faceDetector!
            .processImage(inputImage)
            .then((faces) {
              if (!mounted) {
                _isDetecting = false;
                return;
              }
              setState(() {
                _faces = faces;
                _imageSize = Size(
                  image.width.toDouble(),
                  image.height.toDouble(),
                );
                _rotation =
                    inputImage.metadata?.rotation ??
                    InputImageRotation.rotation270deg;
              });
              _isDetecting = false;
            })
            .catchError((e) {
              if (mounted) {
                Logger.d("Error processing image: $e");
              }
              _isDetecting = false;
            });
      } else {
        _isDetecting = false;
      }
    } catch (e) {
      Logger.d("Error in _processImage: $e");
      _isDetecting = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;

    // Handle rotation based on platform and camera orientation
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // For iOS front camera, use proper rotation
      if (camera.lensDirection == CameraLensDirection.front) {
        rotation = InputImageRotation.rotation270deg;
      } else {
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      }
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // For Android, handle rotation compensation
      var rotationCompensation = (sensorOrientation + 360) % 360;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (360 - rotationCompensation) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    return InputImage.fromBytes(
      bytes: image.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recordingTimer = null;

    // Stop image stream first
    _cameraController?.stopImageStream().catchError((e) {
      Logger.d('Error stopping image stream: $e');
    });

    // Dispose camera controller
    _cameraController?.dispose().catchError((e) {
      Logger.d('Error disposing camera controller: $e');
    });
    _cameraController = null;

    // Close face detector
    _faceDetector?.close().catchError((e) {
      Logger.d('Error closing face detector: $e');
    });
    _faceDetector = null;

    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        Logger.d("Camera not initialized");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera not ready. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      Logger.d("Taking picture...");

      if (_selectedFilterIndex == 0) {
        // No filter - take a direct camera picture for better quality
        final XFile picture = await _cameraController!.takePicture();
        Logger.d("Picture taken: ${picture.path}");

        if (!mounted) return;

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PreviewPage(picture: picture, isVideo: false),
          ),
        );
      } else {
        // Filter applied - capture the rendered view
        RenderRepaintBoundary boundary =
            _globalKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        ByteData? byteData = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        Uint8List pngBytes = byteData!.buffer.asUint8List();

        final String dir = (await getTemporaryDirectory()).path;
        final String filePath =
            '$dir/${DateTime.now().millisecondsSinceEpoch}.png';
        final File file = File(filePath);
        await file.writeAsBytes(pngBytes);

        Logger.d("Filtered picture saved: $filePath");

        if (!mounted) return;

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                PreviewPage(picture: XFile(file.path), isVideo: false),
          ),
        );
      }
    } catch (e) {
      Logger.d("Error taking picture: $e");
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

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: RepaintBoundary(
        key: _globalKey,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full screen camera preview without distortion
            Transform.scale(
              scale: 1.0,
              child: Center(child: CameraPreview(_cameraController!)),
            ),
            // Only show face filters when not recording video and a filter is selected
            if (!_isRecording &&
                _selectedFilterType != null &&
                _faces.isNotEmpty &&
                _imageSize != null)
              CustomPaint(
                size: Size.infinite,
                painter: FacePainter(
                  faces: _faces,
                  imageSize: _imageSize!,
                  screenSize: MediaQuery.of(context).size,
                  filterType: _selectedFilterType,
                  arFilterService: _arFilterService,
                  rotation: _rotation,
                ),
              ),
            // Show filter overlay when face is detected and filter is selected
            if (!_isRecording &&
                _selectedFilterType != null &&
                _faces.isNotEmpty)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: _arFilterService.generateFilterOverlay(
                      _selectedFilterType!,
                      size: Size(200, 150),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 40,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // Photo/Video Toggle Button
            Positioned(top: 40, right: 10, child: _buildModeToggle()),
            // Recording Duration Indicator
            if (_isRecording)
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: _buildRecordingIndicator(),
              ),
            // Red recording indicator dot
            if (_isRecording)
              Positioned(top: 50, left: 20, child: _buildRecordingDot()),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isVideoMode ? _toggleVideoRecording : _takePicture,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording ? Colors.red : Colors.white,
                        border: _isVideoMode
                            ? Border.all(color: Colors.red, width: 3)
                            : null,
                      ),
                      child: _isVideoMode
                          ? Icon(
                              _isRecording ? Icons.stop : Icons.videocam,
                              color: _isRecording ? Colors.white : Colors.red,
                              size: 30,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFilterSelector(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSelector() {
    return Container(
      height: 80,
      color: Colors.black.withValues(alpha: 0.7),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 10),
        itemCount: _availableFilters.length + 1, // +1 for "None" option
        itemBuilder: (context, index) {
          final isNoneFilter = index == 0;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilterIndex = index;
                _selectedFilterType = isNoneFilter 
                    ? null 
                    : _availableFilters[index - 1].type;
              });
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
              decoration: BoxDecoration(
                border: _selectedFilterIndex == index
                    ? Border.all(color: Colors.yellow, width: 3)
                    : Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                borderRadius: BorderRadius.circular(12),
                color: _selectedFilterIndex == index
                    ? Colors.yellow.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.3),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isNoneFilter)
                    Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    )
                  else
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _availableFilters[index - 1].primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getFilterIcon(_availableFilters[index - 1].type),
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  SizedBox(height: 4),
                  Text(
                    isNoneFilter 
                        ? 'None' 
                        : _getFilterShortName(_availableFilters[index - 1].type),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getFilterIcon(FitnessARFilterType type) {
    switch (type) {
      case FitnessARFilterType.fastingChampion:
        return Icons.emoji_events; // Trophy/Crown
      case FitnessARFilterType.calorieCrusher:
        return Icons.flash_on; // Lightning for energy
      case FitnessARFilterType.workoutGuide:
        return Icons.fitness_center; // Workout icon
      case FitnessARFilterType.progressParty:
        return Icons.celebration; // Party/Fireworks
      case FitnessARFilterType.groupStreakSparkler:
        return Icons.auto_awesome; // Sparkles
    }
  }

  String _getFilterShortName(FitnessARFilterType type) {
    switch (type) {
      case FitnessARFilterType.fastingChampion:
        return 'Fasting\nChamp';
      case FitnessARFilterType.calorieCrusher:
        return 'Calorie\nCrusher';
      case FitnessARFilterType.workoutGuide:
        return 'Workout\nGuide';
      case FitnessARFilterType.progressParty:
        return 'Progress\nParty';
      case FitnessARFilterType.groupStreakSparkler:
        return 'Group\nStreak';
    }
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _setMode(false),
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
            onTap: () => _setMode(true),
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
    );
  }

  void _setMode(bool isVideoMode) async {
    if (_isRecording) return; // Don't allow mode change while recording

    try {
      if (isVideoMode) {
        // Stop image stream when switching to video mode to prevent conflicts
        if (_cameraController?.value.isStreamingImages == true) {
          await _cameraController!.stopImageStream();
        }
      } else {
        // Restart image stream when switching back to photo mode
        if (_cameraController?.value.isInitialized == true &&
            _cameraController?.value.isStreamingImages == false &&
            _faceDetector != null) {
          try {
            await _cameraController!.startImageStream(_processImage);
          } catch (e) {
            Logger.d('Error restarting image stream: $e');
          }
        }
      }
    } catch (e) {
      Logger.d('Error switching camera mode: $e');
    }

    setState(() {
      _isVideoMode = isVideoMode;
    });
  }

  Future<void> _toggleVideoRecording() async {
    if (!_isVideoMode) return;

    try {
      if (_isRecording) {
        // Stop recording
        _stopRecording();
      } else {
        // Start recording
        _startRecording();
      }
    } catch (e) {
      Logger.d("Error during video recording: $e");
      _resetRecordingState();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        Logger.d("Camera not initialized for video recording");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Camera not ready for video recording.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      Logger.d("Starting video recording...");

      // Haptic feedback for start
      HapticFeedback.lightImpact();

      await _cameraController!.startVideoRecording();

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      // Start the recording timer
      _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _recordingDuration = Duration(milliseconds: timer.tick * 100);
        });

        // Auto-stop at 5 seconds
        if (_recordingDuration >= _maxRecordingDuration) {
          _stopRecording();
        }
      });

      Logger.d("Video recording started successfully");
    } catch (e) {
      Logger.d("Error starting video recording: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start video recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _resetRecordingState();
    }
  }

  Future<void> _stopRecording() async {
    try {
      Logger.d("Stopping video recording...");

      // Haptic feedback for stop
      HapticFeedback.mediumImpact();

      _recordingTimer?.cancel();

      if (_cameraController != null && _cameraController!.value.isRecordingVideo) {
        final XFile videoFile = await _cameraController!.stopVideoRecording();
        Logger.d("Video recording stopped: ${videoFile.path}");

        _resetRecordingState();

        if (!mounted) return;

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PreviewPage(picture: videoFile, isVideo: true),
          ),
        );
      } else {
        Logger.d("Camera not recording, just resetting state");
        _resetRecordingState();
      }
    } catch (e) {
      Logger.d("Error stopping video recording: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop video recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _resetRecordingState();
    }
  }

  void _resetRecordingState() {
    _recordingTimer?.cancel();
    setState(() {
      _isRecording = false;
      _recordingDuration = Duration.zero;
    });
  }

  Widget _buildRecordingIndicator() {
    final seconds = _recordingDuration.inMilliseconds / 1000.0;
    final progress = seconds / _maxRecordingDuration.inSeconds;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${seconds.toStringAsFixed(1)}s',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 200,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: progress > 0.8 ? Colors.red : Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingDot() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _isRecording ? Colors.red : Colors.transparent,
      ),
      child: _isRecording
          ? Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
              ),
            )
          : null,
    );
  }
}

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final Size screenSize;
  final FitnessARFilterType? filterType;
  final ARFilterService arFilterService;
  final InputImageRotation rotation;

  FacePainter({
    required this.faces,
    required this.imageSize,
    required this.screenSize,
    required this.filterType,
    required this.arFilterService,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (Face face in faces) {
      final faceRect = _scaleRect(
        rect: face.boundingBox,
        imageSize: imageSize,
        screenSize: size,
        rotation: rotation,
      );
      _paintFilter(canvas, face, faceRect);
    }
  }

  void _paintFilter(Canvas canvas, Face face, Rect rect) {
    // Skip painting if no filter is selected
    if (filterType == null) return;

    // The actual filter rendering is handled by the widget overlay system in the UI

    // For now, we'll render a simple indicator that a filter is active
    // The actual filter rendering will be handled by the widget overlay system
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawRect(rect, paint);
    
    // Draw filter type indicator
    final textSpan = TextSpan(
      text: _getFilterDisplayName(filterType!),
      style: TextStyle(
        fontSize: 12,
        color: Colors.white,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            offset: const Offset(1.0, 1.0),
            blurRadius: 2.0,
            color: Colors.black.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final offset = Offset(
      rect.center.dx - (textPainter.width / 2),
      rect.bottom + 5,
    );
    textPainter.paint(canvas, offset);
  }

  String _getFilterDisplayName(FitnessARFilterType type) {
    switch (type) {
      case FitnessARFilterType.fastingChampion:
        return 'Fasting Champion';
      case FitnessARFilterType.calorieCrusher:
        return 'Calorie Crusher';
      case FitnessARFilterType.workoutGuide:
        return 'Workout Guide';
      case FitnessARFilterType.progressParty:
        return 'Progress Party';
      case FitnessARFilterType.groupStreakSparkler:
        return 'Group Streak';
    }
  }

  Rect _scaleRect({
    required Rect rect,
    required Size imageSize,
    required Size screenSize,
    required InputImageRotation rotation,
  }) {
    final double scaleX = screenSize.width / imageSize.height;
    final double scaleY = screenSize.height / imageSize.width;

    final double flippedX = imageSize.width - rect.right;

    return Rect.fromLTRB(
      flippedX * scaleX,
      rect.top * scaleY,
      (imageSize.width - rect.left) * scaleX,
      rect.bottom * scaleY,
    );
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.screenSize != screenSize ||
        oldDelegate.filterType != filterType ||
        oldDelegate.rotation != rotation;
  }
}
