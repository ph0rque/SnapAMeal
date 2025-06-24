import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StoryService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> postStory(String filePath, bool isVideo) async {
    final user = _auth.currentUser;
    if (user == null) return;

    String mediaUrl;
    try {
      final file = File(filePath);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.${isVideo ? 'mp4' : 'jpg'}';
      final ref = _storage.ref().child('stories').child(user.uid).child(fileName);
      
      final uploadTask = await ref.putFile(file);
      mediaUrl = await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading story media: $e");
      return;
    }

    await _firestore.collection('users').doc(user.uid).collection('stories').add({
      'mediaUrl': mediaUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'isVideo': isVideo,
      'viewers': [],
    });
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