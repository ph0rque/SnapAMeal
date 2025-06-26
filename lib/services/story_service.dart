import 'dart:io';
import 'dart:math' as math;
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
          'saves': 0,
        },
        'totalEngagementScore': 0,
        'permanence': {
          'duration': const Duration(hours: 24).inSeconds,
          'expiresAt': FieldValue.serverTimestamp(), // Will be updated when first engagement happens
          'tier': 'standard',
          'calculatedAt': FieldValue.serverTimestamp(),
          'isExtended': false,
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
        fastingSession: currentSession!,
      );
    } catch (e) {
      debugPrint('Error checking content filter: $e');
      return null;
    }
  }

  /// Update story engagement metrics with enhanced tracking
  Future<void> updateStoryEngagement(String userId, String storyId, String engagementType, {String? viewerId}) async {
    try {
      final currentUser = _auth.currentUser;
      final actualViewerId = viewerId ?? currentUser?.uid;
      
      if (actualViewerId == null) return;

      final storyRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('stories')
          .doc(storyId);

      // Update engagement metrics
      await storyRef.update({
        'engagement.$engagementType': FieldValue.increment(1),
        'lastEngagementTime': FieldValue.serverTimestamp(),
        'totalEngagementScore': FieldValue.increment(_getEngagementWeight(engagementType)),
      });

      // Track individual engagement event for detailed analytics
      await _firestore.collection('story_engagement').add({
        'storyId': storyId,
        'storyOwnerId': userId,
        'viewerId': actualViewerId,
        'engagementType': engagementType,
        'timestamp': FieldValue.serverTimestamp(),
        'weight': _getEngagementWeight(engagementType),
      });

      // Update story permanence after engagement
      await _calculateAndUpdateStoryPermanence(userId, storyId);
    } catch (e) {
      debugPrint('Error updating story engagement: $e');
    }
  }

  /// Get engagement weight for different interaction types
  int _getEngagementWeight(String engagementType) {
    switch (engagementType) {
      case 'views':
        return 1;
      case 'likes':
        return 3;
      case 'comments':
        return 5;
      case 'shares':
        return 8;
      case 'saves':
        return 10;
      default:
        return 1;
    }
  }

  /// Calculate logarithmic permanence duration for a story
  Future<void> _calculateAndUpdateStoryPermanence(String userId, String storyId) async {
    try {
      final storyDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('stories')
          .doc(storyId)
          .get();

      if (!storyDoc.exists) return;

      final storyData = storyDoc.data() as Map<String, dynamic>;
      final engagement = storyData['engagement'] as Map<String, dynamic>? ?? {};
      final totalScore = storyData['totalEngagementScore'] as int? ?? 0;
      final timestamp = storyData['timestamp'] as Timestamp?;

      if (timestamp == null) return;

      // Calculate logarithmic duration based on engagement
      final permanenceDuration = _calculateLogarithmicDuration(
        totalScore,
        engagement['views'] as int? ?? 0,
        engagement['likes'] as int? ?? 0,
        engagement['comments'] as int? ?? 0,
        engagement['shares'] as int? ?? 0,
      );

      // Calculate expiration time
      final expiresAt = timestamp.toDate().add(permanenceDuration);
      
      // Determine permanence tier
      final permanenceTier = _getPermanenceTier(permanenceDuration);

      await storyDoc.reference.update({
        'permanence': {
          'duration': permanenceDuration.inSeconds,
          'expiresAt': Timestamp.fromDate(expiresAt),
          'tier': permanenceTier,
          'calculatedAt': FieldValue.serverTimestamp(),
          'isExtended': permanenceDuration.inHours > 24,
        }
      });

      debugPrint('Updated story permanence: ${permanenceDuration.inHours} hours (tier: $permanenceTier)');
    } catch (e) {
      debugPrint('Error calculating story permanence: $e');
    }
  }

  /// Calculate logarithmic duration based on engagement metrics
  Duration _calculateLogarithmicDuration(int totalScore, int views, int likes, int comments, int shares) {
    // Base duration: 24 hours
    const baseDuration = Duration(hours: 24);
    
    // Calculate engagement multiplier using logarithmic scale
    // Formula: log(1 + engagement_score) * scaling_factor
    final engagementMultiplier = math.log(1 + totalScore) * 0.5;
    
    // Calculate view velocity bonus (views in first hour)
    final viewVelocityBonus = math.min(views / 10.0, 2.0); // Max 2x bonus
    
    // Calculate interaction quality bonus
    final interactionQuality = (likes * 0.3) + (comments * 0.5) + (shares * 0.7);
    final qualityMultiplier = math.log(1 + interactionQuality) * 0.3;
    
    // Total multiplier (capped at 30 days max)
    final totalMultiplier = math.min(
      1 + engagementMultiplier + viewVelocityBonus + qualityMultiplier,
      30.0 // Max 30x = 30 days
    );
    
    final finalDuration = Duration(
      seconds: (baseDuration.inSeconds * totalMultiplier).round()
    );
    
    return finalDuration;
  }

  /// Get permanence tier based on duration
  String _getPermanenceTier(Duration duration) {
    final hours = duration.inHours;
    
    if (hours <= 24) return 'standard';
    if (hours <= 72) return 'extended';
    if (hours <= 168) return 'weekly';
    if (hours <= 720) return 'monthly';
    return 'milestone';
  }

  /// Get stories with enhanced permanence data
  Stream<QuerySnapshot> getStoriesWithPermanenceStream(String userId) {
    final now = DateTime.now();
    
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('stories')
        .where('permanence.expiresAt', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('permanence.expiresAt', descending: false)
        .snapshots();
  }

  /// Get milestone stories (stories with extended permanence)
  Future<List<DocumentSnapshot>> getMilestoneStories(String userId, {int limit = 20}) async {
    try {
      final milestoneQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('stories')
          .where('permanence.tier', whereIn: ['weekly', 'monthly', 'milestone'])
          .orderBy('permanence.calculatedAt', descending: true)
          .limit(limit)
          .get();

      return milestoneQuery.docs;
    } catch (e) {
      debugPrint('Error getting milestone stories: $e');
      return [];
    }
  }

  /// Get engagement analytics for a story
  Future<Map<String, dynamic>> getStoryAnalytics(String userId, String storyId) async {
    try {
      // Get story data
      final storyDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('stories')
          .doc(storyId)
          .get();

      if (!storyDoc.exists) return {};

      final storyData = storyDoc.data() as Map<String, dynamic>;
      
      // Get detailed engagement events
      final engagementEvents = await _firestore
          .collection('story_engagement')
          .where('storyId', isEqualTo: storyId)
          .orderBy('timestamp', descending: true)
          .get();

      // Calculate analytics
      final analytics = {
        'totalEngagement': storyData['totalEngagementScore'] ?? 0,
        'engagement': storyData['engagement'] ?? {},
        'permanence': storyData['permanence'] ?? {},
        'engagementEvents': engagementEvents.docs.length,
        'uniqueViewers': _getUniqueViewers(engagementEvents.docs),
        'engagementRate': _calculateEngagementRate(storyData['engagement']),
        'peakEngagementTime': _getPeakEngagementTime(engagementEvents.docs),
      };

      return analytics;
    } catch (e) {
      debugPrint('Error getting story analytics: $e');
      return {};
    }
  }

  /// Calculate unique viewers from engagement events
  int _getUniqueViewers(List<DocumentSnapshot> events) {
    final uniqueViewers = <String>{};
    for (final event in events) {
      final data = event.data() as Map<String, dynamic>;
      final viewerId = data['viewerId'] as String?;
      if (viewerId != null) {
        uniqueViewers.add(viewerId);
      }
    }
    return uniqueViewers.length;
  }

  /// Calculate engagement rate (interactions / views)
  double _calculateEngagementRate(Map<String, dynamic>? engagement) {
    if (engagement == null) return 0.0;
    
    final views = engagement['views'] as int? ?? 0;
    if (views == 0) return 0.0;
    
    final interactions = (engagement['likes'] as int? ?? 0) +
                        (engagement['comments'] as int? ?? 0) +
                        (engagement['shares'] as int? ?? 0);
    
    return interactions / views;
  }

  /// Get peak engagement time from events
  DateTime? _getPeakEngagementTime(List<DocumentSnapshot> events) {
    if (events.isEmpty) return null;
    
    // Group events by hour and find the hour with most activity
    final hourlyActivity = <int, int>{};
    
    for (final event in events) {
      final data = event.data() as Map<String, dynamic>;
      final timestamp = data['timestamp'] as Timestamp?;
      if (timestamp != null) {
        final hour = timestamp.toDate().hour;
        hourlyActivity[hour] = (hourlyActivity[hour] ?? 0) + 1;
      }
    }
    
    if (hourlyActivity.isEmpty) return null;
    
    // Find hour with maximum activity
    final peakHour = hourlyActivity.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    // Return a datetime for that hour today
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, peakHour);
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