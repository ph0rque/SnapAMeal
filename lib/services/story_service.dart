import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../utils/video_compression.dart';
import '../services/content_filter_service.dart';
import '../services/fasting_service.dart';
import '../models/fasting_session.dart';

class StoryService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ContentFilterService? _contentFilterService;
  final FastingService? _fastingService;

  StoryService({
    ContentFilterService? contentFilterService,
    FastingService? fastingService,
  })  : _contentFilterService = contentFilterService,
        _fastingService = fastingService;

  Future<void> postStory(String filePath, bool isVideo, {int duration = 5, String? text}) async {
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
        'text': text, // Store text content for filtering
        'engagement': {
          'views': 0,
          'likes': 0,
          'comments': 0,
          'shares': 0,
        },
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

  /// Get filtered stories for user during fasting
  Stream<List<DocumentSnapshot>> getFilteredStoriesForUserStream(String userId) async* {
    final now = DateTime.now();
    final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

    await for (final snapshot in _firestore
        .collection('users')
        .doc(userId)
        .collection('stories')
        .where('timestamp', isGreaterThanOrEqualTo: twentyFourHoursAgo)
        .orderBy('timestamp', descending: false)
        .snapshots()) {
      
      if (_contentFilterService == null || _fastingService == null) {
        yield snapshot.docs;
        continue;
      }

      try {
        // Get current fasting session
        final currentSession = await _fastingService!.getCurrentSession();
        
        // Filter stories based on fasting state
        final filteredStories = await _contentFilterService!.filterStoryContent(
          snapshot.docs,
          currentSession,
        );
        
        yield filteredStories;
      } catch (e) {
        debugPrint('Error filtering stories: $e');
        yield snapshot.docs; // Fallback to unfiltered
      }
    }
  }

  /// Get stories for all friends with content filtering
  Stream<List<Map<String, dynamic>>> getFilteredFriendsStoriesStream(List<String> friendIds) async* {
    if (friendIds.isEmpty) {
      yield [];
      return;
    }

    final now = DateTime.now();
    final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

    await for (final _ in Stream.periodic(const Duration(seconds: 5))) {
      try {
        final allStories = <Map<String, dynamic>>[];
        
        // Get current fasting session for filtering
        FastingSession? currentSession;
        if (_fastingService != null) {
          currentSession = await _fastingService!.getCurrentSession();
        }

        for (final friendId in friendIds) {
          final friendStories = await _firestore
              .collection('users')
              .doc(friendId)
              .collection('stories')
              .where('timestamp', isGreaterThanOrEqualTo: twentyFourHoursAgo)
              .orderBy('timestamp', descending: false)
              .get();

          if (friendStories.docs.isNotEmpty) {
            List<DocumentSnapshot> filteredStories = friendStories.docs;
            
            // Apply content filtering if fasting
            if (_contentFilterService != null && currentSession?.isActive == true) {
              filteredStories = await _contentFilterService!.filterStoryContent(
                friendStories.docs,
                currentSession,
              );
            }

            if (filteredStories.isNotEmpty) {
              // Get user info
              final userDoc = await _firestore.collection('users').doc(friendId).get();
              final userData = userDoc.data() as Map<String, dynamic>?;

              allStories.add({
                'userId': friendId,
                'username': userData?['username'] ?? 'Unknown',
                'profilePicture': userData?['profilePicture'],
                'stories': filteredStories.map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                }).toList(),
                'totalStories': filteredStories.length,
                'filteredCount': friendStories.docs.length - filteredStories.length,
              });
            }
          }
        }

        // Sort by most recent story
        allStories.sort((a, b) {
          final aLatest = (a['stories'] as List).isNotEmpty 
              ? (a['stories'] as List).last['timestamp'] as Timestamp?
              : null;
          final bLatest = (b['stories'] as List).isNotEmpty 
              ? (b['stories'] as List).last['timestamp'] as Timestamp?
              : null;
          
          if (aLatest == null && bLatest == null) return 0;
          if (aLatest == null) return 1;
          if (bLatest == null) return -1;
          
          return bLatest.compareTo(aLatest);
        });

        yield allStories;
      } catch (e) {
        debugPrint('Error getting filtered friends stories: $e');
        yield [];
      }
    }
  }

  /// Check if content should be filtered for current user
  Future<ContentFilterResult?> checkContentFilter(String text) async {
    if (_contentFilterService == null || _fastingService == null) {
      return null;
    }

    try {
      final currentSession = await _fastingService!.getCurrentSession();
      if (currentSession?.isActive != true) {
        return null;
      }

      return await _contentFilterService!.shouldFilterContent(
        content: text,
        contentType: ContentType.story,
        fastingSession: currentSession,
      );
    } catch (e) {
      debugPrint('Error checking content filter: $e');
      return null;
    }
  }

  /// Update story engagement metrics
  Future<void> updateStoryEngagement(String userId, String storyId, String engagementType) async {
    try {
      final storyRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('stories')
          .doc(storyId);

      await storyRef.update({
        'engagement.$engagementType': FieldValue.increment(1),
        'lastEngagementTime': FieldValue.serverTimestamp(),
      });

      // Track engagement for logarithmic permanence calculation
      await _firestore.collection('story_engagement').add({
        'storyId': storyId,
        'userId': userId,
        'viewerId': _auth.currentUser?.uid,
        'engagementType': engagementType,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating story engagement: $e');
    }
  }

  /// Get filtered alternative content for blocked story
  Future<AlternativeContent?> getAlternativeContentForStory(
    String storyId,
    FilterCategory category,
  ) async {
    if (_contentFilterService == null || _fastingService == null) {
      return null;
    }

    try {
      final currentSession = await _fastingService!.getCurrentSession();
      if (currentSession == null) return null;

      return await _contentFilterService!.generateAlternativeContent(
        category,
        currentSession,
      );
    } catch (e) {
      debugPrint('Error generating alternative content: $e');
      return null;
    }
  }
} 