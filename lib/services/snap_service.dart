import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class SnapService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendSnap(String imagePath, int duration, List<String> recipientIds, bool isVideo) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1. Upload image to Firebase Storage
    String imageUrl;
    try {
      debugPrint("Attempting to upload file from path: $imagePath");
      final file = File(imagePath);

      // Check if the file exists before uploading
      if (!await file.exists()) {
        debugPrint("File does not exist at path: $imagePath");
        return;
      }
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.${isVideo ? 'mp4' : 'jpg'}';
      final ref = _storage.ref().child('snaps').child(user.uid).child(fileName);
      
      final uploadTask = await ref.putFile(file);
      imageUrl = await uploadTask.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading snap media: $e");
      return; // Stop execution if upload fails
    }

    // 2. Create snap metadata for each recipient
    for (String recipientId in recipientIds) {
      try {
        final snapData = {
          'imageUrl': imageUrl,
          'senderId': user.uid,
          'receiverId': recipientId, // Add receiverId for each recipient
          'timestamp': FieldValue.serverTimestamp(),
          'duration': duration,
          'isViewed': false,
          'isVideo': isVideo,
          'replayed': false,
          'createdAt': FieldValue.serverTimestamp(), // Add explicit creation timestamp
        };
        
        debugPrint("Sending snap to recipient: $recipientId");
        debugPrint("Snap data: $snapData");
        
        // Try to add the snap document
        try {
          await _firestore
              .collection('users')
              .doc(recipientId)
              .collection('snaps')
              .add(snapData);
          debugPrint("Successfully added snap document for $recipientId");
        } catch (e) {
          debugPrint("Error adding snap document for $recipientId: $e");
          throw e; // Re-throw to be caught by outer try-catch
        }
        
        // Update streak
        try {
          await _updateStreak(user.uid, recipientId);
          debugPrint("Successfully updated streak for $recipientId");
        } catch (e) {
          debugPrint("Error updating streak for $recipientId: $e");
          throw e; // Re-throw to be caught by outer try-catch
        }

      } catch (e) {
        debugPrint("Error sending snap to $recipientId: $e");
      }
    }
  }

  Future<void> _updateStreak(String senderId, String recipientId) async {
    final now = Timestamp.now();
    
    final senderFriendDocRef = _firestore.collection('users').doc(senderId).collection('friends').doc(recipientId);
    final recipientFriendDocRef = _firestore.collection('users').doc(recipientId).collection('friends').doc(senderId);

    try {
      await _firestore.runTransaction((transaction) async {
        final senderFriendDoc = await transaction.get(senderFriendDocRef);
        final recipientFriendDoc = await transaction.get(recipientFriendDocRef);

        // Skip if either friend document doesn't exist
        if (!senderFriendDoc.exists || !recipientFriendDoc.exists) {
          debugPrint("Friend documents don't exist - skipping streak update");
          return;
        }

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

        // Update both sides of the friendship
        transaction.update(senderFriendDocRef, {
          'streakCount': currentStreak,
          'lastSnapTimestamp': now,
        });
         transaction.update(recipientFriendDocRef, {
          'streakCount': currentStreak,
          'lastSnapTimestamp': now,
        });
      });
    } catch (e) {
      debugPrint("Error in _updateStreak transaction: $e");
      // Don't rethrow - streak update failure shouldn't block snap sending
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
    final currentUserDoc = await _firestore.collection('users').doc(user.uid).get();
    final currentUsername = currentUserDoc.data()?['username'] ?? 'Someone';

    // Call the cloud function
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('sendScreenshotNotification');
      await callable.call({
        'snap': snap.data(),
        'viewerUsername': currentUsername,
      });
    } on FirebaseFunctionsException catch (e) {
              debugPrint('Caught FirebaseFunctionsException: ${e.code}, ${e.message}');
    } catch (e) {
              debugPrint('Caught generic exception: $e');
    }
  }
} 