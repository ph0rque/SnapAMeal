import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../utils/video_compression.dart';

class StoryService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> postStory(String filePath, bool isVideo, {int duration = 5}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String mediaUrl;
    String? thumbnailUrl;
    try {
      debugPrint("StoryService: Posting story - isVideo: $isVideo, filePath: $filePath");
      
      File fileToUpload = File(filePath);
      
      // If it's a video, compress it first
      if (isVideo) {
        debugPrint("StoryService: Processing video story...");
        
        // Validate video file
        if (!await VideoCompressionUtil.validateVideoFile(filePath)) {
          debugPrint("StoryService: Video file validation failed");
          return;
        }

        // Compress video
        final compressedFile = await VideoCompressionUtil.compressVideoForSnap(filePath);
        if (compressedFile == null) {
          debugPrint("StoryService: Video compression failed");
          return;
        }
        
        fileToUpload = compressedFile;
        debugPrint("StoryService: Video compressed successfully");

        // Generate and upload thumbnail
        final thumbnailFile = await VideoCompressionUtil.generateThumbnail(compressedFile.path);
        if (thumbnailFile != null) {
          try {
            final thumbnailFileName = '${DateTime.now().millisecondsSinceEpoch}_thumb.jpg';
            final thumbnailRef = _storage.ref().child('stories').child(user.uid).child('thumbnails').child(thumbnailFileName);
            final thumbnailUploadTask = await thumbnailRef.putFile(thumbnailFile);
            thumbnailUrl = await thumbnailUploadTask.ref.getDownloadURL();
            debugPrint("StoryService: Thumbnail uploaded successfully");
            
            // Clean up local thumbnail file
            await thumbnailFile.delete();
          } catch (e) {
            debugPrint("StoryService: Error uploading thumbnail: $e");
            // Continue without thumbnail - not critical for stories
          }
        }
      }
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.${isVideo ? 'mp4' : 'jpg'}';
      final ref = _storage.ref().child('stories').child(user.uid).child(fileName);
      
      final uploadTask = await ref.putFile(fileToUpload);
      mediaUrl = await uploadTask.ref.getDownloadURL();
      
      // Clean up temporary compressed file
      if (isVideo && fileToUpload.path != filePath) {
        await fileToUpload.delete();
      }
      
      debugPrint("StoryService: Story media uploaded successfully");
    } catch (e) {
      debugPrint("StoryService: Error uploading story media: $e");
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).collection('stories').add({
        'mediaUrl': mediaUrl,
        'thumbnailUrl': thumbnailUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'duration': duration,
        'type': isVideo ? 'video' : 'image',
        'isVideo': isVideo, // Keep for backward compatibility
        'viewers': [],
        'senderId': user.uid,
      });
      
      debugPrint("StoryService: Story document created successfully");
    } catch (e) {
      debugPrint("StoryService: Error creating story document: $e");
    }
  }

  Stream<QuerySnapshot> getStoriesForUserStream(String userId) {
    final now = DateTime.now();
    final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('stories')
        .where('timestamp', isGreaterThanOrEqualTo: twentyFourHoursAgo)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
} 