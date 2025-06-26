import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

/// Anonymous identity for sensitive health sharing
class AnonymousIdentity {
  final String id;
  final String userId;
  final String groupId;
  final String anonymousName;
  final String anonymousAvatar;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;
  final Map<String, dynamic> metadata;

  AnonymousIdentity({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.anonymousName,
    required this.anonymousAvatar,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
    this.metadata = const {},
  });

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'group_id': groupId,
      'anonymous_name': anonymousName,
      'anonymous_avatar': anonymousAvatar,
      'created_at': Timestamp.fromDate(createdAt),
      'expires_at': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'is_active': isActive,
      'metadata': metadata,
    };
  }

  factory AnonymousIdentity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AnonymousIdentity(
      id: doc.id,
      userId: data['user_id'] ?? '',
      groupId: data['group_id'] ?? '',
      anonymousName: data['anonymous_name'] ?? '',
      anonymousAvatar: data['anonymous_avatar'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      expiresAt: data['expires_at'] != null ? (data['expires_at'] as Timestamp).toDate() : null,
      isActive: data['is_active'] ?? true,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

/// Anonymous message for sensitive health discussions
class AnonymousMessage {
  final String id;
  final String groupId;
  final String anonymousId;
  final String content;
  final String category; // 'weight', 'mental-health', 'addiction', 'medical', etc.
  final int sensitivityLevel; // 1-5, higher = more sensitive
  final DateTime timestamp;
  final List<String> supportReactions;
  final bool isModerated;
  final Map<String, dynamic> metadata;

  AnonymousMessage({
    required this.id,
    required this.groupId,
    required this.anonymousId,
    required this.content,
    required this.category,
    required this.sensitivityLevel,
    required this.timestamp,
    this.supportReactions = const [],
    this.isModerated = false,
    this.metadata = const {},
  });

  Map<String, dynamic> toFirestore() {
    return {
      'group_id': groupId,
      'anonymous_id': anonymousId,
      'content': content,
      'category': category,
      'sensitivity_level': sensitivityLevel,
      'timestamp': Timestamp.fromDate(timestamp),
      'support_reactions': supportReactions,
      'is_moderated': isModerated,
      'metadata': metadata,
    };
  }

  factory AnonymousMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AnonymousMessage(
      id: doc.id,
      groupId: data['group_id'] ?? '',
      anonymousId: data['anonymous_id'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? '',
      sensitivityLevel: data['sensitivity_level'] ?? 1,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      supportReactions: List<String>.from(data['support_reactions'] ?? []),
      isModerated: data['is_moderated'] ?? false,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }
}

/// Service for managing anonymous health sharing
class AnonymityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final CollectionReference _anonymousIdentitiesCollection;
  late final CollectionReference _anonymousMessagesCollection;

  // Predefined anonymous names for health contexts
  static const List<String> _healthyAnimalNames = [
    'Peaceful Panda', 'Strong Elephant', 'Swift Cheetah', 'Wise Owl',
    'Brave Lion', 'Gentle Dolphin', 'Resilient Phoenix', 'Calm Turtle',
    'Energetic Hummingbird', 'Steady Mountain Goat', 'Graceful Swan',
    'Determined Eagle', 'Balanced Flamingo', 'Mindful Butterfly',
    'Courageous Bear', 'Flexible Cat', 'Enduring Camel', 'Joyful Otter',
  ];

  static const List<String> _encouragingAdjectives = [
    'Hopeful', 'Brave', 'Strong', 'Peaceful', 'Resilient', 'Gentle',
    'Wise', 'Calm', 'Determined', 'Balanced', 'Mindful', 'Courageous',
    'Flexible', 'Enduring', 'Joyful', 'Radiant', 'Serene', 'Vibrant',
  ];

  static const List<String> _neutralNouns = [
    'Journey', 'Path', 'Star', 'Light', 'Wave', 'Breeze', 'Stone',
    'River', 'Mountain', 'Garden', 'Sunrise', 'Compass', 'Bridge',
    'Anchor', 'Horizon', 'Melody', 'Canvas', 'Sanctuary',
  ];

  AnonymityService() {
    _anonymousIdentitiesCollection = _firestore.collection('anonymous_identities');
    _anonymousMessagesCollection = _firestore.collection('anonymous_messages');
  }

  String? get currentUserId => _auth.currentUser?.uid;

  /// Create or get anonymous identity for a group
  Future<AnonymousIdentity?> getOrCreateAnonymousIdentity(
    String groupId, {
    Duration? expiration,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Check if user already has an active anonymous identity for this group
      final existingQuery = await _anonymousIdentitiesCollection
          .where('user_id', isEqualTo: userId)
          .where('group_id', isEqualTo: groupId)
          .where('is_active', isEqualTo: true)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        final existing = AnonymousIdentity.fromFirestore(existingQuery.docs.first);
        if (!existing.isExpired) {
          return existing;
        } else {
          // Deactivate expired identity
          await _anonymousIdentitiesCollection.doc(existing.id).update({
            'is_active': false,
          });
        }
      }

      // Create new anonymous identity
      final anonymousName = _generateAnonymousName();
      final anonymousAvatar = _generateAnonymousAvatar();
      final now = DateTime.now();

      final identity = AnonymousIdentity(
        id: '',
        userId: userId,
        groupId: groupId,
        anonymousName: anonymousName,
        anonymousAvatar: anonymousAvatar,
        createdAt: now,
        expiresAt: expiration != null ? now.add(expiration) : null,
      );

      final docRef = await _anonymousIdentitiesCollection.add(identity.toFirestore());
      
      return AnonymousIdentity(
        id: docRef.id,
        userId: identity.userId,
        groupId: identity.groupId,
        anonymousName: identity.anonymousName,
        anonymousAvatar: identity.anonymousAvatar,
        createdAt: identity.createdAt,
        expiresAt: identity.expiresAt,
      );
    } catch (e) {
      debugPrint('Error creating anonymous identity: \$e');
      return null;
    }
  }

  /// Post anonymous message to group
  Future<String?> postAnonymousMessage({
    required String groupId,
    required String content,
    required String category,
    int sensitivityLevel = 1,
  }) async {
    try {
      final identity = await getOrCreateAnonymousIdentity(groupId);
      if (identity == null) throw Exception('Could not create anonymous identity');

      final message = AnonymousMessage(
        id: '',
        groupId: groupId,
        anonymousId: identity.id,
        content: content,
        category: category,
        sensitivityLevel: sensitivityLevel,
        timestamp: DateTime.now(),
      );

      final docRef = await _anonymousMessagesCollection.add(message.toFirestore());
      debugPrint('Posted anonymous message: \${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error posting anonymous message: \$e');
      return null;
    }
  }

  /// Get anonymous messages for a group
  Stream<List<AnonymousMessage>> getAnonymousMessages(String groupId) {
    return _anonymousMessagesCollection
        .where('group_id', isEqualTo: groupId)
        .where('is_moderated', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AnonymousMessage.fromFirestore(doc))
            .toList());
  }

  /// Add support reaction to anonymous message
  Future<bool> addSupportReaction(String messageId, String reactionType) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Use anonymous ID instead of user ID for reactions to maintain anonymity
      final identity = await _anonymousIdentitiesCollection
          .where('user_id', isEqualTo: userId)
          .where('is_active', isEqualTo: true)
          .get();

      if (identity.docs.isEmpty) return false;

      final anonymousId = identity.docs.first.id;
      final reactionKey = '\$reactionType:\$anonymousId';

      await _anonymousMessagesCollection.doc(messageId).update({
        'support_reactions': FieldValue.arrayUnion([reactionKey]),
      });

      return true;
    } catch (e) {
      debugPrint('Error adding support reaction: \$e');
      return false;
    }
  }

  /// Get anonymous identity for display (without revealing user)
  Future<Map<String, dynamic>?> getAnonymousDisplayInfo(String anonymousId) async {
    try {
      final doc = await _anonymousIdentitiesCollection.doc(anonymousId).get();
      if (!doc.exists) return null;

      final identity = AnonymousIdentity.fromFirestore(doc);
      
      return {
        'name': identity.anonymousName,
        'avatar': identity.anonymousAvatar,
        'created_at': identity.createdAt,
        'is_active': identity.isActive && !identity.isExpired,
      };
    } catch (e) {
      debugPrint('Error getting anonymous display info: \$e');
      return null;
    }
  }

  /// Check if user can access anonymous features in group
  Future<bool> canAccessAnonymousFeatures(String groupId) async {
    try {
      final userId = currentUserId;
      if (userId == null) return false;

      // Check if group allows anonymous sharing
      final groupDoc = await _firestore.collection('health_groups').doc(groupId).get();
      if (!groupDoc.exists) return false;

      final groupData = groupDoc.data() as Map<String, dynamic>;
      return groupData['allow_anonymous'] == true;
    } catch (e) {
      debugPrint('Error checking anonymous access: \$e');
      return false;
    }
  }

  /// Get sensitive topic categories
  List<Map<String, dynamic>> getSensitiveTopicCategories() {
    return [
      {
        'id': 'weight',
        'name': 'Weight & Body Image',
        'description': 'Struggles with weight, body dysmorphia, eating patterns',
        'icon': '⚖️',
        'sensitivity': 3,
      },
      {
        'id': 'mental-health',
        'name': 'Mental Health',
        'description': 'Depression, anxiety, stress, emotional eating',
        'icon': '🧠',
        'sensitivity': 4,
      },
      {
        'id': 'addiction',
        'name': 'Addiction & Recovery',
        'description': 'Food addiction, substance issues, recovery journey',
        'icon': '🔄',
        'sensitivity': 5,
      },
      {
        'id': 'medical',
        'name': 'Medical Conditions',
        'description': 'Chronic illness, medications, medical challenges',
        'icon': '🏥',
        'sensitivity': 4,
      },
      {
        'id': 'relationships',
        'name': 'Relationships & Support',
        'description': 'Family dynamics, social pressure, relationship with food',
        'icon': '👥',
        'sensitivity': 2,
      },
      {
        'id': 'motivation',
        'name': 'Motivation & Setbacks',
        'description': 'Lack of motivation, relapses, feeling stuck',
        'icon': '💪',
        'sensitivity': 2,
      },
      {
        'id': 'financial',
        'name': 'Financial Challenges',
        'description': 'Cost of healthy food, gym memberships, healthcare',
        'icon': '💰',
        'sensitivity': 3,
      },
    ];
  }

  /// Generate encouraging anonymous name
  String _generateAnonymousName() {
    final random = Random();
    
    // Use different patterns for variety
    final patterns = [
      () => '\${_encouragingAdjectives[random.nextInt(_encouragingAdjectives.length)]} \${_neutralNouns[random.nextInt(_neutralNouns.length)]}',
      () => _healthyAnimalNames[random.nextInt(_healthyAnimalNames.length)],
      () => '\${_encouragingAdjectives[random.nextInt(_encouragingAdjectives.length)]} Warrior',
      () => '\${_neutralNouns[random.nextInt(_neutralNouns.length)]} Seeker',
    ];
    
    return patterns[random.nextInt(patterns.length)]();
  }

  /// Generate anonymous avatar (emoji or color combination)
  String _generateAnonymousAvatar() {
    final random = Random();
    
    // Calming, positive emojis for health contexts
    final avatars = [
      '🌟', '🌸', '🍃', '🌊', '🦋', '🌺', '🌙', '☀️',
      '🌈', '🕊️', '🌿', '🪴', '🌻', '🌷', '🌹', '💫',
      '🔮', '��', '🍀', '🌾', '🐝', '🦋', '🌼', '🌵',
    ];
    
    return avatars[random.nextInt(avatars.length)];
  }

  /// Clean up expired anonymous identities
  Future<void> cleanupExpiredIdentities() async {
    try {
      final now = DateTime.now();
      final expiredQuery = await _anonymousIdentitiesCollection
          .where('expires_at', isLessThan: Timestamp.fromDate(now))
          .where('is_active', isEqualTo: true)
          .get();

      final batch = _firestore.batch();
      for (final doc in expiredQuery.docs) {
        batch.update(doc.reference, {'is_active': false});
      }
      
      await batch.commit();
      debugPrint('Cleaned up \${expiredQuery.docs.length} expired identities');
    } catch (e) {
      debugPrint('Error cleaning up expired identities: \$e');
    }
  }

  /// Get support reaction types
  List<Map<String, dynamic>> getSupportReactionTypes() {
    return [
      {
        'id': 'heart',
        'emoji': '❤️',
        'name': 'Support',
        'description': 'Sending love and support',
      },
      {
        'id': 'strength',
        'emoji': '💪',
        'name': 'Strength',
        'description': 'You are stronger than you know',
      },
      {
        'id': 'hug',
        'emoji': '🤗',
        'name': 'Virtual Hug',
        'description': 'Sending a warm hug',
      },
      {
        'id': 'understand',
        'emoji': '🤝',
        'name': 'I Understand',
        'description': 'I\'ve been there too',
      },
      {
        'id': 'hope',
        'emoji': '🌟',
        'name': 'Hope',
        'description': 'Things will get better',
      },
      {
        'id': 'proud',
        'emoji': '👏',
        'name': 'Proud',
        'description': 'Proud of your courage to share',
      },
    ];
  }
}
