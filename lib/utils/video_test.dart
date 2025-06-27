import 'package:camera/camera.dart';
import 'logger.dart';

/// Basic utility to test video recording capabilities
class VideoRecordingTest {
  static CameraController? _controller;

  /// Test if the device supports video recording with the camera package
  static Future<bool> testVideoRecordingSupport() async {
    try {
      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        Logger.d('VideoRecordingTest: No cameras available');
        return false;
      }

      // Initialize camera controller with the first camera
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: true, // Enable audio for video recording
      );

      await _controller!.initialize();

      // Check if video recording is supported
      if (_controller!.value.isRecordingVideo) {
        Logger.d('VideoRecordingTest: Video recording already in progress');
        await _controller!.stopVideoRecording();
      }

      // Test starting video recording
      await _controller!.startVideoRecording();
      Logger.d('VideoRecordingTest: Video recording started successfully');

      // Stop recording after a brief moment
      await Future.delayed(const Duration(milliseconds: 500));
      final XFile videoFile = await _controller!.stopVideoRecording();

      Logger.d(
        'VideoRecordingTest: Video recording stopped. File: ${videoFile.path}',
      );

      // Cleanup
      await _controller!.dispose();
      _controller = null;

      return true;
    } catch (e) {
      Logger.d('VideoRecordingTest: Error during video recording test: $e');

      // Cleanup on error
      if (_controller != null) {
        try {
          await _controller!.dispose();
        } catch (disposeError) {
          Logger.d(
            'VideoRecordingTest: Error disposing controller: $disposeError',
          );
        }
        _controller = null;
      }

      return false;
    }
  }

  /// Get basic camera information
  static Future<Map<String, dynamic>> getCameraInfo() async {
    try {
      final cameras = await availableCameras();
      return {
        'cameraCount': cameras.length,
        'cameras': cameras
            .map(
              (camera) => {
                'name': camera.name,
                'lensDirection': camera.lensDirection.toString(),
                'sensorOrientation': camera.sensorOrientation,
              },
            )
            .toList(),
      };
    } catch (e) {
      Logger.d('VideoRecordingTest: Error getting camera info: $e');
      return {'error': e.toString()};
    }
  }
}
