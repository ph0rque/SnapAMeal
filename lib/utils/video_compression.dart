import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'video_config.dart';

/// Video compression utility for SnapAMeal
class VideoCompressionUtil {
  /// Compress a video file for snap sharing
  static Future<File?> compressVideoForSnap(String videoPath) async {
    try {
      debugPrint('VideoCompressionUtil: Starting compression for $videoPath');

      // Get the output directory
      final tempDir = await getTemporaryDirectory();
      final outputDir = Directory('${tempDir.path}/${VideoConfig.tempVideoDirectory}');
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      // Configure compression settings
      await VideoCompress.setLogLevel(0); // Minimal logging

      // Compress the video
      final info = await VideoCompress.compressVideo(
        videoPath,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false, // Keep original for safety
        includeAudio: true,
      );

      if (info == null) {
        debugPrint('VideoCompressionUtil: Compression failed - no output');
        return null;
      }

      debugPrint('VideoCompressionUtil: Compression completed');
      debugPrint('Original size: ${await File(videoPath).length()} bytes');
      debugPrint('Compressed size: ${info.filesize} bytes');
      debugPrint('Compression ratio: ${(info.filesize! / await File(videoPath).length() * 100).toStringAsFixed(1)}%');

      // Validate compressed file size
      if (!VideoConfig.isValidVideoSize(info.filesize!)) {
        debugPrint('VideoCompressionUtil: Compressed file size invalid: ${info.filesize} bytes');
        await _cleanupFile(info.path!);
        return null;
      }

      return File(info.path!);
    } catch (e) {
      debugPrint('VideoCompressionUtil: Error during compression: $e');
      return null;
    }
  }

  /// Get video information without compression
  static Future<Map<String, dynamic>?> getVideoInfo(String videoPath) async {
    try {
      final info = await VideoCompress.getMediaInfo(videoPath);
      
      return {
        'path': info.path,
        'title': info.title,
        'duration': info.duration,
        'filesize': info.filesize,
        'width': info.width,
        'height': info.height,
        'orientation': info.orientation,
      };
    } catch (e) {
      debugPrint('VideoCompressionUtil: Error getting video info: $e');
      return null;
    }
  }

  /// Generate thumbnail from video
  static Future<File?> generateThumbnail(String videoPath) async {
    try {
      debugPrint('VideoCompressionUtil: Generating thumbnail for $videoPath');

      final tempDir = await getTemporaryDirectory();
      final thumbnailDir = Directory('${tempDir.path}/thumbnails');
      if (!await thumbnailDir.exists()) {
        await thumbnailDir.create(recursive: true);
      }

      final videoName = path.basenameWithoutExtension(videoPath);
      final thumbnailPath = '${thumbnailDir.path}/${videoName}_thumb.jpg';

      final thumbnail = await VideoCompress.getFileThumbnail(
        videoPath,
        quality: VideoConfig.compressionQuality,
        position: 0, // Get first frame
      );

      if (thumbnail == null) {
        debugPrint('VideoCompressionUtil: Failed to generate thumbnail');
        return null;
      }

      debugPrint('VideoCompressionUtil: Thumbnail generated at ${thumbnail.path}');
      return thumbnail;
    } catch (e) {
      debugPrint('VideoCompressionUtil: Error generating thumbnail: $e');
      return null;
    }
  }

  /// Cleanup temporary video files
  static Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final videoTempDir = Directory('${tempDir.path}/${VideoConfig.tempVideoDirectory}');
      final thumbnailDir = Directory('${tempDir.path}/thumbnails');

      if (await videoTempDir.exists()) {
        await videoTempDir.delete(recursive: true);
        debugPrint('VideoCompressionUtil: Cleaned up temp video directory');
      }

      if (await thumbnailDir.exists()) {
        await thumbnailDir.delete(recursive: true);
        debugPrint('VideoCompressionUtil: Cleaned up thumbnail directory');
      }
    } catch (e) {
      debugPrint('VideoCompressionUtil: Error during cleanup: $e');
    }
  }

  /// Cancel any ongoing compression
  static Future<void> cancelCompression() async {
    try {
      await VideoCompress.cancelCompression();
      debugPrint('VideoCompressionUtil: Compression cancelled');
    } catch (e) {
      debugPrint('VideoCompressionUtil: Error cancelling compression: $e');
    }
  }

  /// Delete a specific file safely
  static Future<void> _cleanupFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('VideoCompressionUtil: Cleaned up file: $filePath');
      }
    } catch (e) {
      debugPrint('VideoCompressionUtil: Error cleaning up file $filePath: $e');
    }
  }

  /// Validate video file before processing
  static Future<bool> validateVideoFile(String videoPath) async {
    try {
      final file = File(videoPath);
      if (!await file.exists()) {
        debugPrint('VideoCompressionUtil: Video file does not exist: $videoPath');
        return false;
      }

      final fileSize = await file.length();
      if (!VideoConfig.isValidVideoSize(fileSize)) {
        debugPrint('VideoCompressionUtil: Video file size invalid: $fileSize bytes');
        return false;
      }

      // Check if it's a valid video file by getting info
      final info = await getVideoInfo(videoPath);
      if (info == null) {
        debugPrint('VideoCompressionUtil: Unable to get video info, file may be corrupted');
        return false;
      }

      debugPrint('VideoCompressionUtil: Video file validation successful');
      return true;
    } catch (e) {
      debugPrint('VideoCompressionUtil: Error validating video file: $e');
      return false;
    }
  }
} 