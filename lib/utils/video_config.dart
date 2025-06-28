import 'package:camera/camera.dart';

/// Video configuration constants and utilities for SnapAMeal
class VideoConfig {
  // Video recording settings
  static const Duration maxRecordingDuration = Duration(seconds: 5);
  static const ResolutionPreset defaultResolution = ResolutionPreset.low; // Changed to low for better compatibility
  static const bool enableAudio = true;

  // Video file settings
  static const String videoFileExtension = '.mp4';
  static const String videoMimeType = 'video/mp4';

  // Compression settings
  static const int compressionQuality = 75; // 0-100, higher is better quality
  static const int maxVideoBitrate = 1000000; // 1 Mbps
  static const int targetFrameRate = 30;

  // Storage settings
  static const String firebaseVideoStoragePath = 'snaps';
  static const String tempVideoDirectory = 'temp_videos';

  // Thumbnail settings
  static const int thumbnailWidth = 200;
  static const int thumbnailHeight = 200;
  static const String thumbnailExtension = '.jpg';

  // Video validation
  static const int maxVideoSizeBytes = 10 * 1024 * 1024; // 10MB max
  static const int minVideoSizeBytes = 1024; // 1KB min

  /// Get camera configuration for video recording
  static CameraController getCameraController(CameraDescription camera) {
    return CameraController(
      camera,
      defaultResolution,
      enableAudio: enableAudio,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
  }

  /// Get video file name with timestamp
  static String generateVideoFileName() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'video_$timestamp$videoFileExtension';
  }

  /// Get thumbnail file name for a video
  static String getThumbnailFileName(String videoFileName) {
    final baseName = videoFileName.replaceAll(videoFileExtension, '');
    return '${baseName}_thumb$thumbnailExtension';
  }

  /// Validate video file size
  static bool isValidVideoSize(int fileSizeBytes) {
    return fileSizeBytes >= minVideoSizeBytes &&
        fileSizeBytes <= maxVideoSizeBytes;
  }

  /// Get Firebase Storage path for video
  static String getVideoStoragePath(String userId, String fileName) {
    return '$firebaseVideoStoragePath/$userId/$fileName';
  }

  /// Get Firebase Storage path for video thumbnail
  static String getThumbnailStoragePath(
    String userId,
    String thumbnailFileName,
  ) {
    return '$firebaseVideoStoragePath/$userId/thumbnails/$thumbnailFileName';
  }

  /// Video compression configuration
  static Map<String, dynamic> getCompressionConfig() {
    return {
      'quality': compressionQuality,
      'bitrate': maxVideoBitrate,
      'frameRate': targetFrameRate,
      'format': 'mp4',
      'codec': 'h264',
    };
  }
}
