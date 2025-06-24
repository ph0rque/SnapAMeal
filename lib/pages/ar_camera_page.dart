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

  final List<String> _filters = ['😎', '🤡', '👹', '👻', '👽'];
  int _selectedFilterIndex = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _initializeCamera();
    await _initializeFaceDetector();
    setState(() {});
  }

  Future<void> _initializeFaceDetector() async {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first);

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();

    if (mounted) {
      setState(() {});
      _cameraController!.startImageStream(_processImage);
    }
  }

  void _processImage(CameraImage image) {
    if (!mounted) return;
    if (_isDetecting) return;
    _isDetecting = true;

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage != null) {
      _faceDetector?.processImage(inputImage).then((faces) {
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
        });
        _isDetecting = false;
      }).catchError((e) {
        if (mounted) {
          debugPrint("Error processing image: $e");
          _isDetecting = false;
        }
      });
    } else {
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
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      // Find the render object
      RenderRepaintBoundary boundary =
          _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      // Convert to image
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Get temporary directory
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
            CameraPreview(_cameraController!),
            if (_faces.isNotEmpty && _imageSize != null)
              CustomPaint(
                size: Size.infinite,
                painter: FacePainter(
                  faces: _faces,
                  imageSize: _imageSize!,
                  screenSize: MediaQuery.of(context).size,
                  filter: _filters[_selectedFilterIndex],
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
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
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
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilterIndex = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                border: _selectedFilterIndex == index
                    ? Border.all(color: Colors.yellow, width: 3)
                    : null,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _filters[index],
                style: const TextStyle(fontSize: 40),
              ),
            ),
          );
        },
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final List<Face> faces;
  final Size imageSize;
  final Size screenSize;
  final String filter;

  FacePainter({
    required this.faces,
    required this.imageSize,
    required this.screenSize,
    required this.filter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final face in faces) {
      final rect = _scaleRect(
        rect: face.boundingBox,
        imageSize: imageSize,
        screenSize: size,
      );

      // Calculate appropriate font size based on face size - appropriately sized
      final fontSize = rect.width * 0.95; // Fine-tuned for optimal proportion
      
      final textSpan = TextSpan(
        text: filter,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white.withValues(alpha: 0.4), // More transparent
          shadows: [
            Shadow(
              offset: const Offset(3.0, 3.0),
              blurRadius: 6.0,
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ],
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      
      // Position the filter more precisely on the face
      // Adjust the vertical position to be more on the face center
      final offset = Offset(
        rect.center.dx - textPainter.width / 2,
        rect.center.dy - textPainter.height / 2,
      );
      
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.faces != faces ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.screenSize != screenSize ||
        oldDelegate.filter != filter;
  }

  Rect _scaleRect({
    required Rect rect,
    required Size imageSize,
    required Size screenSize,
  }) {
    // Calculate scale factors for both dimensions
    final double scaleX = screenSize.width / imageSize.width;
    final double scaleY = screenSize.height / imageSize.height;
    
    // Use the scale factor that fits the image to the screen (covering mode)
    final double scale = max(scaleX, scaleY);
    
    // Calculate the size of the scaled image
    final double scaledImageWidth = imageSize.width * scale;
    final double scaledImageHeight = imageSize.height * scale;
    
    // Calculate offsets to center the image
    final double offsetX = (screenSize.width - scaledImageWidth) / 2;
    final double offsetY = (screenSize.height - scaledImageHeight) / 2;
    
    // Transform the face rectangle coordinates
    // For front camera, we need to mirror horizontally
    final double left = rect.left * scale + offsetX;
    final double top = rect.top * scale + offsetY;
    final double right = rect.right * scale + offsetX;
    final double bottom = rect.bottom * scale + offsetY;
    
    // Mirror horizontally for front camera (selfie mode)
    return Rect.fromLTRB(
      screenSize.width - right,
      top,
      screenSize.width - left,
      bottom,
    );
  }
} 