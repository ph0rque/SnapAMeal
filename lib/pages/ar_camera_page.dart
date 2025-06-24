import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:snapameal/pages/preview_page.dart';
import 'package:snapameal/utils/video_config.dart';

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

  final List<String> _filters = ['None', '😎', '🤡', '👹', '👻', '👽'];
  int _selectedFilterIndex = 0;
  
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
  }

  Future<void> _initialize() async {
    // Start with camera initialization only, no face detection initially
    await _initializeCamera();
    setState(() {});
  }

  Future<void> _initializeFaceDetector() async {
    // Only initialize face detector after camera is working
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          performanceMode: FaceDetectorMode.fast,
        ),
      );
      
      // Wait before starting image stream
      await Future.delayed(const Duration(milliseconds: 2000));
      
      if (mounted && _cameraController != null && _cameraController!.value.isInitialized) {
        try {
          await _cameraController!.startImageStream(_processImage);
        } catch (e) {
          debugPrint('Error starting image stream: $e');
          // Continue without face detection if it fails
        }
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras available');
        return;
      }

      final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first);

      // Use better camera configuration for improved aspect ratio
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high, // Use higher resolution for better quality and aspect ratio
        enableAudio: true, // Enable audio for video recording
      );

      await _cameraController!.initialize();

      if (mounted && _cameraController != null && _cameraController!.value.isInitialized) {
        setState(() {});
        
        // Initialize face detection after camera is stable
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) {
          await _initializeFaceDetector();
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera failed to initialize: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _processImage(CameraImage image) {
    if (!mounted || _cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isDetecting || _faceDetector == null) return;
    
    _isDetecting = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage != null && mounted && _faceDetector != null) {
        _faceDetector!.processImage(inputImage).then((faces) {
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
            _rotation = inputImage.metadata?.rotation ?? InputImageRotation.rotation270deg;
          });
          _isDetecting = false;
        }).catchError((e) {
          if (mounted) {
            debugPrint("Error processing image: $e");
          }
          _isDetecting = false;
        });
      } else {
        _isDetecting = false;
      }
    } catch (e) {
      debugPrint("Error in _processImage: $e");
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
      debugPrint('Error stopping image stream: $e');
    });
    
    // Dispose camera controller
    _cameraController?.dispose().catchError((e) {
      debugPrint('Error disposing camera controller: $e');
    });
    _cameraController = null;
    
    // Close face detector
    _faceDetector?.close().catchError((e) {
      debugPrint('Error closing face detector: $e');
    });
    _faceDetector = null;
    
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      if (_selectedFilterIndex == 0) {
        // No filter - take a direct camera picture for better quality
        final XFile picture = await _cameraController!.takePicture();
        
        if (!mounted) return;

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PreviewPage(
              picture: picture,
              isVideo: false,
            ),
          ),
        );
      } else {
        // Filter applied - capture the rendered view
        RenderRepaintBoundary boundary =
            _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        Uint8List pngBytes = byteData!.buffer.asUint8List();

        final String dir = (await getTemporaryDirectory()).path;
        final String filePath = '$dir/${DateTime.now().millisecondsSinceEpoch}.png';
        final File file = File(filePath);
        await file.writeAsBytes(pngBytes);

        if (!mounted) return;

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PreviewPage(
              picture: XFile(file.path),
              isVideo: false,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: RepaintBoundary(
        key: _globalKey,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ensure camera preview fills the screen with proper aspect ratio
            ClipRect(
              child: OverflowBox(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.width / _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
            ),
            // Only show face filters when not recording video and a filter is selected
            if (!_isRecording && _selectedFilterIndex > 0 && _faces.isNotEmpty && _imageSize != null)
              CustomPaint(
                size: Size.infinite,
                painter: FacePainter(
                  faces: _faces,
                  imageSize: _imageSize!,
                  screenSize: MediaQuery.of(context).size,
                  filter: _filters[_selectedFilterIndex],
                  rotation: _rotation,
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
            Positioned(
              top: 40,
              right: 10,
              child: _buildModeToggle(),
            ),
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
              Positioned(
                top: 50,
                left: 20,
                child: _buildRecordingDot(),
              ),
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
                        border: _isVideoMode ? Border.all(color: Colors.red, width: 3) : null,
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
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSelector() {
    return Container(
      height: 60,
      color: Colors.black.withValues(alpha: 0.5),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final isNoneFilter = _filters[index] == 'None';
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilterIndex = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                border: _selectedFilterIndex == index
                    ? Border.all(color: Colors.yellow, width: 3)
                    : Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                borderRadius: BorderRadius.circular(30),
                color: _selectedFilterIndex == index 
                    ? Colors.yellow.withOpacity(0.2)
                    : Colors.transparent,
              ),
              alignment: Alignment.center,
              child: isNoneFilter
                  ? const Text(
                      'None',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Text(
                      _filters[index],
                      style: const TextStyle(fontSize: 30),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
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

  void _setMode(bool isVideoMode) {
    if (_isRecording) return; // Don't allow mode change while recording
    
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
      debugPrint("Error during video recording: $e");
      _resetRecordingState();
    }
  }

  Future<void> _startRecording() async {
    // Haptic feedback for start
    HapticFeedback.lightImpact();
    
    await _cameraController!.startVideoRecording();
    
    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
    });

    // Start the recording timer
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
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
  }

  Future<void> _stopRecording() async {
    // Haptic feedback for stop
    HapticFeedback.mediumImpact();
    
    _recordingTimer?.cancel();
    
    if (_cameraController!.value.isRecordingVideo) {
      final XFile videoFile = await _cameraController!.stopVideoRecording();
      
      _resetRecordingState();

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PreviewPage(
            picture: videoFile,
            isVideo: true,
          ),
        ),
      );
    } else {
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
          color: Colors.black.withOpacity(0.7),
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
  final String filter;
  final InputImageRotation rotation;

  FacePainter({
    required this.faces,
    required this.imageSize,
    required this.screenSize,
    required this.filter,
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
    // Skip painting if filter is 'None'
    if (filter == 'None') return;
    
    final fontSize = rect.width * 0.95; // Fine-tuned for optimal proportion

    final textSpan = TextSpan(
      text: filter,
      style: TextStyle(
        fontSize: fontSize,
        color: Colors.white.withOpacity(0.8),
        shadows: [
          Shadow(
            offset: const Offset(2.0, 2.0),
            blurRadius: 4.0,
            color: Colors.black.withOpacity(0.5),
          ),
        ],
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: 0,
      maxWidth: rect.width,
    );

    final offset = Offset(
      rect.center.dx - (textPainter.width / 2),
      rect.center.dy - (textPainter.height / 2),
    );
    textPainter.paint(canvas, offset);
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
        oldDelegate.filter != filter ||
        oldDelegate.rotation != rotation;
  }
} 