import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../config/demo_personas.dart';
import '../utils/logger.dart';

class DemoDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Random _random = Random();

  // Demo data collection prefixes for isolation
  static const String _demoPrefix = 'demo_';

  /// Seed all demo data for Alice, Bob, and Charlie
  static Future<void> seedAllDemoData() async {
    try {
      Logger.d('🌱 Starting comprehensive demo data seeding...');

      for (final persona in DemoPersonas.all) {
        await _seedPersonaData(persona);
      }

      // Create social connections between personas
      await _createSocialConnections();

      Logger.d('✅ Demo data seeding completed successfully');
    } catch (e) {
      Logger.d('❌ Demo data seeding failed: $e');
      rethrow;
    }
  }

  /// Check if user has demo data
  static Future<bool> hasDemoData(String userId) async {
    try {
      // Check if user has health profile data
      final healthDoc = await _firestore
          .collection('${_demoPrefix}health_profiles')
          .doc(userId)
          .get();

      return healthDoc.exists;
    } catch (e) {
      Logger.d('Error checking demo data for user $userId: $e');
      return false;
    }
  }

  /// Seed data for a specific persona by ID and user ID (public method for reset service)
  static Future<void> seedPersonaData(String personaId, String userId) async {
    final persona = DemoPersonas.getById(personaId);
    if (persona == null) {
      Logger.d('❌ Persona not found: $personaId');
      return;
    }

    Logger.d('🔄 Seeding data for ${persona.displayName} (userId: $userId)...');

    // Seed health profile enhancements
    await _seedHealthProfile(userId, persona);

    // Generate 30+ days of fasting history
    await _seedFastingHistory(userId, persona);

    // Create diverse meal logs
    await _seedMealLogs(userId, persona);

    // Generate progress stories
    await _seedProgressStories(userId, persona);

    // Create AI advice history
    await _seedAIAdviceHistory(userId, persona);

    // Generate health challenges and streaks
    await _seedHealthChallenges(userId, persona);

    Logger.d('✅ Completed seeding for ${persona.displayName}');
  }

  /// Seed comprehensive data for a single persona
  static Future<void> _seedPersonaData(DemoPersona persona) async {
    Logger.d('🔄 Seeding data for ${persona.displayName}...');

    final userId = await _getUserIdForPersona(persona);
    if (userId == null) {
      Logger.d('❌ User not found for persona: ${persona.id}');
      return;
    }

    // Seed health profile enhancements
    await _seedHealthProfile(userId, persona);

    // Generate 30+ days of fasting history
    await _seedFastingHistory(userId, persona);

    // Create diverse meal logs
    await _seedMealLogs(userId, persona);

    // Generate progress stories
    await _seedProgressStories(userId, persona);

    // Create AI advice history
    await _seedAIAdviceHistory(userId, persona);

    // Generate health challenges and streaks
    await _seedHealthChallenges(userId, persona);

    Logger.d('✅ Completed seeding for ${persona.displayName}');
  }

  /// Get Firebase user ID for a demo persona
  static Future<String?> _getUserIdForPersona(DemoPersona persona) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: persona.email)
          .where('isDemo', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      Logger.d('❌ Error getting user ID for ${persona.id}: $e');
      return null;
    }
  }

  /// Seed enhanced health profile data
  static Future<void> _seedHealthProfile(
    String userId,
    DemoPersona persona,
  ) async {
    final healthData = {
      ...persona.healthProfile,
      'profileCompleteness': 95,
      'lastHealthSync': FieldValue.serverTimestamp(),
      'healthGoals': _generateHealthGoals(persona),
      'medicalConditions': _generateMedicalConditions(persona),
      'preferences': _generateHealthPreferences(persona),
      'activityTracking': _generateActivityTracking(persona),
      'nutritionPreferences': _generateNutritionPreferences(persona),
    };

    await _firestore
        .collection('${_demoPrefix}health_profiles')
        .doc(userId)
        .set(healthData);
  }

  /// Generate realistic health goals based on persona
  static Map<String, dynamic> _generateHealthGoals(DemoPersona persona) {
    switch (persona.id) {
      case 'alice':
        return {
          'primary': 'weight_loss',
          'secondary': ['energy_boost', 'better_sleep'],
          'targetWeight': 58.0, // kg
          'weeklyGoal': 'lose_0.5kg',
          'activityGoal': '150_minutes_moderate',
          'sleepGoal': '8_hours',
        };
      case 'bob':
        return {
          'primary': 'muscle_gain',
          'secondary': ['strength_building', 'endurance'],
          'targetWeight': 85.0, // kg
          'weeklyGoal': 'gain_0.25kg_muscle',
          'activityGoal': '5_strength_sessions',
          'proteinGoal': '120g_daily',
        };
      case 'charlie':
        return {
          'primary': 'overall_health',
          'secondary': ['stress_reduction', 'energy_stability'],
          'targetWeight': 68.0, // kg
          'weeklyGoal': 'maintain_weight',
          'activityGoal': '3_yoga_sessions',
          'mindfulnessGoal': '10_minutes_daily',
        };
      default:
        return {};
    }
  }

  /// Generate medical conditions (if any)
  static List<String> _generateMedicalConditions(DemoPersona persona) {
    switch (persona.id) {
      case 'alice':
        return ['mild_insulin_resistance'];
      case 'bob':
        return [];
      case 'charlie':
        return ['hypothyroidism_managed'];
      default:
        return [];
    }
  }

  /// Generate health preferences
  static Map<String, dynamic> _generateHealthPreferences(DemoPersona persona) {
    return {
      'units': 'metric',
      'notifications': {
        'fastingReminders': true,
        'mealLogging': persona.id == 'bob', // Bob is more casual
        'progressUpdates': true,
        'socialActivity': persona.id != 'charlie', // Charlie values privacy
      },
      'privacy': {
        'shareProgress': persona.id == 'alice', // Alice is social
        'allowFriendRequests': persona.id != 'charlie',
        'shareLocation': false,
      },
    };
  }

  /// Generate activity tracking data
  static Map<String, dynamic> _generateActivityTracking(DemoPersona persona) {
    final baseSteps = persona.id == 'bob'
        ? 12000
        : (persona.id == 'alice' ? 8000 : 6000);

    return {
      'averageDailySteps': baseSteps,
      'weeklyActiveMinutes': persona.healthProfile['activityLevel'] == 'active'
          ? 300
          : 150,
      'favoriteActivities': _getFavoriteActivities(persona),
      'fitnessLevel': _getFitnessLevel(persona),
    };
  }

  /// Get favorite activities for persona
  static List<String> _getFavoriteActivities(DemoPersona persona) {
    switch (persona.id) {
      case 'alice':
        return ['walking', 'yoga', 'cycling'];
      case 'bob':
        return ['weight_lifting', 'running', 'basketball'];
      case 'charlie':
        return ['yoga', 'swimming', 'tai_chi'];
      default:
        return ['walking'];
    }
  }

  /// Get fitness level for persona
  static String _getFitnessLevel(DemoPersona persona) {
    switch (persona.healthProfile['activityLevel']) {
      case 'active':
        return 'intermediate';
      case 'moderate':
        return 'beginner_plus';
      case 'light':
        return 'beginner';
      default:
        return 'beginner';
    }
  }

  /// Generate nutrition preferences
  static Map<String, dynamic> _generateNutritionPreferences(
    DemoPersona persona,
  ) {
    return {
      'dietaryRestrictions': persona.healthProfile['dietaryRestrictions'] ?? [],
      'allergies': _generateAllergies(persona),
      'macroTargets': _generateMacroTargets(persona),
      'mealTiming': _generateMealTiming(persona),
      'hydrationGoal': _generateHydrationGoal(persona),
    };
  }

  /// Generate allergies for persona
  static List<String> _generateAllergies(DemoPersona persona) {
    switch (persona.id) {
      case 'alice':
        return ['shellfish'];
      case 'bob':
        return [];
      case 'charlie':
        return ['dairy_sensitivity'];
      default:
        return [];
    }
  }

  /// Generate macro targets based on goals
  static Map<String, int> _generateMacroTargets(DemoPersona persona) {
    final calorieTarget = persona.healthProfile['calorieTarget'] as int;

    switch (persona.id) {
      case 'alice': // Weight loss focus
        return {
          'protein': ((calorieTarget * 0.30) / 4).round(),
          'carbs': ((calorieTarget * 0.35) / 4).round(),
          'fat': ((calorieTarget * 0.35) / 9).round(),
        };
      case 'bob': // Muscle gain focus
        return {
          'protein': ((calorieTarget * 0.35) / 4).round(),
          'carbs': ((calorieTarget * 0.40) / 4).round(),
          'fat': ((calorieTarget * 0.25) / 9).round(),
        };
      case 'charlie': // Balanced health focus
        return {
          'protein': ((calorieTarget * 0.25) / 4).round(),
          'carbs': ((calorieTarget * 0.45) / 4).round(),
          'fat': ((calorieTarget * 0.30) / 9).round(),
        };
      default:
        return {'protein': 100, 'carbs': 200, 'fat': 60};
    }
  }

  /// Generate meal timing preferences
  static Map<String, dynamic> _generateMealTiming(DemoPersona persona) {
    final fastingType = persona.healthProfile['fastingType'] as String;

    switch (fastingType) {
      case '16:8':
        return {
          'eatingWindow': {'start': '12:00', 'end': '20:00'},
          'preferredMealTimes': ['12:00', '16:00', '19:30'],
          'snackAllowed': false,
        };
      case '14:10':
        return {
          'eatingWindow': {'start': '10:00', 'end': '20:00'},
          'preferredMealTimes': ['10:00', '14:00', '19:00'],
          'snackAllowed': true,
        };
      case '5:2':
        return {
          'fastingDays': ['Tuesday', 'Thursday'],
          'fastingDayCalories': 500,
          'normalDayCalories': persona.healthProfile['calorieTarget'],
        };
      default:
        return {
          'eatingWindow': {'start': '08:00', 'end': '20:00'},
          'preferredMealTimes': ['08:00', '12:00', '18:00'],
          'snackAllowed': true,
        };
    }
  }

  /// Generate hydration goal
  static int _generateHydrationGoal(DemoPersona persona) {
    final weight = persona.healthProfile['weight'] as double;
    final activityLevel = persona.healthProfile['activityLevel'] as String;

    int baseWater = (weight * 35).round(); // 35ml per kg

    if (activityLevel == 'active') {
      baseWater += 500; // Extra for active people
    } else if (activityLevel == 'moderate') {
      baseWater += 250;
    }

    return baseWater;
  }

  /// Create social connections between demo users
  static Future<void> _createSocialConnections() async {
    Logger.d('🔄 Creating social connections between demo users...');

    // Get all demo user IDs
    final userIds = <String, String>{};
    for (final persona in DemoPersonas.all) {
      final userId = await _getUserIdForPersona(persona);
      if (userId != null) {
        userIds[persona.id] = userId;
      }
    }

    if (userIds.length < 2) {
      Logger.d('❌ Not enough demo users found for social connections');
      return;
    }

    // Create friendships
    await _createFriendships(userIds);

    // Create health groups
    await _createHealthGroups(userIds);

    // Create group chat histories
    await _createGroupChatHistories(userIds);

    Logger.d('✅ Social connections created successfully');
  }

  /// Create friendships between demo users
  static Future<void> _createFriendships(Map<String, String> userIds) async {
    final friendships = [
      {'user1': 'alice', 'user2': 'bob', 'since': 15}, // 15 days ago
      {'user1': 'alice', 'user2': 'charlie', 'since': 8}, // 8 days ago
      {'user1': 'bob', 'user2': 'charlie', 'since': 12}, // 12 days ago
    ];

    // Create friendships in demo_friendships collection (existing logic)
    for (final friendship in friendships) {
      final user1Id = userIds[friendship['user1']];
      final user2Id = userIds[friendship['user2']];

      if (user1Id != null && user2Id != null) {
        final friendshipData = {
          'userId': user2Id,
          'status': 'accepted',
          'createdAt': Timestamp.fromDate(
            DateTime.now().subtract(Duration(days: friendship['since'] as int)),
          ),
          'isDemo': true,
        };

        // Add friendship in both directions
        await _firestore
            .collection('${_demoPrefix}friendships')
            .doc('${user1Id}_$user2Id')
            .set({...friendshipData, 'userId': user2Id});

        await _firestore
            .collection('${_demoPrefix}friendships')
            .doc('${user2Id}_$user1Id')
            .set({...friendshipData, 'userId': user1Id});
      }
    }

    // ALSO create friendships in demo_users collection for FriendService compatibility
    await _establishUserDocumentFriendships(userIds);
  }

  /// Establish friendships in user documents (FriendService compatible format)
  static Future<void> _establishUserDocumentFriendships(Map<String, String> userIds) async {
    Logger.d('🤝 Establishing friendships in users collection...');
    
    final friendships = [
      {'user1': 'alice', 'user2': 'bob'},
      {'user1': 'alice', 'user2': 'charlie'},
      {'user1': 'bob', 'user2': 'charlie'},
    ];

    for (final friendship in friendships) {
      final user1Id = userIds[friendship['user1']];
      final user2Id = userIds[friendship['user2']];

      if (user1Id != null && user2Id != null) {
        // Update user1's friends array to include user2 (using production users collection)
        await _firestore
            .collection('users')
            .doc(user1Id)
            .update({
              'friends': FieldValue.arrayUnion([user2Id]),
            });

        // Update user2's friends array to include user1 (using production users collection)
        await _firestore
            .collection('users')
            .doc(user2Id)
            .update({
              'friends': FieldValue.arrayUnion([user1Id]),
            });

        // Create friend documents in subcollections for streak tracking
        final friendshipTimestamp = Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 15))
        );

        // Create friend doc in user1's friends subcollection (using production users collection)
        await _firestore
            .collection('users')
            .doc(user1Id)
            .collection('friends')
            .doc(user2Id)
            .set({
              'friendId': user2Id,
              'timestamp': friendshipTimestamp,
              'streakCount': 0,
              'lastSnapTimestamp': null,
            });

        // Create friend doc in user2's friends subcollection (using production users collection)
        await _firestore
            .collection('users')
            .doc(user2Id)
            .collection('friends')
            .doc(user1Id)
            .set({
              'friendId': user1Id,
              'timestamp': friendshipTimestamp,
              'streakCount': 0,
              'lastSnapTimestamp': null,
            });

        Logger.d('✅ Created friendship: ${friendship['user1']} ↔ ${friendship['user2']}');
      }
    }

    Logger.d('✅ Demo user friendships established in users collection');
  }

  /// Create health groups
  static Future<void> _createHealthGroups(Map<String, String> userIds) async {
    final groups = [
      {
        'name': 'Intermittent Fasting Support',
        'description': 'A supportive community for IF practitioners',
        'members': ['alice', 'bob', 'charlie'],
        'createdDaysAgo': 20,
        'isPrivate': false,
      },
      {
        'name': 'Fitness Motivation Squad',
        'description': 'Daily motivation and workout sharing',
        'members': ['alice', 'bob'],
        'createdDaysAgo': 10,
        'isPrivate': true,
      },
    ];

    for (final group in groups) {
      final groupRef = _firestore
          .collection('health_groups')
          .doc();

      final groupData = {
        'name': group['name'],
        'description': group['description'],
        'createdAt': Timestamp.fromDate(
          DateTime.now().subtract(
            Duration(days: group['createdDaysAgo'] as int),
          ),
        ),
        'isPrivate': group['isPrivate'],
        'memberCount': (group['members'] as List).length,
        'isDemo': true,
        'createdBy': userIds['alice'], // Alice creates groups
      };

      await groupRef.set(groupData);

      // Add members to group
      for (final memberPersonaId in group['members'] as List<String>) {
        final memberId = userIds[memberPersonaId];
        if (memberId != null) {
          await _firestore
              .collection('health_groups')
              .doc(groupRef.id)
              .collection('members')
              .doc(memberId)
              .set({
                'userId': memberId,
                'role': memberPersonaId == 'alice' ? 'admin' : 'member',
                'joinedAt': Timestamp.fromDate(
                  DateTime.now().subtract(
                    Duration(days: group['createdDaysAgo'] as int),
                  ),
                ),
                'isDemo': true,
              });
        }
      }
    }
  }

  /// Create group chat histories with authentic health discussions
  static Future<void> _createGroupChatHistories(
    Map<String, String> userIds,
  ) async {
    Logger.d('🔄 Creating group chat histories...');

    // Get group IDs that were created (using production health_groups collection)
    final groupsSnapshot = await _firestore
        .collection('health_groups')
        .where('isDemo', isEqualTo: true)
        .get();

    for (final groupDoc in groupsSnapshot.docs) {
      await _createChatHistoryForGroup(groupDoc.id, userIds);
    }

    Logger.d('✅ Group chat histories created');
  }

  /// Create chat history for a specific group
  static Future<void> _createChatHistoryForGroup(
    String groupId,
    Map<String, String> userIds,
  ) async {
    final now = DateTime.now();
    final batch = _firestore.batch();

    // Generate 20-30 messages over the past 2 weeks
    final messageCount = 20 + _random.nextInt(11); // 20-30 messages

    for (int i = 0; i < messageCount; i++) {
      final daysAgo = _random.nextInt(14); // 0-14 days ago
      final hoursAgo = _random.nextInt(24);
      final messageDate = now.subtract(
        Duration(days: daysAgo, hours: hoursAgo),
      );

      // Pick random sender from group members
      final senderPersonaId = ['alice', 'bob', 'charlie'][_random.nextInt(3)];
      final senderId = userIds[senderPersonaId];

      if (senderId != null) {
        final message = _generateGroupChatMessage(
          senderPersonaId,
          messageDate,
          i,
        );
        message['senderId'] = senderId;
        message['groupId'] = groupId;

        final messageRef = _firestore
            .collection('${_demoPrefix}group_chat_messages')
            .doc('${groupId}_${messageDate.millisecondsSinceEpoch}_$i');

        batch.set(messageRef, message);
      }
    }

    await batch.commit();
  }

  /// Generate authentic group chat message
  static Map<String, dynamic> _generateGroupChatMessage(
    String senderPersonaId,
    DateTime timestamp,
    int index,
  ) {
    final messageTypes = [
      'encouragement',
      'question',
      'tip_sharing',
      'progress_update',
      'challenge',
    ];
    final messageType = messageTypes[_random.nextInt(messageTypes.length)];

    return {
      'senderId': '', // Will be set by caller
      'groupId': '', // Will be set by caller
      'type': messageType,
      'content': _getMessageContent(senderPersonaId, messageType),
      'timestamp': Timestamp.fromDate(timestamp),
      'isDemo': true,
      'reactions': _generateMessageReactions(),
      'replyCount': _random.nextInt(4), // 0-3 replies
      'isEdited': false,
      'metadata': {
        'senderPersona': senderPersonaId,
        'messageType': messageType,
      },
    };
  }

  /// Get message content based on sender and type
  static String _getMessageContent(String senderPersonaId, String messageType) {
    final messages = _getMessagesForPersona(senderPersonaId);
    final typeMessages = messages[messageType] ?? ['Hello everyone!'];
    return typeMessages[_random.nextInt(typeMessages.length)];
  }

  /// Get messages for each persona
  static Map<String, List<String>> _getMessagesForPersona(String personaId) {
    switch (personaId) {
      case 'alice':
        return {
          'encouragement': [
            'You all are doing amazing! Keep up the great work! 💪',
            'Seeing everyone\'s progress is so motivating!',
            'We\'ve got this team! One day at a time 🌟',
            'Love how supportive this group is!',
          ],
          'question': [
            'Has anyone tried adding lemon to their water during fasting?',
            'What\'s your favorite meal to break your fast with?',
            'Any tips for dealing with evening cravings?',
            'How do you stay motivated on tough days?',
          ],
          'tip_sharing': [
            'Pro tip: I set multiple alarms to remind me of my eating window!',
            'Green tea has been a game-changer for my fasting routine',
            'Meal prep on Sundays makes the week so much easier',
            'I track my mood alongside my fasting - really eye-opening!',
          ],
          'progress_update': [
            'Week 3 complete! Feeling more energized than ever',
            'Hit my hydration goal every day this week! 💧',
            'Down 3 pounds and feeling great!',
            'My sleep quality has improved so much since starting IF',
          ],
          'challenge': [
            'Challenge: Let\'s all try 10,000 steps today! Who\'s in?',
            'Weekend challenge: Try a new healthy recipe!',
            'Mindfulness challenge: Practice gratitude before each meal',
          ],
        };

      case 'bob':
        return {
          'encouragement': [
            'Nice work everyone! 👊',
            'Keep pushing, we\'re all in this together',
            'Solid progress from everyone this week!',
            'Love the energy in this group',
          ],
          'question': [
            'Anyone else working out during their fasting window?',
            'Best pre-workout meal for you guys?',
            'How do you balance strength training with IF?',
            'What time do you usually start your eating window?',
          ],
          'tip_sharing': [
            'I do my workouts right before breaking my fast - works great',
            'Black coffee is my best friend during morning fasts',
            'Keeping busy helps me forget about being hungry',
            'I use a fasting app to track my progress',
          ],
          'progress_update': [
            'Crushed my workout today even while fasting!',
            'Finally got used to the 16:8 schedule',
            'Strength gains are still coming despite the calorie restriction',
            'Energy levels are way more stable now',
          ],
          'challenge': [
            'Who wants to do a workout challenge this week?',
            'Let\'s see who can stick to their fasting window perfectly!',
            'Challenge: No processed foods for 3 days',
          ],
        };

      case 'charlie':
        return {
          'encouragement': [
            'Grateful for this supportive community 🙏',
            'Your dedication inspires me every day',
            'Beautiful to see everyone growing together',
            'Sending positive energy to everyone',
          ],
          'question': [
            'How has fasting affected your meditation practice?',
            'Any recommendations for mindful eating techniques?',
            'Do you notice mental clarity improvements?',
            'How do you handle social eating situations?',
          ],
          'tip_sharing': [
            'I practice deep breathing when I feel hungry',
            'Herbal teas have become my evening ritual',
            'Journaling about my fasting experience helps a lot',
            'I focus on gratitude during meal times',
          ],
          'progress_update': [
            'Feeling more centered and balanced each week',
            'My stress levels have decreased significantly',
            'The mind-body connection is getting stronger',
            'Learning to listen to my body\'s signals better',
          ],
          'challenge': [
            'Mindfulness challenge: Eat one meal in complete silence today',
            'Let\'s practice gratitude before every meal this week',
            'Challenge: 5 minutes of meditation before breaking fast',
          ],
        };

      default:
        return {
          'encouragement': ['Great job everyone!'],
          'question': ['How is everyone doing?'],
          'tip_sharing': ['Here\'s a helpful tip...'],
          'progress_update': ['Making good progress!'],
          'challenge': ['Let\'s try something new!'],
        };
    }
  }

  /// Generate message reactions
  static Map<String, int> _generateMessageReactions() {
    final reactions = ['👍', '❤️', '💪', '🔥', '👏'];
    final messageReactions = <String, int>{};

    // Randomly add 0-3 different reaction types
    final reactionCount = _random.nextInt(4);
    final selectedReactions = reactions..shuffle();

    for (int i = 0; i < reactionCount; i++) {
      messageReactions[selectedReactions[i]] =
          _random.nextInt(3) + 1; // 1-3 of each reaction
    }

    return messageReactions;
  }

  /// Generate 30+ days of realistic fasting session history
  static Future<void> _seedFastingHistory(
    String userId,
    DemoPersona persona,
  ) async {
    Logger.d('🔄 Generating fasting history for ${persona.displayName}...');

    final fastingType = persona.healthProfile['fastingType'] as String;
    final now = DateTime.now();
    final batch = _firestore.batch();

    // Generate 35 days of history for comprehensive demo
    for (int daysAgo = 35; daysAgo >= 0; daysAgo--) {
      final sessionDate = now.subtract(Duration(days: daysAgo));

      // Skip some days based on persona consistency
      if (_shouldSkipFastingDay(persona, sessionDate, daysAgo)) {
        continue;
      }

      final fastingSession = _generateFastingSession(
        persona,
        sessionDate,
        fastingType,
      );
      fastingSession['userId'] = userId;

      final sessionRef = _firestore
          .collection('${_demoPrefix}fasting_sessions')
          .doc('${userId}_${sessionDate.millisecondsSinceEpoch}');

      batch.set(sessionRef, fastingSession);
    }

    await batch.commit();
    Logger.d('✅ Fasting history generated for ${persona.displayName}');
  }

  /// Determine if persona should skip fasting on this day
  static bool _shouldSkipFastingDay(
    DemoPersona persona,
    DateTime date,
    int daysAgo,
  ) {
    // Weekend patterns and persona-specific behaviors
    final weekday = date.weekday;

    switch (persona.id) {
      case 'alice':
        // Alice is consistent but occasionally skips weekends (10% chance)
        return weekday >= 6 && _random.nextDouble() < 0.1;

      case 'bob':
        // Bob is less consistent, skips 15% of days randomly
        return _random.nextDouble() < 0.15;

      case 'charlie':
        // Charlie follows 5:2, only fasts specific days
        if (persona.healthProfile['fastingType'] == '5:2') {
          return !(weekday == 2 || weekday == 4); // Tuesday/Thursday only
        }
        // Otherwise very consistent (5% skip rate)
        return _random.nextDouble() < 0.05;

      default:
        return false;
    }
  }

  /// Generate a realistic fasting session for the persona
  static Map<String, dynamic> _generateFastingSession(
    DemoPersona persona,
    DateTime sessionDate,
    String fastingType,
  ) {
    final baseData = {
      'userId': '', // Will be set by caller
      'date': Timestamp.fromDate(sessionDate),
      'fastingType': fastingType,
      'isDemo': true,
      'createdAt': Timestamp.fromDate(sessionDate),
    };

    switch (fastingType) {
      case '16:8':
        return {...baseData, ...generate16_8Session(persona, sessionDate)};
      case '14:10':
        return {...baseData, ...generate14_10Session(persona, sessionDate)};
      case '5:2':
        return {...baseData, ...generate5_2Session(persona, sessionDate)};
      default:
        return baseData;
    }
  }

  /// Generate 16:8 fasting session data
  static Map<String, dynamic> generate16_8Session(
    DemoPersona persona,
    DateTime date,
  ) {
    // Typical 16:8: fast 20:00 - 12:00 next day (16 hours)
    final fastStart = DateTime(date.year, date.month, date.day, 20, 0);
    final plannedEnd = fastStart.add(const Duration(hours: 16));

    // Add some realistic variation
    final actualVariation = _getPersonaVariation(persona);
    final actualEnd = plannedEnd.add(Duration(minutes: actualVariation));

    final actualDuration = actualEnd.difference(fastStart);
    final success =
        actualDuration.inMinutes >= 14 * 60; // At least 14 hours = success

    return {
      'fastStartTime': Timestamp.fromDate(fastStart),
      'plannedEndTime': Timestamp.fromDate(plannedEnd),
      'actualEndTime': Timestamp.fromDate(actualEnd),
      'plannedDurationMinutes': 16 * 60,
      'actualDurationMinutes': actualDuration.inMinutes,
      'completed': success,
      'difficulty': _getDifficulty(persona, actualDuration.inMinutes, 16 * 60),
      'mood': _getMoodAfterFast(persona, success),
      'notes': _getFastingNotes(persona, success, actualDuration.inMinutes),
      'waterIntake': _getWaterIntake(persona),
      'energyLevel': _getEnergyLevel(persona, success),
    };
  }

  /// Generate 14:10 fasting session data
  static Map<String, dynamic> generate14_10Session(
    DemoPersona persona,
    DateTime date,
  ) {
    // Typical 14:10: fast 20:00 - 10:00 next day (14 hours)
    final fastStart = DateTime(date.year, date.month, date.day, 20, 0);
    final plannedEnd = fastStart.add(const Duration(hours: 14));

    final actualVariation = _getPersonaVariation(persona);
    final actualEnd = plannedEnd.add(Duration(minutes: actualVariation));

    final actualDuration = actualEnd.difference(fastStart);
    final success =
        actualDuration.inMinutes >= 12 * 60; // At least 12 hours = success

    return {
      'fastStartTime': Timestamp.fromDate(fastStart),
      'plannedEndTime': Timestamp.fromDate(plannedEnd),
      'actualEndTime': Timestamp.fromDate(actualEnd),
      'plannedDurationMinutes': 14 * 60,
      'actualDurationMinutes': actualDuration.inMinutes,
      'completed': success,
      'difficulty': _getDifficulty(persona, actualDuration.inMinutes, 14 * 60),
      'mood': _getMoodAfterFast(persona, success),
      'notes': _getFastingNotes(persona, success, actualDuration.inMinutes),
      'waterIntake': _getWaterIntake(persona),
      'energyLevel': _getEnergyLevel(persona, success),
    };
  }

  /// Generate 5:2 fasting session data
  static Map<String, dynamic> generate5_2Session(
    DemoPersona persona,
    DateTime date,
  ) {
    // 5:2 fasting day: limit to 500 calories
    final weekday = date.weekday;
    final isFastingDay = weekday == 2 || weekday == 4; // Tuesday or Thursday

    if (!isFastingDay) {
      return {
        'type': 'normal_eating_day',
        'caloriesConsumed': persona.healthProfile['calorieTarget'],
        'completed': true,
        'difficulty': 'easy',
        'mood': 'satisfied',
        'notes': 'Normal eating day - maintained healthy choices',
      };
    }

    // Fasting day (500 calories max)
    final targetCalories = 500;
    final actualCalories =
        targetCalories + _random.nextInt(100) - 50; // ±50 calories
    final success = actualCalories <= 600; // Some flexibility

    return {
      'type': 'fasting_day',
      'targetCalories': targetCalories,
      'actualCalories': actualCalories,
      'completed': success,
      'difficulty': _getDifficulty(persona, actualCalories, targetCalories),
      'mood': _getMoodAfterFast(persona, success),
      'notes': _getFastingNotes(persona, success, actualCalories),
      'waterIntake': _getWaterIntake(persona),
      'energyLevel': _getEnergyLevel(persona, success),
      'meals': _generate5_2Meals(actualCalories),
    };
  }

  /// Get persona-specific time variation in minutes
  static int _getPersonaVariation(DemoPersona persona) {
    switch (persona.id) {
      case 'alice':
        // Alice is disciplined, small variations
        return _random.nextInt(30) - 15; // ±15 minutes
      case 'bob':
        // Bob is casual, larger variations
        return _random.nextInt(120) - 60; // ±60 minutes
      case 'charlie':
        // Charlie is consistent but flexible
        return _random.nextInt(60) - 30; // ±30 minutes
      default:
        return 0;
    }
  }

  /// Get difficulty rating based on performance
  static String _getDifficulty(DemoPersona persona, int actual, int target) {
    final performance = actual / target;

    switch (persona.id) {
      case 'alice':
        if (performance >= 0.95) return 'easy';
        if (performance >= 0.85) return 'moderate';
        return 'hard';
      case 'bob':
        if (performance >= 0.90) return 'easy';
        if (performance >= 0.75) return 'moderate';
        return 'hard';
      case 'charlie':
        if (performance >= 0.98) return 'easy';
        if (performance >= 0.90) return 'moderate';
        return 'hard';
      default:
        return 'moderate';
    }
  }

  /// Get mood after fasting based on success and persona
  static String _getMoodAfterFast(DemoPersona persona, bool success) {
    if (!success) {
      switch (persona.id) {
        case 'alice':
          return 'disappointed';
        case 'bob':
          return 'okay';
        case 'charlie':
          return 'reflective';
        default:
          return 'neutral';
      }
    }

    // Success moods
    switch (persona.id) {
      case 'alice':
        return _random.nextBool() ? 'accomplished' : 'energized';
      case 'bob':
        return _random.nextBool() ? 'good' : 'satisfied';
      case 'charlie':
        return _random.nextBool() ? 'peaceful' : 'centered';
      default:
        return 'good';
    }
  }

  /// Generate fasting notes based on persona and performance
  static String _getFastingNotes(
    DemoPersona persona,
    bool success,
    int actualMinutes,
  ) {
    final notes = <String>[];

    if (success) {
      switch (persona.id) {
        case 'alice':
          notes.addAll([
            'Felt great throughout the fast!',
            'Energy levels were stable',
            'Proud of staying consistent',
            'Looking forward to my meal',
          ]);
          break;
        case 'bob':
          notes.addAll([
            'Pretty easy today',
            'Kept busy with work',
            'Feeling good about it',
            'Ready to eat!',
          ]);
          break;
        case 'charlie':
          notes.addAll([
            'Mindful throughout the process',
            'Grateful for the discipline',
            'Body feels clean and light',
            'Meditation helped with hunger',
          ]);
          break;
      }
    } else {
      switch (persona.id) {
        case 'alice':
          notes.addAll([
            'Struggled a bit today',
            'Will try better tomorrow',
            'Maybe need more sleep',
          ]);
          break;
        case 'bob':
          notes.addAll([
            'Got hungry earlier than usual',
            'No big deal, tomorrow is new day',
            'Had some snacks, still good',
          ]);
          break;
        case 'charlie':
          notes.addAll([
            'Listened to my body today',
            'Some days are harder than others',
            'Being gentle with myself',
          ]);
          break;
      }
    }

    return notes[_random.nextInt(notes.length)];
  }

  /// Get water intake for persona
  static int _getWaterIntake(DemoPersona persona) {
    final baseIntake = _generateHydrationGoal(persona);
    final variation = _random.nextInt(500) - 250; // ±250ml variation
    return (baseIntake + variation).clamp(1000, 4000);
  }

  /// Get energy level after fasting
  static String _getEnergyLevel(DemoPersona persona, bool success) {
    if (!success) {
      return _random.nextBool() ? 'low' : 'tired';
    }

    final levels = ['high', 'good', 'stable', 'energized'];
    return levels[_random.nextInt(levels.length)];
  }

  /// Generate meals for 5:2 fasting day
  static List<Map<String, dynamic>> _generate5_2Meals(int totalCalories) {
    return [
      {
        'name': 'Light breakfast',
        'calories': (totalCalories * 0.3).round(),
        'description': 'Green tea and small fruit',
      },
      {
        'name': 'Vegetable soup',
        'calories': (totalCalories * 0.7).round(),
        'description': 'Low-calorie vegetable broth with herbs',
      },
    ];
  }

  /// Create diverse meal logs with AI captions and nutrition data
  static Future<void> _seedMealLogs(String userId, DemoPersona persona) async {
    Logger.d('🔄 Generating meal logs for ${persona.displayName}...');

    final now = DateTime.now();
    final batch = _firestore.batch();

    // Generate 30 days of meal logs
    for (int daysAgo = 30; daysAgo >= 0; daysAgo--) {
      final mealDate = now.subtract(Duration(days: daysAgo));

      // Generate 2-4 meals per day based on persona and fasting schedule
      final mealsPerDay = _getMealsPerDay(persona, mealDate);

      for (int mealIndex = 0; mealIndex < mealsPerDay; mealIndex++) {
        final meal = _generateMealLog(
          persona,
          mealDate,
          mealIndex,
          mealsPerDay,
        );
        meal['userId'] = userId;

              final mealRef = _firestore
          .collection('meal_logs')
            .doc('${userId}_${mealDate.millisecondsSinceEpoch}_$mealIndex');

        batch.set(mealRef, meal);
      }
    }

    await batch.commit();
    Logger.d('✅ Meal logs generated for ${persona.displayName}');
  }

  /// Get number of meals per day based on persona and fasting schedule
  static int _getMealsPerDay(DemoPersona persona, DateTime date) {
    final fastingType = persona.healthProfile['fastingType'] as String;
    final weekday = date.weekday;

    switch (fastingType) {
      case '16:8':
        return 2; // Lunch and dinner
      case '14:10':
        return 3; // Breakfast, lunch, dinner
      case '5:2':
        // Tuesday/Thursday are fasting days (500 cal), others normal
        if (weekday == 2 || weekday == 4) {
          return 2; // Light meals only
        }
        return 3; // Normal eating days
      default:
        return 3;
    }
  }

  /// Generate a realistic meal log entry
  static Map<String, dynamic> _generateMealLog(
    DemoPersona persona,
    DateTime date,
    int mealIndex,
    int totalMeals,
  ) {
    final mealType = _getMealType(mealIndex, totalMeals, persona);
    final mealData = _generateMealData(persona, mealType, date);

    return {
      'userId': '', // Will be set by caller
      'date': Timestamp.fromDate(date),
      'mealType': mealType,
      'timestamp': Timestamp.fromDate(
        date.add(Duration(hours: _getMealHour(mealType, persona))),
      ),
      'isDemo': true,
      'createdAt': Timestamp.fromDate(date),
      ...mealData,
    };
  }

  /// Get meal type based on index and persona
  static String _getMealType(
    int mealIndex,
    int totalMeals,
    DemoPersona persona,
  ) {
    if (totalMeals == 2) {
      return mealIndex == 0 ? 'lunch' : 'dinner';
    } else if (totalMeals == 3) {
      switch (mealIndex) {
        case 0:
          return 'breakfast';
        case 1:
          return 'lunch';
        case 2:
          return 'dinner';
        default:
          return 'snack';
      }
    }
    return 'meal';
  }

  /// Get typical hour for meal type based on persona
  static int _getMealHour(String mealType, DemoPersona persona) {
    final fastingType = persona.healthProfile['fastingType'] as String;

    switch (mealType) {
      case 'breakfast':
        return fastingType == '14:10' ? 10 : 8;
      case 'lunch':
        return fastingType == '16:8' ? 12 : 13;
      case 'dinner':
        return 19;
      case 'snack':
        return 15;
      default:
        return 12;
    }
  }

  /// Generate comprehensive meal data with AI captions
  static Map<String, dynamic> _generateMealData(
    DemoPersona persona,
    String mealType,
    DateTime date,
  ) {
    final mealOptions = _getMealOptions(persona, mealType);
    final selectedMeal = mealOptions[_random.nextInt(mealOptions.length)];

    return {
      'foodName': selectedMeal['name'],
      'description': selectedMeal['description'],
      'aiCaption': _generateAICaption(selectedMeal, persona),
      'nutrition': _generateNutritionData(selectedMeal, persona),
      'imageUrl': _generateImageUrl(selectedMeal['name']),
      'confidence': _generateAIConfidence(persona),
      'tags': selectedMeal['tags'],
      'portion': selectedMeal['portion'],
      'preparationMethod': selectedMeal['preparation'],
      'satisfactionRating': _getSatisfactionRating(persona, selectedMeal),
      'notes': _getMealNotes(persona, selectedMeal),
      'location': _getMealLocation(persona),
      'socialContext': _getSocialContext(persona, mealType),
    };
  }

  /// Get meal options for persona and meal type
  static List<Map<String, dynamic>> _getMealOptions(
    DemoPersona persona,
    String mealType,
  ) {
    final dietaryRestrictions =
        persona.healthProfile['dietaryRestrictions'] as List;
    final isVegetarian = dietaryRestrictions.contains('vegetarian');

    switch (mealType) {
      case 'breakfast':
        return _getBreakfastOptions(persona, isVegetarian);
      case 'lunch':
        return _getLunchOptions(persona, isVegetarian);
      case 'dinner':
        return _getDinnerOptions(persona, isVegetarian);
      case 'snack':
        return _getSnackOptions(persona, isVegetarian);
      default:
        return _getLunchOptions(persona, isVegetarian);
    }
  }

  /// Get breakfast options
  static List<Map<String, dynamic>> _getBreakfastOptions(
    DemoPersona persona,
    bool isVegetarian,
  ) {
    final options = [
      {
        'name': 'Avocado Toast',
        'description':
            'Whole grain bread with mashed avocado, cherry tomatoes, and hemp seeds',
        'calories': 320,
        'protein': 12,
        'carbs': 35,
        'fat': 18,
        'fiber': 12,
        'tags': ['healthy', 'vegetarian', 'high_fiber'],
        'portion': '2 slices',
        'preparation': 'fresh',
      },
      {
        'name': 'Greek Yogurt Bowl',
        'description':
            'Plain Greek yogurt with mixed berries, granola, and honey',
        'calories': 280,
        'protein': 20,
        'carbs': 35,
        'fat': 8,
        'fiber': 6,
        'tags': ['protein_rich', 'probiotic', 'antioxidants'],
        'portion': '1 cup',
        'preparation': 'assembled',
      },
      {
        'name': 'Veggie Scramble',
        'description':
            'Scrambled eggs with spinach, bell peppers, and mushrooms',
        'calories': 250,
        'protein': 18,
        'carbs': 8,
        'fat': 16,
        'fiber': 3,
        'tags': ['protein_rich', 'vegetarian', 'low_carb'],
        'portion': '2 eggs + vegetables',
        'preparation': 'cooked',
      },
    ];

    if (!isVegetarian) {
      options.addAll([
        {
          'name': 'Protein Smoothie',
          'description':
              'Whey protein, banana, spinach, almond milk, and peanut butter',
          'calories': 350,
          'protein': 25,
          'carbs': 30,
          'fat': 12,
          'fiber': 5,
          'tags': ['protein_rich', 'post_workout', 'nutrient_dense'],
          'portion': '16 oz',
          'preparation': 'blended',
        },
      ]);
    }

    return options;
  }

  /// Get lunch options
  static List<Map<String, dynamic>> _getLunchOptions(
    DemoPersona persona,
    bool isVegetarian,
  ) {
    final options = [
      {
        'name': 'Quinoa Buddha Bowl',
        'description':
            'Quinoa with roasted vegetables, chickpeas, and tahini dressing',
        'calories': 420,
        'protein': 16,
        'carbs': 55,
        'fat': 14,
        'fiber': 12,
        'tags': ['complete_protein', 'vegetarian', 'nutrient_dense'],
        'portion': '1 large bowl',
        'preparation': 'assembled',
      },
      {
        'name': 'Mediterranean Salad',
        'description':
            'Mixed greens, cucumber, tomatoes, olives, feta, and olive oil',
        'calories': 280,
        'protein': 12,
        'carbs': 15,
        'fat': 22,
        'fiber': 8,
        'tags': ['mediterranean', 'fresh', 'healthy_fats'],
        'portion': '1 large salad',
        'preparation': 'fresh',
      },
      {
        'name': 'Lentil Soup',
        'description': 'Red lentil soup with vegetables and aromatic spices',
        'calories': 300,
        'protein': 18,
        'carbs': 45,
        'fat': 6,
        'fiber': 15,
        'tags': ['plant_protein', 'fiber_rich', 'warming'],
        'portion': '1.5 cups',
        'preparation': 'cooked',
      },
    ];

    if (!isVegetarian) {
      options.addAll([
        {
          'name': 'Grilled Chicken Salad',
          'description':
              'Grilled chicken breast over mixed greens with balsamic vinaigrette',
          'calories': 380,
          'protein': 35,
          'carbs': 12,
          'fat': 18,
          'fiber': 6,
          'tags': ['high_protein', 'lean_meat', 'low_carb'],
          'portion': '6 oz chicken + salad',
          'preparation': 'grilled',
        },
        {
          'name': 'Salmon Bowl',
          'description': 'Baked salmon with brown rice and steamed broccoli',
          'calories': 450,
          'protein': 32,
          'carbs': 35,
          'fat': 20,
          'fiber': 8,
          'tags': ['omega_3', 'complete_meal', 'brain_food'],
          'portion': '5 oz salmon + sides',
          'preparation': 'baked',
        },
      ]);
    }

    return options;
  }

  /// Get dinner options
  static List<Map<String, dynamic>> _getDinnerOptions(
    DemoPersona persona,
    bool isVegetarian,
  ) {
    final options = [
      {
        'name': 'Stuffed Bell Peppers',
        'description':
            'Bell peppers stuffed with quinoa, black beans, and vegetables',
        'calories': 350,
        'protein': 14,
        'carbs': 50,
        'fat': 10,
        'fiber': 12,
        'tags': ['vegetarian', 'fiber_rich', 'colorful'],
        'portion': '2 peppers',
        'preparation': 'baked',
      },
      {
        'name': 'Vegetable Stir Fry',
        'description': 'Mixed vegetables stir-fried with tofu and brown rice',
        'calories': 380,
        'protein': 18,
        'carbs': 45,
        'fat': 14,
        'fiber': 10,
        'tags': ['plant_protein', 'asian_inspired', 'quick_cook'],
        'portion': '1.5 cups',
        'preparation': 'stir_fried',
      },
    ];

    if (!isVegetarian) {
      options.addAll([
        {
          'name': 'Herb-Crusted Chicken',
          'description':
              'Baked chicken thigh with herbs, sweet potato, and green beans',
          'calories': 480,
          'protein': 38,
          'carbs': 35,
          'fat': 20,
          'fiber': 8,
          'tags': ['complete_meal', 'comfort_food', 'balanced'],
          'portion': '6 oz chicken + sides',
          'preparation': 'baked',
        },
        {
          'name': 'Fish Tacos',
          'description':
              'Grilled white fish in corn tortillas with cabbage slaw',
          'calories': 420,
          'protein': 28,
          'carbs': 40,
          'fat': 16,
          'fiber': 6,
          'tags': ['mexican_inspired', 'lean_protein', 'fresh'],
          'portion': '3 tacos',
          'preparation': 'grilled',
        },
      ]);
    }

    return options;
  }

  /// Get snack options
  static List<Map<String, dynamic>> _getSnackOptions(
    DemoPersona persona,
    bool isVegetarian,
  ) {
    return [
      {
        'name': 'Apple with Almond Butter',
        'description': 'Sliced apple with natural almond butter',
        'calories': 180,
        'protein': 6,
        'carbs': 20,
        'fat': 10,
        'fiber': 5,
        'tags': ['healthy_fats', 'natural', 'satisfying'],
        'portion': '1 medium apple + 1 tbsp',
        'preparation': 'fresh',
      },
      {
        'name': 'Mixed Nuts',
        'description': 'Raw almonds, walnuts, and cashews',
        'calories': 160,
        'protein': 6,
        'carbs': 6,
        'fat': 14,
        'fiber': 3,
        'tags': ['healthy_fats', 'portable', 'brain_food'],
        'portion': '1 oz',
        'preparation': 'raw',
      },
      {
        'name': 'Hummus and Vegetables',
        'description': 'Homemade hummus with carrot and cucumber sticks',
        'calories': 120,
        'protein': 5,
        'carbs': 12,
        'fat': 6,
        'fiber': 4,
        'tags': ['plant_protein', 'crunchy', 'mediterranean'],
        'portion': '2 tbsp hummus + veggies',
        'preparation': 'fresh',
      },
    ];
  }

  /// Generate AI caption for meal recognition
  static String _generateAICaption(
    Map<String, dynamic> meal,
    DemoPersona persona,
  ) {
    final foodName = meal['name'] as String;
    final description = meal['description'] as String;
    final tags = meal['tags'] as List<String>;

    final captions = [
      'I can see this is $foodName! $description. This looks like a ${tags.contains('healthy') ? 'nutritious' : 'delicious'} choice.',
      'Great choice! This $foodName contains approximately ${meal['calories']} calories and ${meal['protein']}g of protein.',
      'I recognize this as $foodName. ${_getAIHealthComment(meal, persona)}',
      'This $foodName looks perfectly prepared! ${_getAINutritionInsight(meal)}',
    ];

    return captions[_random.nextInt(captions.length)];
  }

  /// Generate AI health comment based on persona goals
  static String _getAIHealthComment(
    Map<String, dynamic> meal,
    DemoPersona persona,
  ) {
    final goals = persona.healthProfile['goals'] as List;
    final tags = meal['tags'] as List<String>;

    if (goals.contains('weight_loss') && tags.contains('low_carb')) {
      return 'This aligns well with your weight loss goals - low in carbs and satisfying!';
    } else if (goals.contains('muscle_gain') && tags.contains('protein_rich')) {
      return 'Perfect for muscle building with its high protein content!';
    } else if (goals.contains('health') && tags.contains('nutrient_dense')) {
      return 'Excellent choice for overall health - packed with nutrients!';
    }

    return 'This fits nicely into your balanced eating plan.';
  }

  /// Generate AI nutrition insight
  static String _getAINutritionInsight(Map<String, dynamic> meal) {
    final protein = meal['protein'] as int;
    final fiber = meal['fiber'] as int;

    if (protein > 20) {
      return 'High in protein to help keep you satisfied longer.';
    } else if (fiber > 8) {
      return 'Rich in fiber for digestive health and satiety.';
    } else {
      return 'A well-balanced meal with good nutritional variety.';
    }
  }

  /// Generate nutrition data
  static Map<String, dynamic> _generateNutritionData(
    Map<String, dynamic> meal,
    DemoPersona persona,
  ) {
    return {
      'calories': meal['calories'],
      'macros': {
        'protein': meal['protein'],
        'carbs': meal['carbs'],
        'fat': meal['fat'],
        'fiber': meal['fiber'],
      },
      'micronutrients': _generateMicronutrients(meal),
      'glycemicIndex': _estimateGlycemicIndex(meal),
      'nutritionScore': _calculateNutritionScore(meal),
    };
  }

  /// Generate micronutrients based on meal
  static Map<String, dynamic> _generateMicronutrients(
    Map<String, dynamic> meal,
  ) {
    final tags = meal['tags'] as List<String>;
    final micronutrients = <String, dynamic>{};

    if (tags.contains('antioxidants')) {
      micronutrients['vitaminC'] = 'high';
      micronutrients['vitaminE'] = 'moderate';
    }
    if (tags.contains('omega_3')) {
      micronutrients['omega3'] = 'high';
    }
    if (tags.contains('brain_food')) {
      micronutrients['vitaminB12'] = 'high';
      micronutrients['folate'] = 'moderate';
    }

    return micronutrients;
  }

  /// Estimate glycemic index
  static String _estimateGlycemicIndex(Map<String, dynamic> meal) {
    final carbs = meal['carbs'] as int;
    final fiber = meal['fiber'] as int;

    if (fiber > carbs * 0.3) return 'low';
    if (fiber > carbs * 0.15) return 'moderate';
    return 'moderate-high';
  }

  /// Calculate nutrition score
  static int _calculateNutritionScore(Map<String, dynamic> meal) {
    int score = 50; // Base score

    final tags = meal['tags'] as List<String>;
    if (tags.contains('nutrient_dense')) score += 20;
    if (tags.contains('healthy')) score += 15;
    if (tags.contains('protein_rich')) score += 10;
    if (tags.contains('fiber_rich')) score += 10;

    return score.clamp(0, 100);
  }

  /// Generate image URL (placeholder for demo)
  static String _generateImageUrl(String foodName) {
    final slug = foodName.toLowerCase().replaceAll(' ', '_');
    return 'https://demo.snapameal.com/images/meals/$slug.jpg';
  }

  /// Generate AI confidence score
  static double _generateAIConfidence(DemoPersona persona) {
    // Vary confidence based on meal complexity
    return 0.85 + (_random.nextDouble() * 0.12); // 85-97%
  }

  /// Get satisfaction rating
  static int _getSatisfactionRating(
    DemoPersona persona,
    Map<String, dynamic> meal,
  ) {
    int baseRating = 4; // Generally satisfied

    final tags = meal['tags'] as List<String>;
    final goals = persona.healthProfile['goals'] as List;

    // Boost rating if meal aligns with goals
    if (goals.contains('weight_loss') && tags.contains('low_carb')) {
      baseRating++;
    }
    if (goals.contains('muscle_gain') && tags.contains('protein_rich')) {
      baseRating++;
    }
    if (goals.contains('health') && tags.contains('nutrient_dense')) {
      baseRating++;
    }

    // Add some randomness
    baseRating += _random.nextInt(2) - 1; // ±1

    return baseRating.clamp(1, 5);
  }

  /// Get meal notes
  static String _getMealNotes(DemoPersona persona, Map<String, dynamic> meal) {
    final notes = <String>[];

    switch (persona.id) {
      case 'alice':
        notes.addAll([
          'Perfectly portioned and satisfying',
          'Love how this fits my goals',
          'Feeling energized after this meal',
          'Great flavor combination',
        ]);
        break;
      case 'bob':
        notes.addAll([
          'Tasty and filling',
          'Quick to prepare',
          'Hit the spot',
          'Would eat again',
        ]);
        break;
      case 'charlie':
        notes.addAll([
          'Mindfully enjoyed every bite',
          'Grateful for nourishing food',
          'Felt balanced and satisfied',
          'Prepared with love and intention',
        ]);
        break;
    }

    return notes[_random.nextInt(notes.length)];
  }

  /// Get meal location
  static String _getMealLocation(DemoPersona persona) {
    final locations = ['home', 'office', 'restaurant', 'cafe'];
    final weights = persona.id == 'alice'
        ? [0.7, 0.2, 0.05, 0.05]
        : persona.id == 'bob'
        ? [0.5, 0.3, 0.15, 0.05]
        : [0.8, 0.1, 0.05, 0.05]; // Charlie prefers home

    final random = _random.nextDouble();
    double cumulative = 0.0;

    for (int i = 0; i < weights.length; i++) {
      cumulative += weights[i];
      if (random <= cumulative) {
        return locations[i];
      }
    }

    return 'home';
  }

  /// Get social context
  static String _getSocialContext(DemoPersona persona, String mealType) {
    if (mealType == 'breakfast') return 'alone';

    final contexts = [
      'alone',
      'with_family',
      'with_friends',
      'with_colleagues',
    ];
    final weights = persona.id == 'alice'
        ? [0.6, 0.2, 0.15, 0.05]
        : persona.id == 'bob'
        ? [0.4, 0.3, 0.25, 0.05]
        : [0.7, 0.25, 0.03, 0.02]; // Charlie is more private

    final random = _random.nextDouble();
    double cumulative = 0.0;

    for (int i = 0; i < weights.length; i++) {
      cumulative += weights[i];
      if (random <= cumulative) {
        return contexts[i];
      }
    }

    return 'alone';
  }

  /// Build progress stories with varied engagement levels and retention
  static Future<void> _seedProgressStories(
    String userId,
    DemoPersona persona,
  ) async {
    Logger.d('🔄 Generating progress stories for ${persona.displayName}...');

    final now = DateTime.now();
    final batch = _firestore.batch();

    // Generate 15-20 stories over the past 30 days
    final storyCount = 15 + _random.nextInt(6); // 15-20 stories

    for (int i = 0; i < storyCount; i++) {
      final daysAgo = _random.nextInt(30) + 1; // 1-30 days ago
      final storyDate = now.subtract(Duration(days: daysAgo));

      final story = _generateProgressStory(persona, storyDate, i);
      story['userId'] = userId;

      final storyRef = _firestore
          .collection('${_demoPrefix}progress_stories')
          .doc('${userId}_${storyDate.millisecondsSinceEpoch}_$i');

      batch.set(storyRef, story);
    }

    await batch.commit();
    Logger.d('✅ Progress stories generated for ${persona.displayName}');
  }

  /// Generate a progress story with engagement data
  static Map<String, dynamic> _generateProgressStory(
    DemoPersona persona,
    DateTime date,
    int index,
  ) {
    final storyTypes = [
      'milestone',
      'daily_progress',
      'challenge_completion',
      'meal_highlight',
      'workout_achievement',
    ];
    final storyType = storyTypes[_random.nextInt(storyTypes.length)];

    final baseStory = {
      'userId': '', // Will be set by caller
      'type': storyType,
      'timestamp': Timestamp.fromDate(date),
      'isDemo': true,
      'createdAt': Timestamp.fromDate(date),
      'expiresAt': Timestamp.fromDate(date.add(const Duration(hours: 24))),
      'isVisible': true,
      'viewCount': _generateViewCount(persona),
      'likeCount': _generateLikeCount(persona),
      'commentCount': _generateCommentCount(persona),
      'shareCount': _generateShareCount(persona),
      'engagement': _generateEngagementMetrics(persona),
    };

    switch (storyType) {
      case 'milestone':
        return {...baseStory, ..._generateMilestoneStory(persona, date)};
      case 'daily_progress':
        return {...baseStory, ..._generateDailyProgressStory(persona, date)};
      case 'challenge_completion':
        return {...baseStory, ..._generateChallengeStory(persona, date)};
      case 'meal_highlight':
        return {...baseStory, ..._generateMealHighlightStory(persona, date)};
      case 'workout_achievement':
        return {...baseStory, ..._generateWorkoutStory(persona, date)};
      default:
        return {...baseStory, ..._generateDailyProgressStory(persona, date)};
    }
  }

  /// Generate milestone story content
  static Map<String, dynamic> _generateMilestoneStory(
    DemoPersona persona,
    DateTime date,
  ) {
    final milestones = _getMilestones(persona);
    final milestone = milestones[_random.nextInt(milestones.length)];

    return {
      'title': milestone['title'],
      'description': milestone['description'],
      'achievement': milestone['achievement'],
      'imageUrl':
          'https://demo.snapameal.com/images/milestones/${milestone['image']}',
      'celebrationLevel': milestone['level'], // bronze, silver, gold
      'metadata': {
        'category': 'milestone',
        'difficulty': milestone['difficulty'],
        'timeToAchieve': milestone['timeToAchieve'],
      },
    };
  }

  /// Get milestone options for persona
  static List<Map<String, dynamic>> _getMilestones(DemoPersona persona) {
    final commonMilestones = [
      {
        'title': '7-Day Streak!',
        'description': 'Completed 7 consecutive days of fasting',
        'achievement': 'consistency_week',
        'level': 'bronze',
        'difficulty': 'beginner',
        'timeToAchieve': '1 week',
        'image': 'streak_7.jpg',
      },
      {
        'title': 'First Month Complete',
        'description':
            'Successfully completed your first month of intermittent fasting',
        'achievement': 'first_month',
        'level': 'silver',
        'difficulty': 'intermediate',
        'timeToAchieve': '1 month',
        'image': 'month_complete.jpg',
      },
      {
        'title': 'Nutrition Awareness',
        'description': 'Logged 50 meals with detailed nutrition tracking',
        'achievement': 'nutrition_tracker',
        'level': 'bronze',
        'difficulty': 'beginner',
        'timeToAchieve': '2 weeks',
        'image': 'nutrition_50.jpg',
      },
    ];

    // Add persona-specific milestones
    switch (persona.id) {
      case 'alice':
        commonMilestones.addAll([
          {
            'title': 'Weight Loss Goal',
            'description':
                'Lost 5 pounds through consistent fasting and healthy eating',
            'achievement': 'weight_loss_5lb',
            'level': 'gold',
            'difficulty': 'advanced',
            'timeToAchieve': '6 weeks',
            'image': 'weight_loss.jpg',
          },
          {
            'title': 'Energy Boost',
            'description':
                'Reported increased energy levels for 2 weeks straight',
            'achievement': 'energy_improvement',
            'level': 'silver',
            'difficulty': 'intermediate',
            'timeToAchieve': '2 weeks',
            'image': 'energy_boost.jpg',
          },
        ]);
        break;
      case 'bob':
        commonMilestones.addAll([
          {
            'title': 'Strength Gains',
            'description':
                'Increased workout intensity while maintaining fasting schedule',
            'achievement': 'strength_fasting',
            'level': 'gold',
            'difficulty': 'advanced',
            'timeToAchieve': '4 weeks',
            'image': 'strength_gains.jpg',
          },
          {
            'title': 'Meal Prep Master',
            'description': 'Prepared healthy meals for 2 weeks in advance',
            'achievement': 'meal_prep_pro',
            'level': 'silver',
            'difficulty': 'intermediate',
            'timeToAchieve': '2 weeks',
            'image': 'meal_prep.jpg',
          },
        ]);
        break;
      case 'charlie':
        commonMilestones.addAll([
          {
            'title': 'Mindful Eating',
            'description': 'Practiced mindful eating for 30 consecutive meals',
            'achievement': 'mindful_eating',
            'level': 'gold',
            'difficulty': 'advanced',
            'timeToAchieve': '3 weeks',
            'image': 'mindful_eating.jpg',
          },
          {
            'title': 'Stress Reduction',
            'description':
                'Reported lower stress levels through fasting meditation',
            'achievement': 'stress_relief',
            'level': 'silver',
            'difficulty': 'intermediate',
            'timeToAchieve': '3 weeks',
            'image': 'stress_relief.jpg',
          },
        ]);
        break;
    }

    return commonMilestones;
  }

  /// Generate daily progress story
  static Map<String, dynamic> _generateDailyProgressStory(
    DemoPersona persona,
    DateTime date,
  ) {
    final progressTypes = [
      'fasting_success',
      'energy_level',
      'mood_improvement',
      'sleep_quality',
    ];
    final progressType = progressTypes[_random.nextInt(progressTypes.length)];

    return {
      'title': _getProgressTitle(progressType, persona),
      'description': _getProgressDescription(progressType, persona),
      'progressType': progressType,
      'rating': _random.nextInt(3) + 3, // 3-5 rating
      'imageUrl':
          'https://demo.snapameal.com/images/progress/$progressType.jpg',
      'metadata': {
        'category': 'daily_progress',
        'mood': _getMoodAfterFast(persona, true),
        'energyLevel': _getEnergyLevel(persona, true),
      },
    };
  }

  /// Get progress title based on type
  static String _getProgressTitle(String progressType, DemoPersona persona) {
    switch (progressType) {
      case 'fasting_success':
        return 'Nailed my ${persona.healthProfile['fastingType']} fast today!';
      case 'energy_level':
        return 'Feeling energized and focused';
      case 'mood_improvement':
        return 'Great mood and mental clarity';
      case 'sleep_quality':
        return 'Best sleep in weeks!';
      default:
        return 'Making progress today';
    }
  }

  /// Get progress description
  static String _getProgressDescription(
    String progressType,
    DemoPersona persona,
  ) {
    final descriptions = {
      'fasting_success': [
        'Completed my fast without any cravings. Feeling accomplished!',
        'Another successful fasting day. The routine is becoming natural.',
        'Stayed strong through the hunger waves. So proud of myself!',
      ],
      'energy_level': [
        'My energy levels have been consistently high lately.',
        'No afternoon crash today - fasting is really working!',
        'Feeling more energized than I have in months.',
      ],
      'mood_improvement': [
        'Mental clarity is amazing after fasting.',
        'Feeling positive and motivated about my health journey.',
        'The mood benefits of fasting are incredible.',
      ],
      'sleep_quality': [
        'Slept like a baby last night. Fasting helps so much!',
        'Deep, restful sleep. Woke up feeling refreshed.',
        'Best sleep quality since starting my fasting routine.',
      ],
    };

    final options =
        descriptions[progressType] ?? ['Making good progress today!'];
    return options[_random.nextInt(options.length)];
  }

  /// Generate challenge completion story
  static Map<String, dynamic> _generateChallengeStory(
    DemoPersona persona,
    DateTime date,
  ) {
    final challenges = [
      {
        'name': '7-Day Hydration Challenge',
        'description': 'Drank 8 glasses of water every day for a week',
        'reward': 'Better skin and energy',
        'difficulty': 'easy',
      },
      {
        'name': '14-Day Consistency Challenge',
        'description': 'Completed fasting window every day for 2 weeks',
        'reward': 'Improved discipline and results',
        'difficulty': 'moderate',
      },
      {
        'name': 'Mindful Eating Week',
        'description': 'Practiced mindful eating for every meal this week',
        'reward': 'Better digestion and satisfaction',
        'difficulty': 'moderate',
      },
    ];

    final challenge = challenges[_random.nextInt(challenges.length)];

    return {
      'title': 'Challenge Complete: ${challenge['name']}',
      'description': challenge['description'],
      'challengeName': challenge['name'],
      'reward': challenge['reward'],
      'difficulty': challenge['difficulty'],
      'completionRate': 100,
      'imageUrl':
          'https://demo.snapameal.com/images/challenges/${(challenge['name'] as String).toLowerCase().replaceAll(' ', '_')}.jpg',
      'metadata': {
        'category': 'challenge',
        'type': 'completion',
        'duration': (challenge['name'] as String).contains('7-Day')
            ? '7 days'
            : '14 days',
      },
    };
  }

  /// Generate meal highlight story
  static Map<String, dynamic> _generateMealHighlightStory(
    DemoPersona persona,
    DateTime date,
  ) {
    final highlights = [
      {
        'meal': 'Quinoa Buddha Bowl',
        'reason': 'Perfect macro balance',
        'calories': 420,
        'highlight': 'Felt satisfied for hours!',
      },
      {
        'meal': 'Grilled Salmon',
        'reason': 'Omega-3 powerhouse',
        'calories': 380,
        'highlight': 'Brain food at its finest',
      },
      {
        'meal': 'Mediterranean Salad',
        'reason': 'Fresh and vibrant',
        'calories': 320,
        'highlight': 'So many nutrients in one bowl',
      },
    ];

    final highlight = highlights[_random.nextInt(highlights.length)];

    return {
      'title': 'Meal Highlight: ${highlight['meal']}',
      'description': highlight['highlight'],
      'mealName': highlight['meal'],
      'reason': highlight['reason'],
      'calories': highlight['calories'],
      'imageUrl':
          'https://demo.snapameal.com/images/meals/${(highlight['meal'] as String).toLowerCase().replaceAll(' ', '_')}.jpg',
      'metadata': {
        'category': 'meal',
        'type': 'highlight',
        'nutritionFocus': highlight['reason'],
      },
    };
  }

  /// Generate workout achievement story
  static Map<String, dynamic> _generateWorkoutStory(
    DemoPersona persona,
    DateTime date,
  ) {
    final workouts = persona.id == 'bob'
        ? [
            {
              'type': 'Strength Training',
              'achievement': 'New personal record on deadlifts',
              'details': 'Lifted 20 lbs more than last month',
              'duration': '45 minutes',
            },
            {
              'type': 'HIIT Session',
              'achievement': 'Completed full workout without breaks',
              'details': 'Endurance is really improving',
              'duration': '30 minutes',
            },
          ]
        : [
            {
              'type': 'Yoga Flow',
              'achievement': 'Held crow pose for 30 seconds',
              'details': 'Balance and strength getting better',
              'duration': '60 minutes',
            },
            {
              'type': 'Morning Walk',
              'achievement': 'Walked 5 miles without fatigue',
              'details': 'Energy levels are amazing',
              'duration': '75 minutes',
            },
          ];

    final workout = workouts[_random.nextInt(workouts.length)];

    return {
      'title': 'Workout Win: ${workout['achievement']}',
      'description': workout['details'],
      'workoutType': workout['type'],
      'achievement': workout['achievement'],
      'duration': workout['duration'],
      'imageUrl':
          'https://demo.snapameal.com/images/workouts/${(workout['type'] as String).toLowerCase().replaceAll(' ', '_')}.jpg',
      'metadata': {
        'category': 'fitness',
        'type': 'achievement',
        'workoutCategory': workout['type'],
      },
    };
  }

  /// Generate view count based on persona social activity
  static int _generateViewCount(DemoPersona persona) {
    final baseViews = persona.id == 'alice'
        ? 25
        : (persona.id == 'bob' ? 15 : 8);
    return baseViews + _random.nextInt(20);
  }

  /// Generate like count
  static int _generateLikeCount(DemoPersona persona) {
    final baseLikes = persona.id == 'alice' ? 8 : (persona.id == 'bob' ? 5 : 3);
    return baseLikes + _random.nextInt(10);
  }

  /// Generate comment count
  static int _generateCommentCount(DemoPersona persona) {
    final baseComments = persona.id == 'alice'
        ? 3
        : (persona.id == 'bob' ? 2 : 1);
    return baseComments + _random.nextInt(5);
  }

  /// Generate share count
  static int _generateShareCount(DemoPersona persona) {
    final baseShares = persona.id == 'alice'
        ? 2
        : (persona.id == 'bob' ? 1 : 0);
    return baseShares + _random.nextInt(3);
  }

  /// Generate engagement metrics
  static Map<String, dynamic> _generateEngagementMetrics(DemoPersona persona) {
    final viewCount = _generateViewCount(persona);
    final likeCount = _generateLikeCount(persona);

    return {
      'engagementRate': ((likeCount / viewCount) * 100).round(),
      'retentionTime': _random.nextInt(15) + 5, // 5-20 seconds
      'completionRate': _random.nextInt(30) + 70, // 70-100%
      'shareToViewRatio': _generateShareCount(persona) / viewCount,
    };
  }

  /// Generate AI advice interaction history showing personalization evolution
  static Future<void> _seedAIAdviceHistory(
    String userId,
    DemoPersona persona,
  ) async {
    Logger.d('🔄 Generating AI advice history for ${persona.displayName}...');

    final now = DateTime.now();
    final batch = _firestore.batch();

    // Generate 15-20 AI advice interactions over 30 days
    final adviceCount = 15 + _random.nextInt(6); // 15-20 interactions

    for (int i = 0; i < adviceCount; i++) {
      final daysAgo = _random.nextInt(30) + 1; // 1-30 days ago
      final adviceDate = now.subtract(Duration(days: daysAgo));

      final advice = _generateAIAdviceInteraction(persona, adviceDate, i);
      advice['userId'] = userId;

      final adviceRef = _firestore
          .collection('${_demoPrefix}ai_advice_history')
          .doc('${userId}_${adviceDate.millisecondsSinceEpoch}_$i');

      batch.set(adviceRef, advice);
    }

    await batch.commit();
    Logger.d('✅ AI advice history generated for ${persona.displayName}');
  }

  /// Generate AI advice interaction with personalization evolution
  static Map<String, dynamic> _generateAIAdviceInteraction(
    DemoPersona persona,
    DateTime date,
    int index,
  ) {
    final adviceTypes = [
      'fasting_guidance',
      'nutrition_tips',
      'motivation',
      'health_insights',
      'goal_adjustment',
    ];
    final adviceType = adviceTypes[_random.nextInt(adviceTypes.length)];

    // Show evolution: earlier advice is more generic, later is more personalized
    final daysSinceStart =
        30 -
        (date
            .difference(DateTime.now().subtract(const Duration(days: 30)))
            .inDays);
    final personalizationLevel = (daysSinceStart / 30 * 100).round().clamp(
      20,
      95,
    );

    return {
      'userId': '', // Will be set by caller
      'type': adviceType,
      'timestamp': Timestamp.fromDate(date),
      'isDemo': true,
      'createdAt': Timestamp.fromDate(date),
      'question': _generateUserQuestion(persona, adviceType),
      'aiResponse': _generateAIResponse(
        persona,
        adviceType,
        personalizationLevel,
      ),
      'personalizationLevel': personalizationLevel,
      'confidence': _generateAIConfidenceScore(personalizationLevel),
      'helpfulnessRating': _generateHelpfulnessRating(
        persona,
        personalizationLevel,
      ),
      'followUpQuestions': _generateFollowUpQuestions(adviceType),
      'sources': _generateAdviceSources(adviceType),
      'metadata': {
        'category': adviceType,
        'personaId': persona.id,
        'evolutionStage': _getEvolutionStage(personalizationLevel),
        'contextData': _generateContextData(persona, date),
      },
    };
  }

  /// Generate user question based on persona and advice type
  static String _generateUserQuestion(DemoPersona persona, String adviceType) {
    final questions = _getQuestionsForPersona(persona, adviceType);
    return questions[_random.nextInt(questions.length)];
  }

  /// Get questions for each persona and advice type
  static List<String> _getQuestionsForPersona(
    DemoPersona persona,
    String adviceType,
  ) {
    final personaQuestions = {
      'alice': {
        'fasting_guidance': [
          'I\'m struggling with afternoon cravings during my 14:10 fast. Any tips?',
          'How can I maintain my energy levels while fasting?',
          'Is it normal to feel dizzy when I first start fasting?',
          'What should I do if I accidentally break my fast early?',
        ],
        'nutrition_tips': [
          'What foods should I prioritize when breaking my fast?',
          'How do I ensure I\'m getting enough protein for weight loss?',
          'Are there foods that help with better sleep?',
          'What\'s the best way to meal prep for my eating window?',
        ],
        'motivation': [
          'I\'m feeling discouraged about my progress. How do I stay motivated?',
          'How do I handle social situations while maintaining my fasting schedule?',
          'What should I do when I feel like giving up?',
          'How can I celebrate small wins along the way?',
        ],
        'health_insights': [
          'How is my fasting affecting my metabolism?',
          'What health markers should I be tracking?',
          'Is intermittent fasting safe for someone with insulin resistance?',
          'How do I know if fasting is working for me?',
        ],
        'goal_adjustment': [
          'Should I adjust my fasting window as I get more experienced?',
          'How do I modify my approach if I hit a weight loss plateau?',
          'When should I consider changing my calorie target?',
          'How do I balance my weight loss and energy goals?',
        ],
      },
      'bob': {
        'fasting_guidance': [
          'Can I still build muscle while doing 16:8 fasting?',
          'What\'s the best time to work out during my fast?',
          'How do I prevent muscle loss during fasting?',
          'Is it okay to have protein powder during my fasting window?',
        ],
        'nutrition_tips': [
          'What should I eat post-workout to maximize gains?',
          'How much protein do I really need for muscle building?',
          'Are there foods that help with recovery?',
          'What\'s the best pre-workout meal timing?',
        ],
        'motivation': [
          'How do I stay consistent with fasting when work gets busy?',
          'What do I do when I don\'t see strength gains?',
          'How do I balance social eating with my goals?',
          'Any tips for staying motivated during tough workouts?',
        ],
        'health_insights': [
          'How does fasting affect my workout performance?',
          'What health benefits am I getting from IF?',
          'Should I track anything besides weight?',
          'How do I know if I\'m eating enough?',
        ],
        'goal_adjustment': [
          'Should I adjust my eating window for better performance?',
          'How do I modify my approach for muscle gain?',
          'When should I consider eating more calories?',
          'How do I balance cutting and bulking with IF?',
        ],
      },
      'charlie': {
        'fasting_guidance': [
          'How can I make my 5:2 fasting more mindful?',
          'What meditation practices work well with fasting?',
          'How do I listen to my body during fasting days?',
          'Is it normal to feel more emotional while fasting?',
        ],
        'nutrition_tips': [
          'What foods support my thyroid health during fasting?',
          'How can I eat more mindfully during my eating days?',
          'What vegetarian proteins work best for me?',
          'How do I handle dairy sensitivity while fasting?',
        ],
        'motivation': [
          'How do I maintain inner peace when fasting gets difficult?',
          'What practices help me stay centered during challenges?',
          'How do I approach setbacks with self-compassion?',
          'What mantras or affirmations help with fasting?',
        ],
        'health_insights': [
          'How is fasting affecting my stress levels?',
          'What connection is there between fasting and mental clarity?',
          'How does IF support my overall wellness goals?',
          'What should I monitor for thyroid health?',
        ],
        'goal_adjustment': [
          'Should I modify my fasting approach for better balance?',
          'How do I adjust my practice as my body changes?',
          'When should I consider a gentler approach?',
          'How do I honor my body\'s changing needs?',
        ],
      },
    };

    return personaQuestions[persona.id]?[adviceType] ??
        ['How can I improve my health journey?'];
  }

  /// Generate AI response with personalization level
  static String _generateAIResponse(
    DemoPersona persona,
    String adviceType,
    int personalizationLevel,
  ) {
    if (personalizationLevel < 40) {
      return _getGenericResponse(adviceType);
    } else if (personalizationLevel < 70) {
      return _getPersonalizedResponse(persona, adviceType);
    } else {
      return _getHighlyPersonalizedResponse(persona, adviceType);
    }
  }

  /// Generate generic AI responses (early stage)
  static String _getGenericResponse(String adviceType) {
    final responses = {
      'fasting_guidance': [
        'Intermittent fasting can be challenging at first. Stay hydrated and keep busy during fasting hours.',
        'It\'s normal to feel hungry initially. Your body will adapt over time.',
        'Consider starting with a shorter fasting window and gradually increasing it.',
      ],
      'nutrition_tips': [
        'Focus on whole foods, lean proteins, and plenty of vegetables.',
        'Stay hydrated and consider taking a multivitamin.',
        'Eat slowly and mindfully when breaking your fast.',
      ],
      'motivation': [
        'Remember your why - focus on your health goals.',
        'Take it one day at a time and celebrate small victories.',
        'Consider finding a support community or accountability partner.',
      ],
      'health_insights': [
        'Intermittent fasting may help with weight management and metabolic health.',
        'Many people report increased energy and mental clarity.',
        'Consult with healthcare providers for personalized medical advice.',
      ],
      'goal_adjustment': [
        'Regularly assess your progress and adjust as needed.',
        'Listen to your body and modify your approach accordingly.',
        'Consider working with a healthcare professional for guidance.',
      ],
    };

    final typeResponses =
        responses[adviceType] ?? ['Here\'s some general health advice.'];
    return typeResponses[_random.nextInt(typeResponses.length)];
  }

  /// Generate personalized responses (mid stage)
  static String _getPersonalizedResponse(
    DemoPersona persona,
    String adviceType,
  ) {
    switch (persona.id) {
      case 'alice':
        return _getAlicePersonalizedResponse(adviceType);
      case 'bob':
        return _getBobPersonalizedResponse(adviceType);
      case 'charlie':
        return _getCharliePersonalizedResponse(adviceType);
      default:
        return _getGenericResponse(adviceType);
    }
  }

  /// Alice-specific personalized responses
  static String _getAlicePersonalizedResponse(String adviceType) {
    final responses = {
      'fasting_guidance': [
        'For your 14:10 schedule, try having herbal tea during afternoon cravings. Your energy levels should stabilize as you adapt.',
        'Since you\'re focused on weight loss, maintaining your 14:10 window consistently will help regulate your insulin response.',
      ],
      'nutrition_tips': [
        'With your weight loss goals, prioritize protein (aim for 25-30g) when breaking your fast to maintain satiety.',
        'Given your insulin resistance history, focus on low-glycemic foods like leafy greens and lean proteins.',
      ],
      'motivation': [
        'Your consistency with tracking is impressive! Remember that sustainable weight loss takes time.',
        'You\'ve shown great discipline with your eating window - that\'s a huge accomplishment.',
      ],
      'health_insights': [
        'Your energy improvements suggest your metabolism is adapting well to the 14:10 schedule.',
        'The sleep quality improvements you\'ve mentioned are a great sign of hormonal balance.',
      ],
      'goal_adjustment': [
        'Consider extending to 15:9 if you\'re comfortable - it might help accelerate your weight loss.',
        'Your current approach is working well. Small adjustments might optimize your energy levels.',
      ],
    };

    final typeResponses =
        responses[adviceType] ??
        ['Keep up the great work with your health journey!'];
    return typeResponses[_random.nextInt(typeResponses.length)];
  }

  /// Bob-specific personalized responses
  static String _getBobPersonalizedResponse(String adviceType) {
    final responses = {
      'fasting_guidance': [
        'For muscle building with 16:8, time your workouts 1-2 hours before breaking your fast for optimal recovery.',
        'Your strength training schedule works well with IF. Consider BCAAs if you\'re working out fasted.',
      ],
      'nutrition_tips': [
        'With your muscle gain goals, aim for 1.6-2.2g protein per kg body weight spread across your eating window.',
        'Post-workout nutrition is crucial - prioritize protein and carbs within your eating window.',
      ],
      'motivation': [
        'Your workout consistency while fasting shows great dedication. Results will come with time.',
        'Balancing strength training with IF requires patience - you\'re doing great.',
      ],
      'health_insights': [
        'Your stable energy during workouts suggests you\'re well-adapted to fasted training.',
        'The strength gains you\'ve maintained show IF isn\'t hindering your muscle building.',
      ],
      'goal_adjustment': [
        'Consider adjusting your eating window timing around your workout schedule for optimal results.',
        'Your current 16:8 approach supports both muscle gain and metabolic health.',
      ],
    };

    final typeResponses =
        responses[adviceType] ??
        ['Your strength-focused approach to IF is impressive!'];
    return typeResponses[_random.nextInt(typeResponses.length)];
  }

  /// Charlie-specific personalized responses
  static String _getCharliePersonalizedResponse(String adviceType) {
    final responses = {
      'fasting_guidance': [
        'Your 5:2 approach aligns beautifully with mindful eating. Use fasting days for deeper self-reflection.',
        'With your thyroid condition, monitor how fasting affects your energy and adjust gently as needed.',
      ],
      'nutrition_tips': [
        'Your vegetarian approach provides excellent fiber. Focus on iron-rich foods to support your thyroid.',
        'Mindful eating practices during your normal days will enhance the benefits of your 5:2 schedule.',
      ],
      'motivation': [
        'Your mindful approach to fasting is inspiring. Trust your body\'s wisdom throughout this journey.',
        'The stress reduction you\'ve experienced shows the mind-body connection is strengthening.',
      ],
      'health_insights': [
        'Your improved mental clarity suggests fasting is supporting your overall nervous system health.',
        'The stress level improvements align with research on fasting\'s effects on cortisol regulation.',
      ],
      'goal_adjustment': [
        'Your gentle, mindful approach is perfect. Consider seasonal adjustments to honor your body\'s needs.',
        'Listen to your thyroid function - adjust fasting intensity based on your energy levels.',
      ],
    };

    final typeResponses =
        responses[adviceType] ??
        ['Your mindful approach to health is truly inspiring!'];
    return typeResponses[_random.nextInt(typeResponses.length)];
  }

  /// Generate highly personalized responses (advanced stage)
  static String _getHighlyPersonalizedResponse(
    DemoPersona persona,
    String adviceType,
  ) {
    // These would incorporate specific data points from the user's history
    switch (persona.id) {
      case 'alice':
        return 'Based on your 3-week consistency with 14:10 fasting and your recent energy improvements, I recommend optimizing your pre-fast meal timing. Your data shows better sleep quality when you finish eating by 7 PM rather than 8 PM. This aligns with your goal of losing another 5 pounds while maintaining energy for your freelance work schedule.';
      case 'bob':
        return 'Your workout performance data shows you\'re strongest during afternoon sessions within your eating window. Given your recent strength gains (15% increase in deadlift over 4 weeks), consider timing your largest meal post-workout. Your protein intake of 140g daily is optimal for your current muscle-building phase with IF.';
      case 'charlie':
        return 'Your mindfulness practice has beautifully complemented your 5:2 fasting routine. The stress reduction you\'ve experienced (based on your mood tracking) suggests your cortisol patterns are optimizing. Consider incorporating gentle movement on fasting days to support your thyroid function while honoring your body\'s wisdom.';
      default:
        return _getPersonalizedResponse(persona, adviceType);
    }
  }

  /// Generate AI confidence score
  static double _generateAIConfidenceScore(int personalizationLevel) {
    return (personalizationLevel / 100 * 0.4 + 0.6); // 60-100% confidence
  }

  /// Generate helpfulness rating from user
  static int _generateHelpfulnessRating(
    DemoPersona persona,
    int personalizationLevel,
  ) {
    int baseRating = (personalizationLevel / 20)
        .round(); // 1-5 based on personalization

    // Add persona-specific tendencies
    switch (persona.id) {
      case 'alice':
        baseRating += _random.nextBool() ? 1 : 0; // Alice tends to rate higher
        break;
      case 'bob':
        baseRating += _random.nextInt(2) - 1; // Bob is more variable
        break;
      case 'charlie':
        baseRating += _random.nextBool()
            ? 0
            : 1; // Charlie is thoughtful but positive
        break;
    }

    return baseRating.clamp(1, 5);
  }

  /// Generate follow-up questions
  static List<String> _generateFollowUpQuestions(String adviceType) {
    final followUps = {
      'fasting_guidance': [
        'Would you like specific meal timing recommendations?',
        'Are you interested in learning about different fasting approaches?',
        'Would you like tips for managing hunger during fasting?',
      ],
      'nutrition_tips': [
        'Would you like personalized meal suggestions?',
        'Are you interested in supplement recommendations?',
        'Would you like macro tracking guidance?',
      ],
      'motivation': [
        'Would you like to set up progress milestones?',
        'Are you interested in finding accountability partners?',
        'Would you like motivational reminders?',
      ],
      'health_insights': [
        'Would you like to track additional health metrics?',
        'Are you interested in learning about the science behind IF?',
        'Would you like personalized health recommendations?',
      ],
      'goal_adjustment': [
        'Would you like to reassess your current goals?',
        'Are you interested in exploring new approaches?',
        'Would you like to adjust your tracking methods?',
      ],
    };

    return followUps[adviceType] ??
        ['Would you like more information on this topic?'];
  }

  /// Generate advice sources
  static List<String> _generateAdviceSources(String adviceType) {
    return [
      'Peer-reviewed nutrition research',
      'Clinical studies on intermittent fasting',
      'Evidence-based health guidelines',
      'Registered dietitian recommendations',
      'Your personal health data trends',
    ];
  }

  /// Get evolution stage description
  static String _getEvolutionStage(int personalizationLevel) {
    if (personalizationLevel < 40) return 'learning';
    if (personalizationLevel < 70) return 'adapting';
    return 'personalized';
  }

  /// Generate context data for AI personalization
  static Map<String, dynamic> _generateContextData(
    DemoPersona persona,
    DateTime date,
  ) {
    final daysSinceStart = DateTime.now().difference(date).inDays;

    return {
      'daysSinceStart': daysSinceStart,
      'recentFastingSuccess': _random.nextBool(),
      'energyTrend': daysSinceStart > 14 ? 'improving' : 'adapting',
      'consistencyScore': (daysSinceStart * 3).clamp(0, 100),
      'goalProgress': '${(daysSinceStart * 2).clamp(0, 100)}%',
    };
  }

  /// Populate health challenges and streak data between users
  static Future<void> _seedHealthChallenges(
    String userId,
    DemoPersona persona,
  ) async {
    Logger.d('🔄 Generating health challenges for ${persona.displayName}...');

    final now = DateTime.now();
    final batch = _firestore.batch();

    // Generate 5-8 challenges over the past 30 days
    final challengeCount = 5 + _random.nextInt(4); // 5-8 challenges

    for (int i = 0; i < challengeCount; i++) {
      final challenge = _generateHealthChallenge(persona, now, i);
      challenge['userId'] = userId;

      final challengeRef = _firestore
          .collection('${_demoPrefix}health_challenges')
          .doc('${userId}_challenge_$i');

      batch.set(challengeRef, challenge);
    }

    // Generate streak data
    await _generateStreakData(userId, persona, batch);

    await batch.commit();
    Logger.d('✅ Health challenges generated for ${persona.displayName}');
  }

  /// Generate a health challenge
  static Map<String, dynamic> _generateHealthChallenge(
    DemoPersona persona,
    DateTime now,
    int index,
  ) {
    final challenges = _getChallengesForPersona(persona);
    final challenge = challenges[_random.nextInt(challenges.length)];

    final startDate = now.subtract(Duration(days: _random.nextInt(25) + 5));
    final duration = challenge['duration'] as int;
    final endDate = startDate.add(Duration(days: duration));

    final isCompleted = now.isAfter(endDate);
    final progress = isCompleted
        ? 100
        : _generateChallengeProgress(persona, now, startDate, duration);

    return {
      'userId': '', // Will be set by caller
      'challengeId': 'challenge_${challenge['id']}_$index',
      'name': challenge['name'],
      'description': challenge['description'],
      'type': challenge['type'],
      'difficulty': challenge['difficulty'],
      'duration': duration,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isCompleted': isCompleted,
      'progress': progress,
      'participants': _generateChallengeParticipants(persona),
      'rewards': challenge['rewards'],
      'milestones': challenge['milestones'],
      'isDemo': true,
      'createdAt': Timestamp.fromDate(startDate),
      'metadata': {
        'category': challenge['category'],
        'personalizedFor': persona.id,
        'difficultyScore': challenge['difficultyScore'],
      },
    };
  }

  /// Get challenges for each persona
  static List<Map<String, dynamic>> _getChallengesForPersona(
    DemoPersona persona,
  ) {
    final commonChallenges = [
      {
        'id': 'hydration_7day',
        'name': '7-Day Hydration Challenge',
        'description': 'Drink your daily water goal every day for a week',
        'type': 'hydration',
        'category': 'wellness',
        'difficulty': 'easy',
        'difficultyScore': 2,
        'duration': 7,
        'rewards': ['Better skin', 'Increased energy', 'Improved digestion'],
        'milestones': [
          {'day': 3, 'reward': 'Hydration streak badge'},
          {'day': 7, 'reward': 'Hydration master badge'},
        ],
      },
      {
        'id': 'consistency_14day',
        'name': '14-Day Consistency Challenge',
        'description': 'Stick to your fasting window every day for 2 weeks',
        'type': 'fasting',
        'category': 'discipline',
        'difficulty': 'moderate',
        'difficultyScore': 4,
        'duration': 14,
        'rewards': ['Improved discipline', 'Better results', 'Habit formation'],
        'milestones': [
          {'day': 7, 'reward': 'Week warrior badge'},
          {'day': 14, 'reward': 'Consistency champion badge'},
        ],
      },
      {
        'id': 'mindful_eating',
        'name': 'Mindful Eating Week',
        'description': 'Practice mindful eating for every meal this week',
        'type': 'mindfulness',
        'category': 'mental_health',
        'difficulty': 'moderate',
        'difficultyScore': 3,
        'duration': 7,
        'rewards': [
          'Better digestion',
          'Increased satisfaction',
          'Food awareness',
        ],
        'milestones': [
          {'day': 3, 'reward': 'Mindfulness novice badge'},
          {'day': 7, 'reward': 'Mindful eater badge'},
        ],
      },
    ];

    // Add persona-specific challenges
    switch (persona.id) {
      case 'alice':
        commonChallenges.addAll([
          {
            'id': 'weight_loss_sprint',
            'name': '21-Day Weight Loss Sprint',
            'description': 'Combine IF with daily walks and meal tracking',
            'type': 'weight_loss',
            'category': 'fitness',
            'difficulty': 'challenging',
            'difficultyScore': 5,
            'duration': 21,
            'rewards': [
              'Visible results',
              'Increased confidence',
              'Habit stack',
            ],
            'milestones': [
              {'day': 7, 'reward': 'First week champion'},
              {'day': 14, 'reward': 'Halfway hero'},
              {'day': 21, 'reward': 'Sprint superstar'},
            ],
          },
          {
            'id': 'energy_optimization',
            'name': 'Energy Optimization Challenge',
            'description':
                'Track energy levels and optimize meal timing for 10 days',
            'type': 'energy',
            'category': 'optimization',
            'difficulty': 'moderate',
            'difficultyScore': 3,
            'duration': 10,
            'rewards': [
              'Better energy',
              'Optimized schedule',
              'Productivity boost',
            ],
            'milestones': [
              {'day': 5, 'reward': 'Energy tracker badge'},
              {'day': 10, 'reward': 'Energy optimizer badge'},
            ],
          },
        ]);
        break;

      case 'bob':
        commonChallenges.addAll([
          {
            'id': 'strength_fasting',
            'name': 'Strength & Fasting Challenge',
            'description':
                'Maintain workout intensity while following IF for 2 weeks',
            'type': 'fitness',
            'category': 'strength',
            'difficulty': 'challenging',
            'difficultyScore': 5,
            'duration': 14,
            'rewards': [
              'Improved performance',
              'Better recovery',
              'Discipline',
            ],
            'milestones': [
              {'day': 7, 'reward': 'Fasted warrior badge'},
              {'day': 14, 'reward': 'Strength master badge'},
            ],
          },
          {
            'id': 'protein_power',
            'name': 'Protein Power Week',
            'description':
                'Hit protein targets every day for optimal muscle building',
            'type': 'nutrition',
            'category': 'muscle_building',
            'difficulty': 'moderate',
            'difficultyScore': 3,
            'duration': 7,
            'rewards': [
              'Better gains',
              'Nutrition awareness',
              'Meal planning skills',
            ],
            'milestones': [
              {'day': 3, 'reward': 'Protein tracker badge'},
              {'day': 7, 'reward': 'Protein pro badge'},
            ],
          },
        ]);
        break;

      case 'charlie':
        commonChallenges.addAll([
          {
            'id': 'mindful_movement',
            'name': 'Mindful Movement Challenge',
            'description':
                'Practice gentle movement and meditation daily for 2 weeks',
            'type': 'mindfulness',
            'category': 'mental_health',
            'difficulty': 'easy',
            'difficultyScore': 2,
            'duration': 14,
            'rewards': [
              'Inner peace',
              'Better flexibility',
              'Stress reduction',
            ],
            'milestones': [
              {'day': 7, 'reward': 'Mindful mover badge'},
              {'day': 14, 'reward': 'Zen master badge'},
            ],
          },
          {
            'id': 'stress_reduction',
            'name': 'Stress Reduction Sprint',
            'description':
                'Practice stress-reduction techniques alongside gentle fasting',
            'type': 'stress_management',
            'category': 'mental_health',
            'difficulty': 'moderate',
            'difficultyScore': 3,
            'duration': 10,
            'rewards': ['Lower stress', 'Better sleep', 'Emotional balance'],
            'milestones': [
              {'day': 5, 'reward': 'Stress buster badge'},
              {'day': 10, 'reward': 'Calm champion badge'},
            ],
          },
        ]);
        break;
    }

    return commonChallenges;
  }

  /// Generate challenge progress based on persona and timing
  static int _generateChallengeProgress(
    DemoPersona persona,
    DateTime now,
    DateTime startDate,
    int duration,
  ) {
    final daysSinceStart = now.difference(startDate).inDays;
    final expectedProgress = (daysSinceStart / duration * 100).round();

    // Add persona-specific variation
    int variation = 0;
    switch (persona.id) {
      case 'alice':
        variation =
            _random.nextInt(10) + 5; // Alice tends to exceed expectations
        break;
      case 'bob':
        variation = _random.nextInt(20) - 10; // Bob is more variable
        break;
      case 'charlie':
        variation = _random.nextInt(8) - 2; // Charlie is steady
        break;
    }

    return (expectedProgress + variation).clamp(0, 100);
  }

  /// Generate challenge participants (friends participating)
  static List<String> _generateChallengeParticipants(DemoPersona persona) {
    final allPersonas = ['alice', 'bob', 'charlie'];
    final participants = <String>[persona.id];

    // Add 1-2 other participants randomly
    final otherPersonas = allPersonas.where((p) => p != persona.id).toList();
    final participantCount =
        _random.nextInt(2) + 1; // 1-2 additional participants

    for (int i = 0; i < participantCount && i < otherPersonas.length; i++) {
      participants.add(otherPersonas[i]);
    }

    return participants;
  }

  /// Generate streak data for persona
  static Future<void> _generateStreakData(
    String userId,
    DemoPersona persona,
    WriteBatch batch,
  ) async {
    final streakTypes = ['fasting', 'hydration', 'exercise', 'meal_logging'];

    for (final streakType in streakTypes) {
      final streakData = _generateStreakForType(persona, streakType);
      streakData['userId'] = userId;

      final streakRef = _firestore
          .collection('${_demoPrefix}user_streaks')
          .doc('${userId}_${streakType}_streak');

      batch.set(streakRef, streakData);
    }
  }

  /// Generate streak data for specific type
  static Map<String, dynamic> _generateStreakForType(
    DemoPersona persona,
    String streakType,
  ) {
    final now = DateTime.now();

    // Generate realistic streak lengths based on persona consistency
    int currentStreak = 0;
    int longestStreak = 0;

    switch (persona.id) {
      case 'alice':
        currentStreak = _random.nextInt(15) + 10; // 10-24 days
        longestStreak =
            currentStreak + _random.nextInt(20) + 5; // Longer historical streak
        break;
      case 'bob':
        currentStreak = _random.nextInt(12) + 5; // 5-16 days
        longestStreak = currentStreak + _random.nextInt(15) + 3;
        break;
      case 'charlie':
        currentStreak = _random.nextInt(20) + 8; // 8-27 days (very consistent)
        longestStreak = currentStreak + _random.nextInt(10) + 2;
        break;
    }

    return {
      'userId': '', // Will be set by caller
      'streakType': streakType,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActivityDate': Timestamp.fromDate(
        now.subtract(const Duration(days: 1)),
      ),
      'startDate': Timestamp.fromDate(
        now.subtract(Duration(days: currentStreak)),
      ),
      'isActive': true,
      'milestones': _generateStreakMilestones(currentStreak, longestStreak),
      'isDemo': true,
      'metadata': {
        'personaId': persona.id,
        'streakCategory': streakType,
        'consistencyRating': _getConsistencyRating(persona, currentStreak),
      },
    };
  }

  /// Generate streak milestones
  static List<Map<String, dynamic>> _generateStreakMilestones(
    int currentStreak,
    int longestStreak,
  ) {
    final milestones = <Map<String, dynamic>>[];

    final milestoneTargets = [7, 14, 21, 30, 60, 90];

    for (final target in milestoneTargets) {
      if (longestStreak >= target) {
        milestones.add({
          'target': target,
          'achieved': true,
          'achievedDate': Timestamp.fromDate(
            DateTime.now().subtract(Duration(days: longestStreak - target)),
          ),
          'reward': '$target-day streak badge',
        });
      } else if (currentStreak < target) {
        milestones.add({
          'target': target,
          'achieved': false,
          'progress': (currentStreak / target * 100).round(),
          'reward': '$target-day streak badge',
        });
        break; // Only show next unachieved milestone
      }
    }

    return milestones;
  }

  /// Get consistency rating for persona
  static String _getConsistencyRating(DemoPersona persona, int currentStreak) {
    switch (persona.id) {
      case 'alice':
        return currentStreak > 15
            ? 'excellent'
            : (currentStreak > 10 ? 'very_good' : 'good');
      case 'bob':
        return currentStreak > 12
            ? 'excellent'
            : (currentStreak > 7 ? 'good' : 'improving');
      case 'charlie':
        return currentStreak > 20
            ? 'exceptional'
            : (currentStreak > 15 ? 'excellent' : 'very_good');
      default:
        return 'good';
    }
  }
}
