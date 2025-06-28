import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';

import 'rag_service.dart';



class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RAGService? _ragService;

  FriendService({RAGService? ragService}) : _ragService = ragService;

  // Search for users by username
  Stream<List<Map<String, dynamic>>> searchUsers(String query) {
    if (query.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => doc.data())
              .where(
                (user) => user['uid'] != _auth.currentUser!.uid,
              ) // Exclude self on the client
              .toList();
        });
  }

  // Send a friend request
  Future<void> sendFriendRequest(String receiverId) async {
    final String currentUserId = _auth.currentUser!.uid;

    // Prevent sending request to self
    if (currentUserId == receiverId) {
      throw Exception('Cannot send friend request to yourself');
    }

    // Check if they are already friends
    final userDoc = await _firestore.collection('users').doc(currentUserId).get();
    final friends = List<String>.from(userDoc.data()?['friends'] ?? []);
    if (friends.contains(receiverId)) {
      throw Exception('You are already friends with this user');
    }

    // create a unique doc id for the friend request
    List<String> ids = [currentUserId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    // Check if friend request already exists (with proper error handling)
    try {
      final existingRequest = await _firestore.collection('friend_requests').doc(chatRoomId).get();
      if (existingRequest.exists) {
        final data = existingRequest.data() as Map<String, dynamic>;
        if (data['status'] == 'pending') {
          throw Exception('Friend request already sent');
        }
      }
    } catch (e) {
      // If we can't check existing requests, proceed anyway
      // This handles permission issues gracefully
      if (e.toString().contains('Friend request already sent')) {
        rethrow; // Re-throw our own exception
      }
      // Otherwise continue with creating the request
    }

    await _firestore.collection('friend_requests').doc(chatRoomId).set({
      'senderId': currentUserId,
      'receiverId': receiverId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Get friend requests for the current user
  Stream<QuerySnapshot> getFriendRequests() {
    final String currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection('friend_requests')
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Accept a friend request
  Future<void> acceptFriendRequest(String senderId) async {
    final String currentUserId = _auth.currentUser!.uid;

    // Get the friend request doc id
    List<String> ids = [currentUserId, senderId];
    ids.sort();
    String chatRoomId = ids.join("_");

    await _firestore.runTransaction((transaction) async {
      // 1. Update the friend request status
      final requestDoc = _firestore
          .collection('friend_requests')
          .doc(chatRoomId);
      transaction.update(requestDoc, {'status': 'accepted'});

      // 2. Add sender to current user's friend list
      final currentUserDoc = _firestore.collection('users').doc(currentUserId);
      transaction.update(currentUserDoc, {
        'friends': FieldValue.arrayUnion([senderId]),
      });

      // 3. Add current user to sender's friend list
      final senderUserDoc = _firestore.collection('users').doc(senderId);
      transaction.update(senderUserDoc, {
        'friends': FieldValue.arrayUnion([currentUserId]),
      });

      // 4. Create friend document in sender's friends subcollection
      final senderFriendDoc = _firestore
          .collection('users')
          .doc(senderId)
          .collection('friends')
          .doc(currentUserId);
      transaction.set(senderFriendDoc, {
        'friendId': currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'streakCount': 0,
        'lastSnapTimestamp': null,
      });

      // 5. Create friend document in current user's friends subcollection
      final currentUserFriendDoc = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(senderId);
      transaction.set(currentUserFriendDoc, {
        'friendId': senderId,
        'timestamp': FieldValue.serverTimestamp(),
        'streakCount': 0,
        'lastSnapTimestamp': null,
      });
    });
  }

  // Decline a friend request
  Future<void> declineFriendRequest(String senderId) async {
    final String currentUserId = _auth.currentUser!.uid;

    List<String> ids = [currentUserId, senderId];
    ids.sort();
    String chatRoomId = ids.join("_");

    await _firestore.collection('friend_requests').doc(chatRoomId).delete();
  }

  // Get user data from Firestore (legacy method for backward compatibility)
  Future<DocumentSnapshot> getUserData(String userId) async {
    try {
      return await _firestore.collection('users').doc(userId).get();
    } catch (e) {
      Logger.d('Error getting user data: $e');
      rethrow;
    }
  }

  // Get the current user's friends stream
  Stream<List<String>> getFriendsStream() {
    final String currentUserId = _auth.currentUser!.uid;
    return _firestore.collection('users').doc(currentUserId).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      if (data != null && data['friends'] != null) {
        return List<String>.from(data['friends']);
      }
      return [];
    });
  }

  // Get a specific friend's document stream
  Stream<DocumentSnapshot> getFriendDocStream(String friendId) {
    final currentUserId = _auth.currentUser!.uid;
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .doc(friendId)
        .snapshots()
        .handleError((error) {
          Logger.d('Error getting friend doc stream for $friendId: $error');
          return null;
        });
  }

  // Get a specific friend's document (one-time read)
  Future<DocumentSnapshot?> getFriendDoc(String friendId) async {
    final currentUserId = _auth.currentUser!.uid;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(friendId)
          .get();
      return doc;
    } catch (e) {
      Logger.d('Error getting friend doc for $friendId: $e');
      return null;
    }
  }

  // Ensure current user's friend document exists (create if missing)
  Future<void> ensureCurrentUserFriendDocExists(String friendId) async {
    final currentUserId = _auth.currentUser!.uid;

    try {
      final currentUserFriendDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friends')
          .doc(friendId)
          .get();

      if (!currentUserFriendDoc.exists) {
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('friends')
            .doc(friendId)
            .set({
              'friendId': friendId,
              'timestamp': FieldValue.serverTimestamp(),
              'streakCount': 0,
              'lastSnapTimestamp': null,
            });
      }
    } catch (e) {
      Logger.d('Error ensuring current user friend document exists: $e');
    }
  }

  // Get or create a one-on-one chat room
  Future<String> getOrCreateOneOnOneChatRoom(String friendId) async {
    try {
      final currentUserId = _auth.currentUser!.uid;
      final members = [currentUserId, friendId]
        ..sort(); // Sort to ensure consistent ordering

      // Check if current user is a demo user
      final userEmail = _auth.currentUser?.email;
      final isDemoUser = userEmail != null && (
        userEmail == 'alice.demo@example.com' ||
        userEmail == 'bob.demo@example.com' ||
        userEmail == 'charlie.demo@example.com'
      );
      
      final collectionName = isDemoUser ? 'demo_chat_rooms' : 'chat_rooms';

      // Check if a chat room already exists with these members
      final existingChatQuery = await _firestore
          .collection(collectionName)
          .where('members', isEqualTo: members)
          .where('isGroup', isEqualTo: false)
          .limit(1)
          .get();

      if (existingChatQuery.docs.isNotEmpty) {
        return existingChatQuery.docs.first.id;
      }

      // Create a new chat room
      final chatRoomDoc = await _firestore.collection(collectionName).add({
        'members': members,
        'isGroup': false,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      return chatRoomDoc.id;
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        Logger.d('Permission denied for chat room creation, trying fallback approach');
        
        // Create deterministic chat room ID and try to create the document directly
        final currentUserId = _auth.currentUser!.uid;
        final members = [currentUserId, friendId]..sort();
        final fallbackId = 'chat_${members.join('_')}';
        
        try {
          final userEmail = _auth.currentUser?.email;
          final isDemoUser = userEmail != null && (
            userEmail == 'alice.demo@example.com' ||
            userEmail == 'bob.demo@example.com' ||
            userEmail == 'charlie.demo@example.com'
          );
          
          final collectionName = isDemoUser ? 'demo_chat_rooms' : 'chat_rooms';
          
          // Try to create the chat room document with the deterministic ID
          await _firestore.collection(collectionName).doc(fallbackId).set({
            'members': members,
            'isGroup': false,
            'createdAt': FieldValue.serverTimestamp(),
            'lastMessage': '',
            'lastMessageTime': FieldValue.serverTimestamp(),
          });
          
          Logger.d('Successfully created fallback chat room: $fallbackId');
          return fallbackId;
        } catch (fallbackError) {
          Logger.d('Fallback chat room creation also failed: $fallbackError');
          // Return the ID anyway - the chat service will handle the missing document
          return fallbackId;
        }
      } else {
        Logger.d('Error creating chat room: $e');
        rethrow;
      }
    }
  }

  // ===== ENHANCED FRIEND MATCHING =====

  /// Get AI-enhanced friend suggestions with personalized justifications
  Future<List<Map<String, dynamic>>> getEnhancedFriendSuggestions({
    int limit = 10,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return [];

      // Get current user's profile and health data
      final userProfile = await _getUserHealthProfile(currentUserId);
      if (userProfile == null) return [];

      // Get potential friend candidates
      final candidates = await _findPotentialFriends(currentUserId, userProfile, limit * 2);
      
      // Generate AI justifications for top candidates
      final enhancedSuggestions = <Map<String, dynamic>>[];
      
      for (final candidate in candidates.take(limit)) {
        try {
          // Generate AI justification for this match
          final justification = await _generateMatchJustification(userProfile, candidate);
          
          candidate['match_justification'] = justification;
          candidate['has_ai_justification'] = justification.isNotEmpty;
          
          enhancedSuggestions.add(candidate);
        } catch (e) {
          Logger.d('Error generating justification for candidate ${candidate['uid']}: $e');
          // Add fallback justification
          candidate['match_justification'] = _getFallbackJustification(userProfile, candidate);
          candidate['has_ai_justification'] = false;
          enhancedSuggestions.add(candidate);
        }
      }

      Logger.d('Generated ${enhancedSuggestions.length} enhanced friend suggestions');
      return enhancedSuggestions;
    } catch (e) {
      Logger.d('Error getting enhanced friend suggestions: $e');
      return [];
    }
  }

  /// Find potential friends based on health goals and activity patterns
  Future<List<Map<String, dynamic>>> _findPotentialFriends(
    String currentUserId,
    Map<String, dynamic> userProfile,
    int limit,
  ) async {
    try {
      // Get current user's friends to exclude them
      final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      final currentFriends = List<String>.from(currentUserDoc.data()?['friends'] ?? []);
      
      // Get user's health goals for matching
      final userGoals = List<String>.from(userProfile['health_goals'] ?? []);
      
      if (userGoals.isEmpty) {
        // If no health goals, find users with similar activity patterns
        return await _findUsersByActivityPattern(currentUserId, currentFriends, limit);
      }

      // Query users with overlapping health goals
      final snapshot = await _firestore
          .collection('user_health_profiles')
          .where('health_goals', arrayContainsAny: userGoals)
          .limit(limit)
          .get();

      final candidates = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final candidateUserId = doc.id;
        
        // Skip self and existing friends
        if (candidateUserId == currentUserId || currentFriends.contains(candidateUserId)) {
          continue;
        }

        // Get full user data
        final userDoc = await _firestore.collection('users').doc(candidateUserId).get();
        if (!userDoc.exists) continue;

        final userData = userDoc.data()!;
        final healthProfile = doc.data();
        
        // Calculate compatibility score
        final compatibilityScore = _calculateCompatibilityScore(userProfile, healthProfile);
        
        candidates.add({
          ...userData,
          'health_profile': healthProfile,
          'compatibility_score': compatibilityScore,
          'uid': candidateUserId,
        });
      }

      // Sort by compatibility score
      candidates.sort((a, b) => (b['compatibility_score'] as double).compareTo(a['compatibility_score'] as double));
      
      return candidates;
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        Logger.d('Permission denied for finding potential friends, returning empty list');
        return [];
      } else {
        Logger.d('Error finding potential friends: $e');
        return [];
      }
    }
  }

  /// Find users by similar activity patterns when health goals are not available
  Future<List<Map<String, dynamic>>> _findUsersByActivityPattern(
    String currentUserId,
    List<String> currentFriends,
    int limit,
  ) async {
    try {
      // Get recent active users (simplified approach)
      final snapshot = await _firestore
          .collection('users')
          .where('last_active', isGreaterThan: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 7)),
          ))
          .limit(limit * 2)
          .get();

      final candidates = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final candidateUserId = doc.id;
        
        // Skip self and existing friends
        if (candidateUserId == currentUserId || currentFriends.contains(candidateUserId)) {
          continue;
        }

        final userData = doc.data();
        
        candidates.add({
          ...userData,
          'compatibility_score': 0.5, // Neutral score for activity-based matching
          'uid': candidateUserId,
        });
      }

      return candidates.take(limit).toList();
    } catch (e) {
      Logger.d('Error finding users by activity pattern: $e');
      return [];
    }
  }

  /// Calculate compatibility score between two health profiles
  double _calculateCompatibilityScore(
    Map<String, dynamic> userProfile,
    Map<String, dynamic> candidateProfile,
  ) {
    double score = 0.0;

    // Health goals compatibility (40% weight)
    final userGoals = Set<String>.from(userProfile['health_goals'] ?? []);
    final candidateGoals = Set<String>.from(candidateProfile['health_goals'] ?? []);
    
    if (userGoals.isNotEmpty && candidateGoals.isNotEmpty) {
      final intersection = userGoals.intersection(candidateGoals);
      final union = userGoals.union(candidateGoals);
      score += 0.4 * (intersection.length / union.length);
    }

    // Activity level compatibility (30% weight)
    final userActivity = userProfile['activity_level'] ?? 'moderate';
    final candidateActivity = candidateProfile['activity_level'] ?? 'moderate';
    
    if (userActivity == candidateActivity) {
      score += 0.3;
    } else {
      // Partial score for similar activity levels
      final activityLevels = ['low', 'moderate', 'high'];
      final userIndex = activityLevels.indexOf(userActivity);
      final candidateIndex = activityLevels.indexOf(candidateActivity);
      
      if (userIndex != -1 && candidateIndex != -1) {
        final difference = (userIndex - candidateIndex).abs();
        score += 0.3 * (1.0 - (difference / 2.0));
      }
    }

    // Dietary preferences compatibility (20% weight)
    final userDiet = Set<String>.from(userProfile['dietary_restrictions'] ?? []);
    final candidateDiet = Set<String>.from(candidateProfile['dietary_restrictions'] ?? []);
    
    if (userDiet.isNotEmpty && candidateDiet.isNotEmpty) {
      final intersection = userDiet.intersection(candidateDiet);
      score += 0.2 * (intersection.length / userDiet.length.clamp(1, double.infinity));
    } else if (userDiet.isEmpty && candidateDiet.isEmpty) {
      score += 0.2; // Both have no restrictions
    }

    // Age compatibility (10% weight)
    final userAge = userProfile['age'] ?? 25;
    final candidateAge = candidateProfile['age'] ?? 25;
    final ageDifference = (userAge - candidateAge).abs();
    
    if (ageDifference <= 5) {
      score += 0.1;
    } else if (ageDifference <= 10) {
      score += 0.05;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Generate AI-powered match justification
  Future<String> _generateMatchJustification(
    Map<String, dynamic> userProfile,
    Map<String, dynamic> candidateProfile,
  ) async {
    if (_ragService == null) {
      return _getFallbackJustification(userProfile, candidateProfile);
    }

    try {
      final context = '''
      User Profile:
      - Health Goals: ${userProfile['health_goals']?.join(', ') ?? 'Not specified'}
      - Activity Level: ${userProfile['activity_level'] ?? 'Not specified'}
      - Dietary Preferences: ${userProfile['dietary_restrictions']?.join(', ') ?? 'None'}
      - Age: ${userProfile['age'] ?? 'Not specified'}
      
      Potential Friend Profile:
      - Health Goals: ${candidateProfile['health_profile']?['health_goals']?.join(', ') ?? 'Not specified'}
      - Activity Level: ${candidateProfile['health_profile']?['activity_level'] ?? 'Not specified'}
      - Dietary Preferences: ${candidateProfile['health_profile']?['dietary_restrictions']?.join(', ') ?? 'None'}
      - Age: ${candidateProfile['health_profile']?['age'] ?? 'Not specified'}
      - Display Name: ${candidateProfile['display_name'] ?? 'User'}
      
      Compatibility Score: ${candidateProfile['compatibility_score']}
      ''';

      final results = await _ragService!.performSemanticSearch(
        query: 'friend matching justification health goals compatibility: $context',
        maxResults: 2,
      );

      if (results.isNotEmpty) {
        // Use RAG results to create personalized justification
        final ragContent = results.first.document.content;
        
        return _createPersonalizedJustification(
          userProfile,
          candidateProfile,
          ragContent,
        );
      }

      return _getFallbackJustification(userProfile, candidateProfile);
    } catch (e) {
      Logger.d('Error generating AI match justification: $e');
      return _getFallbackJustification(userProfile, candidateProfile);
    }
  }

  /// Create personalized justification using RAG content
  String _createPersonalizedJustification(
    Map<String, dynamic> userProfile,
    Map<String, dynamic> candidateProfile,
    String ragContent,
  ) {
    final userGoals = List<String>.from(userProfile['health_goals'] ?? []);
    final candidateGoals = List<String>.from(candidateProfile['health_profile']?['health_goals'] ?? []);
    final sharedGoals = userGoals.where((goal) => candidateGoals.contains(goal)).toList();
    final displayName = candidateProfile['display_name'] ?? 'This person';

    final justificationParts = <String>[];

    // Shared goals
    if (sharedGoals.isNotEmpty) {
      if (sharedGoals.length == 1) {
        justificationParts.add('You both share the goal of ${sharedGoals.first.toLowerCase()}');
      } else {
        justificationParts.add('You share ${sharedGoals.length} health goals including ${sharedGoals.take(2).join(' and ').toLowerCase()}');
      }
    }

    // Activity level compatibility
    final userActivity = userProfile['activity_level'];
    final candidateActivity = candidateProfile['health_profile']?['activity_level'];
    if (userActivity == candidateActivity && userActivity != null) {
      justificationParts.add('you both have a ${userActivity.toLowerCase()} activity level');
    }

    // Dietary compatibility
    final userDiet = List<String>.from(userProfile['dietary_restrictions'] ?? []);
    final candidateDiet = List<String>.from(candidateProfile['health_profile']?['dietary_restrictions'] ?? []);
    final sharedDiet = userDiet.where((diet) => candidateDiet.contains(diet)).toList();
    
    if (sharedDiet.isNotEmpty) {
      justificationParts.add('you both follow ${sharedDiet.join(' and ').toLowerCase()} dietary preferences');
    }

    // Build final justification
    String justification = '$displayName could be a great health buddy';
    
    if (justificationParts.isNotEmpty) {
      if (justificationParts.length == 1) {
        justification += ' because ${justificationParts.first}';
      } else {
        final lastPart = justificationParts.removeLast();
        justification += ' because ${justificationParts.join(', ')} and $lastPart';
      }
    }

    justification += '. You could motivate each other and share your wellness journey!';

    return justification;
  }

  /// Get fallback justification when AI generation fails
  String _getFallbackJustification(
    Map<String, dynamic> userProfile,
    Map<String, dynamic> candidateProfile,
  ) {
    final userGoals = List<String>.from(userProfile['health_goals'] ?? []);
    final candidateGoals = List<String>.from(candidateProfile['health_profile']?['health_goals'] ?? []);
    final sharedGoals = userGoals.where((goal) => candidateGoals.contains(goal)).toList();
    final displayName = candidateProfile['display_name'] ?? 'This person';

    if (sharedGoals.isNotEmpty) {
      return '$displayName shares your interest in ${sharedGoals.first.toLowerCase()} and could be a great accountability partner on your health journey!';
    }

    final compatibilityScore = candidateProfile['compatibility_score'] as double? ?? 0.0;
    
    if (compatibilityScore > 0.7) {
      return '$displayName has a similar health profile to yours and could be an excellent workout buddy and motivational support!';
    } else if (compatibilityScore > 0.5) {
      return '$displayName has complementary health goals that could bring fresh perspectives to your wellness journey!';
    } else {
      return '$displayName is an active member of our health community and could be a great addition to your support network!';
    }
  }

  /// Get user's health profile
  Future<Map<String, dynamic>?> _getUserHealthProfile(String userId) async {
    try {
      final doc = await _firestore.collection('user_health_profiles').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        Logger.d('Permission denied for user health profile, returning fallback');
        return {
          'health_goals': ['general_wellness'],
          'activity_level': 'moderate',
          'dietary_restrictions': [],
          'age': 25,
        };
      } else {
        Logger.d('Error getting user health profile: $e');
        return null;
      }
    }
  }

  /// Get enhanced user data including health profile
  Future<Map<String, dynamic>> getEnhancedUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final healthDoc = await _firestore.collection('user_health_profiles').doc(userId).get();
      
      final userData = userDoc.data() ?? {};
      final healthData = healthDoc.data() ?? {};
      
      return {
        ...userData,
        'health_profile': healthData,
        'uid': userId,
      };
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        Logger.d('Permission denied for enhanced user data, returning fallback');
        return {
          'uid': userId,
          'username': 'User',
          'display_name': 'Health Community Member',
          'profileImageUrl': null,
          'health_profile': {},
        };
      } else {
        Logger.d('Error getting enhanced user data: $e');
        return {'uid': userId};
      }
    }
  }

  /// Update friend suggestion interaction (for learning)
  Future<void> recordFriendSuggestionInteraction({
    required String suggestedUserId,
    required String action, // 'viewed', 'dismissed', 'sent_request'
    String? justification,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _firestore.collection('friend_suggestion_interactions').add({
        'user_id': currentUserId,
        'suggested_user_id': suggestedUserId,
        'action': action,
        'justification': justification,
        'timestamp': FieldValue.serverTimestamp(),
      });

      Logger.d('Recorded friend suggestion interaction: $action for $suggestedUserId');
    } catch (e) {
      Logger.d('Error recording friend suggestion interaction: $e');
    }
  }
}
