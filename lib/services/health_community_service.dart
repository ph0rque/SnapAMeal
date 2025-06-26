import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/health_group.dart';
import '../models/health_challenge.dart';
import 'rag_service.dart';
import 'friend_service.dart';

/// Service for managing health-focused community features
class HealthCommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RAGService _ragService;
  final FriendService _friendService;

  // Collection references
  late final CollectionReference _groupsCollection;
  late final CollectionReference _challengesCollection;
  late final CollectionReference _userHealthProfilesCollection;

  HealthCommunityService(this._ragService, this._friendService) {
    _groupsCollection = _firestore.collection('health_groups');
    _challengesCollection = _firestore.collection('health_challenges');
    _userHealthProfilesCollection = _firestore.collection('user_health_profiles');
  }

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Create a new health group
  Future<String?> createHealthGroup({
    required String name,
    required String description,
    required HealthGroupType type,
    required HealthGroupPrivacy privacy,
    List<String> tags = const [],
    Map<String, dynamic> groupGoals = const {},
    int maxMembers = 50,
    bool allowAnonymous = false,
    bool requireApproval = false,
    String? imageUrl,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final group = HealthGroup(
        id: '', // Will be set by Firestore
        name: name,
        description: description,
        type: type,
        privacy: privacy,
        creatorId: userId,
        memberIds: [userId], // Creator is first member
        adminIds: [userId], // Creator is admin
        tags: tags,
        groupGoals: groupGoals,
        groupStats: {},
        activityLevel: HealthGroupActivity.low,
        createdAt: now,
        lastActivity: now,
        maxMembers: maxMembers,
        allowAnonymous: allowAnonymous,
        requireApproval: requireApproval,
        imageUrl: imageUrl,
      );

      final docRef = await _groupsCollection.add(group.toFirestore());
      debugPrint('Created health group: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating health group: $e');
      return null;
    }
  }

  /// Join a health group
  Future<bool> joinHealthGroup(String groupId) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final groupDoc = await _groupsCollection.doc(groupId).get();
      if (!groupDoc.exists) throw Exception('Group not found');

      final group = HealthGroup.fromFirestore(groupDoc);
      
      // Check if already a member
      if (group.isMember(userId)) {
        debugPrint('User already member of group');
        return true;
      }

      // Check if group is full
      if (group.isFull) {
        debugPrint('Group is full');
        return false;
      }

      // Add user to group
      await _groupsCollection.doc(groupId).update({
        'member_ids': FieldValue.arrayUnion([userId]),
        'last_activity': Timestamp.now(),
      });

      debugPrint('Successfully joined health group: $groupId');
      return true;
    } catch (e) {
      debugPrint('Error joining health group: $e');
      return false;
    }
  }

  /// Leave a health group
  Future<bool> leaveHealthGroup(String groupId) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _groupsCollection.doc(groupId).update({
        'member_ids': FieldValue.arrayRemove([userId]),
        'admin_ids': FieldValue.arrayRemove([userId]),
        'last_activity': Timestamp.now(),
      });

      debugPrint('Successfully left health group: $groupId');
      return true;
    } catch (e) {
      debugPrint('Error leaving health group: $e');
      return false;
    }
  }

  /// Get health groups for current user
  Stream<List<HealthGroup>> getUserHealthGroups() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _groupsCollection
        .where('member_ids', arrayContains: userId)
        .orderBy('last_activity', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HealthGroup.fromFirestore(doc))
            .toList());
  }

  /// Search health groups
  Stream<List<HealthGroup>> searchHealthGroups({
    HealthGroupType? type,
    List<String> tags = const [],
    String? searchTerm,
  }) {
    Query query = _groupsCollection.where('privacy', isEqualTo: 'public');

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    return query
        .orderBy('member_ids', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      var groups = snapshot.docs
          .map((doc) => HealthGroup.fromFirestore(doc))
          .toList();

      // Filter by tags if provided
      if (tags.isNotEmpty) {
        groups = groups.where((group) => 
            group.tags.any((tag) => tags.contains(tag))
        ).toList();
      }

      // Filter by search term if provided
      if (searchTerm != null && searchTerm.isNotEmpty) {
        final lowerSearchTerm = searchTerm.toLowerCase();
        groups = groups.where((group) =>
            group.name.toLowerCase().contains(lowerSearchTerm) ||
            group.description.toLowerCase().contains(lowerSearchTerm) ||
            group.tags.any((tag) => tag.toLowerCase().contains(lowerSearchTerm))
        ).toList();
      }

      return groups;
    });
  }

  /// Create a health challenge
  Future<String?> createHealthChallenge({
    required String title,
    required String description,
    required ChallengeType type,
    required ChallengeDifficulty difficulty,
    required ChallengeFrequency frequency,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> goals,
    Map<String, dynamic> rules = const {},
    Map<String, dynamic> rewards = const {},
    bool isPublic = true,
    bool allowTeams = false,
    int maxParticipants = 100,
    List<String> tags = const [],
    String? imageUrl,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final challenge = HealthChallenge(
        id: '', // Will be set by Firestore
        title: title,
        description: description,
        type: type,
        difficulty: difficulty,
        frequency: frequency,
        creatorId: userId,
        participants: [],
        goals: goals,
        rules: rules,
        rewards: rewards,
        startDate: startDate,
        endDate: endDate,
        createdAt: DateTime.now(),
        isPublic: isPublic,
        allowTeams: allowTeams,
        maxParticipants: maxParticipants,
        tags: tags,
        imageUrl: imageUrl,
      );

      final docRef = await _challengesCollection.add(challenge.toFirestore());
      debugPrint('Created health challenge: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating health challenge: $e');
      return null;
    }
  }

  /// Join a health challenge
  Future<bool> joinHealthChallenge(String challengeId) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final challengeDoc = await _challengesCollection.doc(challengeId).get();
      if (!challengeDoc.exists) throw Exception('Challenge not found');

      final challenge = HealthChallenge.fromFirestore(challengeDoc);
      
      // Check if already participating
      if (challenge.isParticipating(userId)) {
        debugPrint('User already participating in challenge');
        return true;
      }

      // Check if challenge is full
      if (challenge.isFull) {
        debugPrint('Challenge is full');
        return false;
      }

      // Get user data for participant
      final userData = await _friendService.getUserData(userId);
      final participant = ChallengeParticipant(
        userId: userId,
        displayName: userData['display_name'] ?? 'Anonymous',
        joinedAt: DateTime.now(),
        status: ParticipationStatus.active,
        progress: {},
        stats: {},
        avatarUrl: userData['profile_pic_url'],
      );

      // Add participant to challenge
      await _challengesCollection.doc(challengeId).update({
        'participants': FieldValue.arrayUnion([participant.toMap()]),
      });

      debugPrint('Successfully joined health challenge: $challengeId');
      return true;
    } catch (e) {
      debugPrint('Error joining health challenge: $e');
      return false;
    }
  }

  /// Get active challenges for user
  Stream<List<HealthChallenge>> getUserActiveChallenges() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _challengesCollection
        .where('participants', arrayContainsAny: [{'user_id': userId}])
        .orderBy('start_date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => HealthChallenge.fromFirestore(doc))
            .where((challenge) => challenge.isParticipating(userId))
            .toList());
  }

  /// Search public challenges
  Stream<List<HealthChallenge>> searchHealthChallenges({
    ChallengeType? type,
    ChallengeDifficulty? difficulty,
    List<String> tags = const [],
    String? searchTerm,
  }) {
    Query query = _challengesCollection
        .where('is_public', isEqualTo: true)
        .where('end_date', isGreaterThan: Timestamp.now());

    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    if (difficulty != null) {
      query = query.where('difficulty', isEqualTo: difficulty.name);
    }

    return query
        .orderBy('start_date', descending: false)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      var challenges = snapshot.docs
          .map((doc) => HealthChallenge.fromFirestore(doc))
          .toList();

      // Filter by tags if provided
      if (tags.isNotEmpty) {
        challenges = challenges.where((challenge) => 
            challenge.tags.any((tag) => tags.contains(tag))
        ).toList();
      }

      // Filter by search term if provided
      if (searchTerm != null && searchTerm.isNotEmpty) {
        final lowerSearchTerm = searchTerm.toLowerCase();
        challenges = challenges.where((challenge) =>
            challenge.title.toLowerCase().contains(lowerSearchTerm) ||
            challenge.description.toLowerCase().contains(lowerSearchTerm)
        ).toList();
      }

      return challenges;
    });
  }

  /// Get AI-powered friend suggestions based on health goals
  Future<List<Map<String, dynamic>>> getHealthBasedFriendSuggestions() async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Get user's health profile
      final userProfile = await _getUserHealthProfile(userId);
      if (userProfile == null) return [];

      // Get users with similar health goals and patterns
      final suggestions = await _findSimilarUsers(userProfile);
      
      // Use RAG to enhance suggestions with context
      final enhancedSuggestions = await _enhanceSuggestionsWithRAG(suggestions, userProfile);
      
      return enhancedSuggestions;
    } catch (e) {
      debugPrint('Error getting health-based friend suggestions: $e');
      return [];
    }
  }

  /// Update user's health profile for better matching
  Future<bool> updateUserHealthProfile({
    List<String>? healthGoals,
    List<String>? interests,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? activityPatterns,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{};
      if (healthGoals != null) updates['health_goals'] = healthGoals;
      if (interests != null) updates['interests'] = interests;
      if (preferences != null) updates['preferences'] = preferences;
      if (activityPatterns != null) updates['activity_patterns'] = activityPatterns;
      updates['updated_at'] = Timestamp.now();

      await _userHealthProfilesCollection.doc(userId).set(updates, SetOptions(merge: true));
      debugPrint('Updated user health profile');
      return true;
    } catch (e) {
      debugPrint('Error updating user health profile: $e');
      return false;
    }
  }

  /// Get user's health profile
  Future<Map<String, dynamic>?> _getUserHealthProfile(String userId) async {
    try {
      final doc = await _userHealthProfilesCollection.doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user health profile: $e');
      return null;
    }
  }

  /// Find users with similar health profiles
  Future<List<Map<String, dynamic>>> _findSimilarUsers(Map<String, dynamic> userProfile) async {
    try {
      final userGoals = List<String>.from(userProfile['health_goals'] ?? []);
      if (userGoals.isEmpty) return [];

      // Query users with overlapping health goals
      final snapshot = await _userHealthProfilesCollection
          .where('health_goals', arrayContainsAny: userGoals)
          .limit(20)
          .get();

      final suggestions = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        if (doc.id != currentUserId) {
          final profile = doc.data() as Map<String, dynamic>;
          profile['user_id'] = doc.id;
          
          // Calculate similarity score
          final similarity = _calculateHealthSimilarity(userProfile, profile);
          profile['similarity_score'] = similarity;
          
          suggestions.add(profile);
        }
      }

      // Sort by similarity score
      suggestions.sort((a, b) => (b['similarity_score'] as double).compareTo(a['similarity_score'] as double));
      
      return suggestions.take(10).toList();
    } catch (e) {
      debugPrint('Error finding similar users: $e');
      return [];
    }
  }

  /// Calculate similarity score between two health profiles
  double _calculateHealthSimilarity(Map<String, dynamic> profile1, Map<String, dynamic> profile2) {
    double score = 0.0;

    // Compare health goals (40% weight)
    final goals1 = Set<String>.from(profile1['health_goals'] ?? []);
    final goals2 = Set<String>.from(profile2['health_goals'] ?? []);
    if (goals1.isNotEmpty && goals2.isNotEmpty) {
      final intersection = goals1.intersection(goals2);
      final union = goals1.union(goals2);
      score += 0.4 * (intersection.length / union.length);
    }

    // Compare interests (30% weight)
    final interests1 = Set<String>.from(profile1['interests'] ?? []);
    final interests2 = Set<String>.from(profile2['interests'] ?? []);
    if (interests1.isNotEmpty && interests2.isNotEmpty) {
      final intersection = interests1.intersection(interests2);
      final union = interests1.union(interests2);
      score += 0.3 * (intersection.length / union.length);
    }

    // Compare activity patterns (30% weight)
    final patterns1 = Map<String, dynamic>.from(profile1['activity_patterns'] ?? {});
    final patterns2 = Map<String, dynamic>.from(profile2['activity_patterns'] ?? {});
    if (patterns1.isNotEmpty && patterns2.isNotEmpty) {
      double patternSimilarity = 0.0;
      int comparisons = 0;
      
      for (final key in patterns1.keys) {
        if (patterns2.containsKey(key)) {
          // Normalize values and compare
          final val1 = patterns1[key] as num;
          final val2 = patterns2[key] as num;
          final maxVal = val1 > val2 ? val1 : val2;
          if (maxVal > 0) {
            patternSimilarity += 1.0 - ((val1 - val2).abs() / maxVal);
            comparisons++;
          }
        }
      }
      
      if (comparisons > 0) {
        score += 0.3 * (patternSimilarity / comparisons);
      }
    }

    return score;
  }

  /// Enhance suggestions with RAG-powered insights
  Future<List<Map<String, dynamic>>> _enhanceSuggestionsWithRAG(
    List<Map<String, dynamic>> suggestions,
    Map<String, dynamic> userProfile,
  ) async {
    try {
      for (final suggestion in suggestions) {
        // Generate contextualized suggestion reason using RAG
        final reason = await _generateSuggestionReason(suggestion, userProfile);
        suggestion['suggestion_reason'] = reason;
      }
      return suggestions;
    } catch (e) {
      debugPrint('Error enhancing suggestions with RAG: $e');
      return suggestions;
    }
  }

  /// Generate suggestion reason using RAG
  Future<String> _generateSuggestionReason(
    Map<String, dynamic> suggestion,
    Map<String, dynamic> userProfile,
  ) async {
    try {
      final context = '''
      User Profile: ${userProfile['health_goals']?.join(', ')}
      Suggested User: ${suggestion['health_goals']?.join(', ')}
      Similarity Score: ${suggestion['similarity_score']}
      ''';

      // Use RAG service to get health-related advice for friend suggestions
      final healthAdvice = await _ragService.performSemanticSearch(
        query: 'health friend recommendations based on profile: $context',
        maxResults: 3,
      );
      
      return healthAdvice.map((result) => result.document.content).join('\n');
    } catch (e) {
      debugPrint('Error generating suggestion reason: $e');
      return 'You share similar health goals and could motivate each other!';
    }
  }
} 