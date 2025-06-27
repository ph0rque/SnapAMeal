import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import '../utils/video_compression.dart';
import '../utils/logger.dart';
import 'friend_service.dart';

class SnapService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendSnap(
    String mediaPath,
    int duration,
    List<String> recipientIds,
    bool isVideo,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1. Process and upload media to Firebase Storage
    String mediaUrl;
    String? thumbnailUrl;
    try {
      Logger.d("Attempting to upload file from path: $mediaPath");
      final file = File(mediaPath);

      // Check if the file exists before uploading
      if (!await file.exists()) {
        Logger.d("File does not exist at path: $mediaPath");
        return;
      }

      File fileToUpload = file;

      // If it's a video, compress it first
      if (isVideo) {
        Logger.d("Processing video file...");

        // Validate video file
        if (!await VideoCompressionUtil.validateVideoFile(mediaPath)) {
          Logger.d("Video file validation failed");
          return;
        }

        // Compress video
        final compressedFile = await VideoCompressionUtil.compressVideoForSnap(
          mediaPath,
        );
        if (compressedFile == null) {
          Logger.d("Video compression failed");
          return;
        }

        fileToUpload = compressedFile;
        Logger.d("Video compressed successfully");

        // Generate and upload thumbnail
        final thumbnailFile = await VideoCompressionUtil.generateThumbnail(
          compressedFile.path,
        );
        if (thumbnailFile != null) {
          try {
            final thumbnailFileName =
                '${DateTime.now().millisecondsSinceEpoch}_thumb.jpg';
            final thumbnailRef = _storage
                .ref()
                .child('snaps')
                .child(user.uid)
                .child('thumbnails')
                .child(thumbnailFileName);
            final thumbnailUploadTask = await thumbnailRef.putFile(
              thumbnailFile,
            );
            thumbnailUrl = await thumbnailUploadTask.ref.getDownloadURL();
            Logger.d("Thumbnail uploaded successfully");

            // Clean up local thumbnail file
            await thumbnailFile.delete();
          } catch (e) {
            Logger.d("Error uploading thumbnail: $e");
            // Continue without thumbnail - not critical
          }
        }
      }

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.${isVideo ? 'mp4' : 'jpg'}';
      final ref = _storage.ref().child('snaps').child(user.uid).child(fileName);

      final uploadTask = await ref.putFile(fileToUpload);
      mediaUrl = await uploadTask.ref.getDownloadURL();

      // Clean up temporary compressed file
      if (isVideo && fileToUpload.path != mediaPath) {
        await fileToUpload.delete();
      }

      Logger.d("Media uploaded successfully");
    } catch (e) {
      Logger.d("Error uploading snap media: $e");
      return; // Stop execution if upload fails
    }

    // 2. Create snap metadata for each recipient
    for (String recipientId in recipientIds) {
      try {
        final snapData = {
          'mediaUrl': mediaUrl,
          'imageUrl': mediaUrl, // Keep for backward compatibility
          'thumbnailUrl': thumbnailUrl,
          'senderId': user.uid,
          'receiverId': recipientId, // Add receiverId for each recipient
          'timestamp': FieldValue.serverTimestamp(),
          'duration': duration,
          'isViewed': false,
          'isVideo': isVideo,
          'replayed': false,
          'createdAt':
              FieldValue.serverTimestamp(), // Add explicit creation timestamp
          'hasBeenScreenshot': false, // Track screenshot notifications
        };

        // Try to add the snap document
        await _firestore
            .collection('users')
            .doc(recipientId)
            .collection('snaps')
            .add(snapData);

        // Update streak (non-blocking)
        try {
          await _updateStreak(user.uid, recipientId);
        } catch (e) {
          Logger.d("Error updating streak for $recipientId: $e");
        }
      } catch (e) {
        Logger.d("Error sending snap to $recipientId: $e");
      }
    }
  }

  Future<void> _updateStreak(String senderId, String recipientId) async {
    final now = Timestamp.now();

    final senderFriendDocRef = _firestore
        .collection('users')
        .doc(senderId)
        .collection('friends')
        .doc(recipientId);
    final recipientFriendDocRef = _firestore
        .collection('users')
        .doc(recipientId)
        .collection('friends')
        .doc(senderId);

    try {
      // Ensure current user's friend document exists
      await FriendService().ensureCurrentUserFriendDocExists(recipientId);

      // Get sender's friend document
      final senderFriendDoc = await senderFriendDocRef.get();
      if (!senderFriendDoc.exists) {
        return; // Skip if no friend document
      }

      // Calculate new streak count
      final data = senderFriendDoc.data()!;
      int currentStreak = data['streakCount'] ?? 0;
      Timestamp? lastSnapTimestamp = data['lastSnapTimestamp'];

      if (lastSnapTimestamp != null) {
        final difference = now.toDate().difference(lastSnapTimestamp.toDate());
        if (difference.inHours >= 24 && difference.inHours < 48) {
          currentStreak++;
        } else if (difference.inHours >= 48) {
          currentStreak = 1; // Reset streak
        }
      } else {
        currentStreak = 1; // First snap
      }

      final updateData = {
        'streakCount': currentStreak,
        'lastSnapTimestamp': now,
      };

      // Update sender's friend document
      await senderFriendDocRef.update(updateData);

      // Optionally try updating recipient's friend document (may fail)
      try {
        await recipientFriendDocRef.update(updateData);
      } catch (e) {
        // Expected to fail sometimes - not a problem
      }
    } catch (e) {
      Logger.d("Error in _updateStreak: $e");
    }
  }

  Stream<QuerySnapshot> getSnapsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('snaps')
        .where('replayed', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> notifySenderOfScreenshot(DocumentSnapshot snap) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Get current user's username
    final currentUserDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();
    final currentUsername = currentUserDoc.data()?['username'] ?? 'Someone';

    // Call the cloud function
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'sendScreenshotNotification',
      );
      await callable.call({
        'snap': snap.data(),
        'viewerUsername': currentUsername,
      });
    } on FirebaseFunctionsException catch (e) {
      Logger.d('Caught FirebaseFunctionsException: ${e.code}, ${e.message}');
    } catch (e) {
      Logger.d('Caught generic exception: $e');
    }
  }
}
