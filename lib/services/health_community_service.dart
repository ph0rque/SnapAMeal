import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/health_group.dart';
import '../models/health_challenge.dart';
import '../models/conversation_starter.dart';
import '../data/fallback_content.dart';
import '../utils/logger.dart';
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
  late final CollectionReference _conversationStartersCollection;

  HealthCommunityService(this._ragService, this._friendService) {
    // Check if current user is a demo user
    final userEmail = _auth.currentUser?.email;
    final isDemoUser = userEmail != null && (
      userEmail == 'alice.demo@example.com' ||
      userEmail == 'bob.demo@example.com' ||
      userEmail == 'charlie.demo@example.com'
    );
    
    final prefix = isDemoUser ? 'demo_' : '';
    
    _groupsCollection = _firestore.collection('${prefix}health_groups');
    _challengesCollection = _firestore.collection('${prefix}health_challenges');
    _userHealthProfilesCollection = _firestore.collection(
      '${prefix}user_health_profiles',
    );
    _conversationStartersCollection = _firestore.collection('${prefix}conversation_starters');
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
      Logger.d('Created health group: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      Logger.d('Error creating health group: $e');
      return null;
    }
  }

  /// Join a health group
  Future<bool> joinHealthGroup(String groupId) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        Logger.d('User not authenticated for group join');
        return false;
      }

      // Get the group document to check if user is already a member
      final groupDoc = await _groupsCollection.doc(groupId).get();
      if (!groupDoc.exists) {
        Logger.d('Group not found: $groupId');
        return false;
      }

      final groupData = groupDoc.data() as Map<String, dynamic>;
      final memberIds = List<String>.from(groupData['member_ids'] ?? []);
      
      // Check if user is already a member
      if (memberIds.contains(userId)) {
        Logger.d('User already a member of group: $groupId');
        return true;
      }

      // Add user to member_ids array
      await _groupsCollection.doc(groupId).update({
        'member_ids': FieldValue.arrayUnion([userId]),
        'last_activity': FieldValue.serverTimestamp(),
      });

      Logger.d('Successfully joined health group: $groupId');
      return true;
    } catch (e) {
      Logger.d('Error joining health group: $e');
      return false;
    }
  }



  /// Leave a health group
  Future<bool> leaveHealthGroup(String groupId) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        Logger.d('User not authenticated for group leave');
        return false;
      }

      // Get the group document to check if user is a member
      final groupDoc = await _groupsCollection.doc(groupId).get();
      if (!groupDoc.exists) {
        Logger.d('Group not found: $groupId');
        return false;
      }

      final groupData = groupDoc.data() as Map<String, dynamic>;
      final memberIds = List<String>.from(groupData['member_ids'] ?? []);
      
      // Check if user is a member
      if (!memberIds.contains(userId)) {
        Logger.d('User not a member of group: $groupId');
        return true;
      }

      // Remove user from member_ids array
      await _groupsCollection.doc(groupId).update({
        'member_ids': FieldValue.arrayRemove([userId]),
        'last_activity': FieldValue.serverTimestamp(),
      });

      Logger.d('Successfully left health group: $groupId');
      return true;
    } catch (e) {
      Logger.d('Error leaving health group: $e');
      return false;
    }
  }



  /// Get health groups for current user
  Stream<List<HealthGroup>> getUserHealthGroups() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    try {
      return _groupsCollection
          .where('member_ids', arrayContains: userId)
          .orderBy('last_activity', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => HealthGroup.fromFirestore(doc))
              .toList())
          .handleError((error) {
            // Handle permission errors gracefully
            if (error.toString().contains('permission-denied')) {
              Logger.d('Permission denied for user health groups, returning empty list');
            } else {
              Logger.d('Error in user health groups stream: $error');
            }
            return <HealthGroup>[];
          });
    } catch (e) {
      Logger.d('Error setting up user health groups stream: $e');
      return Stream.value(<HealthGroup>[]);
    }
  }



  /// Search health groups
  Stream<List<HealthGroup>> searchHealthGroups({
    HealthGroupType? type,
    List<String> tags = const [],
    String? searchTerm,
  }) {
    try {
      // Start with all groups, then filter by privacy client-side to be more flexible
      Query query = _groupsCollection;

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      // Add server-side filtering for tags when possible
      if (tags.isNotEmpty && tags.length == 1) {
        // For single tag, we can use server-side filtering
        query = query.where('tags', arrayContains: tags.first);
      }

      return query
          .limit(50) // Increased limit to account for client-side filtering
          .snapshots()
          .map((snapshot) {
            var groups = snapshot.docs
                .map((doc) => HealthGroup.fromFirestore(doc))
                .toList();

            // Filter by privacy (show public groups and groups user belongs to)
            final userId = currentUserId;
            groups = groups.where((group) {
              return group.privacy == HealthGroupPrivacy.public ||
                     (userId != null && group.memberIds.contains(userId));
            }).toList();

            // Filter by multiple tags if provided (client-side for complex queries)
            if (tags.length > 1) {
              groups = groups
                  .where((group) => group.tags.any((tag) => tags.contains(tag)))
                  .toList();
            }

            // Filter by search term if provided (client-side for text search)
            if (searchTerm != null && searchTerm.isNotEmpty) {
              final lowerSearchTerm = searchTerm.toLowerCase();
              groups = groups
                  .where(
                    (group) =>
                        group.name.toLowerCase().contains(lowerSearchTerm) ||
                        group.description.toLowerCase().contains(
                          lowerSearchTerm,
                        ) ||
                        group.tags.any(
                          (tag) => tag.toLowerCase().contains(lowerSearchTerm),
                        ),
                  )
                  .toList();
            }

            // Sort by member count client-side (since server-side orderBy might fail)
            groups.sort((a, b) => b.memberCount.compareTo(a.memberCount));
            
            // Limit final results after filtering
            return groups.take(20).toList();
          })
          .handleError((error) {
            // Handle permission errors gracefully
            if (error.toString().contains('permission-denied')) {
              Logger.d('Permission denied for search health groups, returning empty list');
            } else {
              Logger.d('Error in search health groups stream: $error');
            }
            return <HealthGroup>[];
          });
    } catch (e) {
      Logger.d('Error setting up search health groups stream: $e');
      return Stream.value(<HealthGroup>[]);
    }
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
      Logger.d('Created health challenge: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      Logger.d('Error creating health challenge: $e');
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
        Logger.d('User already participating in challenge');
        return true;
      }

      // Check if challenge is full
      if (challenge.isFull) {
        Logger.d('Challenge is full');
        return false;
      }

      // Get user data for participant
      final userData = await _friendService.getEnhancedUserData(userId);
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

      Logger.d('Successfully joined health challenge: $challengeId');
      return true;
    } catch (e) {
      Logger.d('Error joining health challenge: $e');
      return false;
    }
  }

  /// Get active challenges for user
  Stream<List<HealthChallenge>> getUserActiveChallenges() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _challengesCollection
        .where(
          'participants',
          arrayContainsAny: [
            {'user_id': userId},
          ],
        )
        .orderBy('start_date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => HealthChallenge.fromFirestore(doc))
              .where((challenge) => challenge.isParticipating(userId))
              .toList(),
        );
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
            challenges = challenges
                .where(
                  (challenge) =>
                      challenge.tags.any((tag) => tags.contains(tag)),
                )
                .toList();
          }

          // Filter by search term if provided
          if (searchTerm != null && searchTerm.isNotEmpty) {
            final lowerSearchTerm = searchTerm.toLowerCase();
            challenges = challenges
                .where(
                  (challenge) =>
                      challenge.title.toLowerCase().contains(lowerSearchTerm) ||
                      challenge.description.toLowerCase().contains(
                        lowerSearchTerm,
                      ),
                )
                .toList();
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
      final enhancedSuggestions = await _enhanceSuggestionsWithRAG(
        suggestions,
        userProfile,
      );

      return enhancedSuggestions;
    } catch (e) {
      Logger.d('Error getting health-based friend suggestions: $e');
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
      if (activityPatterns != null) {
        updates['activity_patterns'] = activityPatterns;
      }
      updates['updated_at'] = Timestamp.now();

      await _userHealthProfilesCollection
          .doc(userId)
          .set(updates, SetOptions(merge: true));
      Logger.d('Updated user health profile');
      return true;
    } catch (e) {
      Logger.d('Error updating user health profile: $e');
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
      Logger.d('Error getting user health profile: $e');
      return null;
    }
  }

  /// Find users with similar health profiles
  Future<List<Map<String, dynamic>>> _findSimilarUsers(
    Map<String, dynamic> userProfile,
  ) async {
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
      suggestions.sort(
        (a, b) => (b['similarity_score'] as double).compareTo(
          a['similarity_score'] as double,
        ),
      );

      return suggestions.take(10).toList();
    } catch (e) {
      Logger.d('Error finding similar users: $e');
      return [];
    }
  }

  /// Calculate similarity score between two health profiles
  double _calculateHealthSimilarity(
    Map<String, dynamic> profile1,
    Map<String, dynamic> profile2,
  ) {
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
    final patterns1 = Map<String, dynamic>.from(
      profile1['activity_patterns'] ?? {},
    );
    final patterns2 = Map<String, dynamic>.from(
      profile2['activity_patterns'] ?? {},
    );
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
      Logger.d('Error enhancing suggestions with RAG: $e');
      return suggestions;
    }
  }

  /// Generate suggestion reason using RAG
  Future<String> _generateSuggestionReason(
    Map<String, dynamic> suggestion,
    Map<String, dynamic> userProfile,
  ) async {
    try {
      final context =
          '''
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
      Logger.d('Error generating suggestion reason: $e');
      return 'You share similar health goals and could motivate each other!';
    }
  }

  // ===== CONVERSATION STARTERS =====

  /// Generate AI-powered conversation starter for a group
  Future<ConversationStarter?> generateConversationStarter({
    required String groupId,
    ConversationStarterType? preferredType,
    DateTime? scheduledFor,
  }) async {
    try {
      // Get group information
      final groupDoc = await _groupsCollection.doc(groupId).get();
      if (!groupDoc.exists) {
        Logger.d('Group not found: $groupId');
        return null;
      }

      final group = HealthGroup.fromFirestore(groupDoc);
      
      // Try to generate using RAG service first
      ConversationStarter? starter;
      try {
        starter = await _generateConversationStarterWithRAG(group, preferredType);
      } catch (e) {
        Logger.d('RAG generation failed, using fallback: $e');
      }

      // Use fallback if RAG fails
      starter ??= _generateFallbackConversationStarter(group, preferredType);

      // Set scheduling information
      if (scheduledFor != null) {
        starter = starter.copyWith(scheduledFor: scheduledFor);
      }

      // Save to Firestore
      final docRef = await _conversationStartersCollection.add(starter.toFirestore());
      
      Logger.d('Generated conversation starter for group $groupId: ${docRef.id}');
      return starter.copyWith(title: docRef.id); // Update with actual ID
    } catch (e) {
      Logger.d('Error generating conversation starter: $e');
      return null;
    }
  }

  /// Generate conversation starter using RAG service
  Future<ConversationStarter> _generateConversationStarterWithRAG(
    HealthGroup group,
    ConversationStarterType? preferredType,
  ) async {
    final context = '''
    Health Group Context:
    - Type: ${group.typeDisplayName}
    - Members: ${group.memberCount}
    - Tags: ${group.tags.join(', ')}
    - Goals: ${group.groupGoals.keys.join(', ')}
    - Activity Level: ${group.activityLevel.name}
    
    Generate an engaging conversation starter that:
    - Is relevant to ${group.typeDisplayName} health goals
    - Encourages community participation
    - Is appropriate for ${group.memberCount} members
    - Promotes healthy discussion
    ''';

    final results = await _ragService.performSemanticSearch(
      query: 'health community discussion topics for ${group.type.name} groups: $context',
      maxResults: 3,
    );

    if (results.isEmpty) {
      throw Exception('No RAG results found');
    }

    // Use the first result to create conversation starter
    final content = results.first.document.content;
    final title = 'Weekly ${group.typeDisplayName} Discussion';
    
    return ConversationStarter(
      id: '', // Will be set when saved
      groupId: group.id,
      title: title,
      content: '$content\n\n*This discussion prompt was generated to help our community connect and share experiences.*',
      type: preferredType ?? ConversationStarterType.discussion,
      createdAt: DateTime.now(),
      tags: [...group.tags, 'ai-generated'],
      metadata: {
        'generated_by': 'rag_service',
        'group_type': group.type.name,
        'member_count': group.memberCount,
      },
    );
  }

  /// Generate fallback conversation starter
  ConversationStarter _generateFallbackConversationStarter(
    HealthGroup group,
    ConversationStarterType? preferredType,
  ) {
    final fallbackData = FallbackContent.getConversationStarter(group.type.name);
    
    return ConversationStarter(
      id: '', // Will be set when saved
      groupId: group.id,
      title: fallbackData['title'] as String,
      content: '${fallbackData['content'] as String}\n\n*This discussion prompt was generated to help our community connect and share experiences.*',
      type: ConversationStarterType.values.firstWhere(
        (e) => e.name == fallbackData['type'],
        orElse: () => preferredType ?? ConversationStarterType.discussion,
      ),
      createdAt: DateTime.now(),
      tags: [...(fallbackData['tags'] as List<String>), 'ai-generated'],
      metadata: {
        'generated_by': 'fallback_content',
        'group_type': group.type.name,
        'member_count': group.memberCount,
      },
    );
  }

  /// Post a scheduled conversation starter
  Future<bool> postScheduledConversationStarter(String conversationStarterId) async {
    try {
      await _conversationStartersCollection.doc(conversationStarterId).update({
        'posted_at': Timestamp.now(),
        'status': ConversationStarterStatus.active.name,
      });

      Logger.d('Posted conversation starter: $conversationStarterId');
      return true;
    } catch (e) {
      Logger.d('Error posting conversation starter: $e');
      return false;
    }
  }

  /// Get active conversation starters for a group
  Stream<List<ConversationStarter>> getGroupConversationStarters(String groupId) {
    return _conversationStartersCollection
        .where('group_id', isEqualTo: groupId)
        .where('status', isEqualTo: ConversationStarterStatus.active.name)
        .orderBy('posted_at', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ConversationStarter.fromFirestore(doc))
              .toList(),
        );
  }

  /// Archive old conversation starters
  Future<void> archiveOldConversationStarters({int daysOld = 7}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      final snapshot = await _conversationStartersCollection
          .where('status', isEqualTo: ConversationStarterStatus.active.name)
          .where('posted_at', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'status': ConversationStarterStatus.archived.name,
        });
      }

      await batch.commit();
      Logger.d('Archived ${snapshot.docs.length} old conversation starters');
    } catch (e) {
      Logger.d('Error archiving conversation starters: $e');
    }
  }

  /// Schedule conversation starters for a group
  Future<List<String>> scheduleConversationStarters({
    required String groupId,
    required int count,
    required Duration interval,
  }) async {
    try {
      final scheduledIds = <String>[];
      final now = DateTime.now();

      for (int i = 0; i < count; i++) {
        final scheduledTime = now.add(interval * i);
        
        final starter = await generateConversationStarter(
          groupId: groupId,
          scheduledFor: scheduledTime,
        );

        if (starter != null) {
          scheduledIds.add(starter.id);
        }
      }

      Logger.d('Scheduled ${scheduledIds.length} conversation starters for group $groupId');
      return scheduledIds;
    } catch (e) {
      Logger.d('Error scheduling conversation starters: $e');
      return [];
    }
  }

  /// Update group conversation starter preferences
  Future<bool> updateGroupConversationPreferences({
    required String groupId,
    bool? enableAutoStarters,
    Duration? starterInterval,
    List<ConversationStarterType>? preferredTypes,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (enableAutoStarters != null) {
        updates['auto_conversation_starters'] = enableAutoStarters;
      }
      
      if (starterInterval != null) {
        updates['starter_interval_hours'] = starterInterval.inHours;
      }
      
      if (preferredTypes != null) {
        updates['preferred_starter_types'] = preferredTypes.map((e) => e.name).toList();
      }

      if (updates.isNotEmpty) {
        updates['conversation_preferences_updated_at'] = Timestamp.now();
        
        await _groupsCollection.doc(groupId).update({
          'metadata.conversation_preferences': updates,
        });
      }

      Logger.d('Updated conversation preferences for group $groupId');
      return true;
    } catch (e) {
      Logger.d('Error updating conversation preferences: $e');
      return false;
    }
  }

  /// Report inappropriate conversation starter
  Future<bool> reportConversationStarter({
    required String conversationStarterId,
    required String reason,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _conversationStartersCollection.doc(conversationStarterId).update({
        'status': ConversationStarterStatus.reported.name,
        'reports': FieldValue.arrayUnion([{
          'user_id': userId,
          'reason': reason,
          'reported_at': Timestamp.now(),
        }]),
      });

      Logger.d('Reported conversation starter: $conversationStarterId');
      return true;
    } catch (e) {
      Logger.d('Error reporting conversation starter: $e');
      return false;
    }
  }

  /// Get conversation starter statistics for a group
  Future<Map<String, dynamic>> getConversationStarterStats(String groupId) async {
    try {
      final snapshot = await _conversationStartersCollection
          .where('group_id', isEqualTo: groupId)
          .get();

      final starters = snapshot.docs
          .map((doc) => ConversationStarter.fromFirestore(doc))
          .toList();

      final stats = {
        'total_starters': starters.length,
        'active_starters': starters.where((s) => s.isActive).length,
        'average_engagement': starters.isEmpty 
            ? 0.0 
            : starters.map((s) => s.engagementScore).reduce((a, b) => a + b) / starters.length,
        'most_engaging_type': _getMostEngagingType(starters),
        'last_posted': starters.where((s) => s.isPosted).isNotEmpty 
            ? starters.where((s) => s.isPosted).map((s) => s.postedAt!).reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
      };

      return stats;
    } catch (e) {
      Logger.d('Error getting conversation starter stats: $e');
      return {};
    }
  }

  /// Get most engaging conversation starter type
  String _getMostEngagingType(List<ConversationStarter> starters) {
    if (starters.isEmpty) return 'discussion';

    final typeEngagement = <ConversationStarterType, List<int>>{};
    
    for (final starter in starters) {
      typeEngagement.putIfAbsent(starter.type, () => []).add(starter.engagementScore);
    }

    ConversationStarterType? bestType;
    double bestAverage = 0.0;

    for (final entry in typeEngagement.entries) {
      final average = entry.value.reduce((a, b) => a + b) / entry.value.length;
      if (average > bestAverage) {
        bestAverage = average;
        bestType = entry.key;
      }
    }

    return bestType?.name ?? 'discussion';
  }
}
