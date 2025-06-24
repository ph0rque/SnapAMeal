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
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      var rotationCompensation = (sensorOrientation + 360) % 360;
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
              Opacity(
                opacity: 0.7,
                child: CustomPaint(
                  painter: FacePainter(
                    faces: _faces,
                    imageSize: _imageSize!,
                    screenSize: MediaQuery.of(context).size,
                    filter: _filters[_selectedFilterIndex],
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

      final textSpan = TextSpan(
        text: filter,
        style: TextStyle(fontSize: rect.width * 0.45),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      final offset = Offset(
        rect.center.dx - textPainter.width / 2,
        rect.center.dy - textPainter.height / 2 - rect.height * 0.01,
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
    final double scaleX = screenSize.width / imageSize.height;
    final double scaleY = screenSize.height / imageSize.width;
    final double scale = max(scaleX, scaleY);

    final double offsetX = (screenSize.width - imageSize.height * scale) / 2;
    final double offsetY = (screenSize.height - imageSize.width * scale) / 2;
    
    return Rect.fromLTRB(
      screenSize.width - (rect.right * scale + offsetX),
      rect.top * scale + offsetY,
      screenSize.width - (rect.left * scale + offsetX),
      rect.bottom * scale + offsetY,
    );
  }
} 