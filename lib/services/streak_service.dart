import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';

/// Types of streaks that can be tracked
enum StreakType {
  fasting,
  workout,
  waterIntake,
  meditation,
  sleepGoal,
  calorieGoal,
  stepGoal,
  custom,
}

/// Individual streak data
class StreakData {
  final String id;
  final String userId;
  final StreakType type;
  final String title;
  final String description;
  final int currentStreak;
  final int bestStreak;
  final DateTime lastUpdated;
  final DateTime startDate;
  final Map<String, dynamic> settings;
  final List<DateTime> completedDates;
  final bool isActive;

  StreakData({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.currentStreak,
    required this.bestStreak,
    required this.lastUpdated,
    required this.startDate,
    required this.settings,
    required this.completedDates,
    this.isActive = true,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'type': type.name,
      'title': title,
      'description': description,
      'current_streak': currentStreak,
      'best_streak': bestStreak,
      'last_updated': Timestamp.fromDate(lastUpdated),
      'start_date': Timestamp.fromDate(startDate),
      'settings': settings,
      'completed_dates': completedDates
          .map((date) => Timestamp.fromDate(date))
          .toList(),
      'is_active': isActive,
    };
  }

  factory StreakData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return StreakData(
      id: doc.id,
      userId: data['user_id'] ?? '',
      type: StreakType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => StreakType.custom,
      ),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      currentStreak: data['current_streak'] ?? 0,
      bestStreak: data['best_streak'] ?? 0,
      lastUpdated: (data['last_updated'] as Timestamp).toDate(),
      startDate: (data['start_date'] as Timestamp).toDate(),
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
      completedDates:
          (data['completed_dates'] as List<dynamic>?)
              ?.map((timestamp) => (timestamp as Timestamp).toDate())
              .toList() ??
          [],
      isActive: data['is_active'] ?? true,
    );
  }

  /// Check if streak was completed today
  bool get isCompletedToday {
    final today = DateTime.now();
    return completedDates.any(
      (date) =>
          date.year == today.year &&
          date.month == today.month &&
          date.day == today.day,
    );
  }

  /// Get streak completion percentage for current week
  double get weeklyCompletionRate {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekDates = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );

    final completedThisWeek = completedDates
        .where(
          (date) => weekDates.any(
            (weekDate) =>
                date.year == weekDate.year &&
                date.month == weekDate.month &&
                date.day == weekDate.day,
          ),
        )
        .length;

    return completedThisWeek / 7.0;
  }
}

/// Shared streak between group members
class SharedStreak {
  final String id;
  final String groupId;
  final String title;
  final String description;
  final StreakType type;
  final List<String> memberIds;
  final Map<String, StreakData> memberStreaks;
  final DateTime startDate;
  final DateTime? endDate;
  final Map<String, dynamic> settings;
  final bool isActive;

  SharedStreak({
    required this.id,
    required this.groupId,
    required this.title,
    required this.description,
    required this.type,
    required this.memberIds,
    required this.memberStreaks,
    required this.startDate,
    this.endDate,
    required this.settings,
    this.isActive = true,
  });

  /// Get average streak across all members
  double get averageStreak {
    if (memberStreaks.isEmpty) return 0.0;
    final total = memberStreaks.values.fold(
      0,
      (acc, streak) => acc + streak.currentStreak,
    );
    return total / memberStreaks.length;
  }

  /// Get member with longest current streak
  StreakData? get topStreaker {
    if (memberStreaks.isEmpty) return null;
    return memberStreaks.values.reduce(
      (a, b) => a.currentStreak > b.currentStreak ? a : b,
    );
  }

  /// Get completion rate for today across all members
  double get todayCompletionRate {
    if (memberStreaks.isEmpty) return 0.0;
    final completedToday = memberStreaks.values
        .where((streak) => streak.isCompletedToday)
        .length;
    return completedToday / memberStreaks.length;
  }
}

/// Service for managing streak tracking and shared challenges
class StreakService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final CollectionReference _streaksCollection;
  late final CollectionReference _sharedStreaksCollection;

  StreakService() {
    _streaksCollection = _firestore.collection('user_streaks');
    _sharedStreaksCollection = _firestore.collection('shared_streaks');
  }

  String? get currentUserId => _auth.currentUser?.uid;

  /// Create a new personal streak
  Future<String?> createStreak({
    required StreakType type,
    required String title,
    required String description,
    Map<String, dynamic> settings = const {},
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final streak = StreakData(
        id: '',
        userId: userId,
        type: type,
        title: title,
        description: description,
        currentStreak: 0,
        bestStreak: 0,
        lastUpdated: DateTime.now(),
        startDate: DateTime.now(),
        settings: settings,
        completedDates: [],
      );

      final docRef = await _streaksCollection.add(streak.toFirestore());
      Logger.d('Created streak: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      Logger.d('Error creating streak: $e');
      return null;
    }
  }

  /// Mark streak as completed for today
  Future<bool> completeStreakToday(String streakId) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final streakDoc = await _streaksCollection.doc(streakId).get();
      if (!streakDoc.exists) throw Exception('Streak not found');

      final streak = StreakData.fromFirestore(streakDoc);

      // Check if already completed today
      if (streak.isCompletedToday) {
        Logger.d('Streak already completed today');
        return true;
      }

      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      // Check if streak should continue or reset
      final wasCompletedYesterday = streak.completedDates.any(
        (date) =>
            date.year == yesterday.year &&
            date.month == yesterday.month &&
            date.day == yesterday.day,
      );

      final newCurrentStreak =
          wasCompletedYesterday || streak.currentStreak == 0
          ? streak.currentStreak + 1
          : 1; // Reset if missed yesterday

      final newBestStreak = newCurrentStreak > streak.bestStreak
          ? newCurrentStreak
          : streak.bestStreak;

      final updatedCompletedDates = [...streak.completedDates, today];

      await _streaksCollection.doc(streakId).update({
        'current_streak': newCurrentStreak,
        'best_streak': newBestStreak,
        'last_updated': Timestamp.now(),
        'completed_dates': updatedCompletedDates
            .map((date) => Timestamp.fromDate(date))
            .toList(),
      });

      Logger.d('Streak completed for today');
      return true;
    } catch (e) {
      Logger.d('Error completing streak: $e');
      return false;
    }
  }

  /// Get user's streaks
  Stream<List<StreakData>> getUserStreaks() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _streaksCollection
        .where('user_id', isEqualTo: userId)
        .where('is_active', isEqualTo: true)
        .orderBy('current_streak', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StreakData.fromFirestore(doc))
              .toList(),
        );
  }

  /// Create a shared streak for a group
  Future<String?> createSharedStreak({
    required String groupId,
    required String title,
    required String description,
    required StreakType type,
    required List<String> memberIds,
    DateTime? endDate,
    Map<String, dynamic> settings = const {},
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Create individual streaks for each member
      final memberStreaks = <String, StreakData>{};
      for (final memberId in memberIds) {
        final streakId = await createStreak(
          type: type,
          title: '$title (Shared)',
          description: description,
          settings: {...settings, 'shared_streak': true, 'group_id': groupId},
        );

        if (streakId != null) {
          final streakDoc = await _streaksCollection.doc(streakId).get();
          memberStreaks[memberId] = StreakData.fromFirestore(streakDoc);
        }
      }

      final sharedStreakData = {
        'group_id': groupId,
        'title': title,
        'description': description,
        'type': type.name,
        'member_ids': memberIds,
        'member_streak_ids': memberStreaks.map(
          (key, value) => MapEntry(key, value.id),
        ),
        'start_date': Timestamp.now(),
        'end_date': endDate != null ? Timestamp.fromDate(endDate) : null,
        'settings': settings,
        'is_active': true,
        'created_by': userId,
      };

      final docRef = await _sharedStreaksCollection.add(sharedStreakData);
      Logger.d('Created shared streak: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      Logger.d('Error creating shared streak: $e');
      return null;
    }
  }

  /// Get shared streaks for a group
  Stream<List<Map<String, dynamic>>> getGroupSharedStreaks(String groupId) {
    return _sharedStreaksCollection
        .where('group_id', isEqualTo: groupId)
        .where('is_active', isEqualTo: true)
        .orderBy('start_date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>},
              )
              .toList(),
        );
  }

  /// Get shared streak details with member progress
  Future<SharedStreak?> getSharedStreakDetails(String sharedStreakId) async {
    try {
      final doc = await _sharedStreaksCollection.doc(sharedStreakId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      final memberStreakIds = Map<String, String>.from(
        data['member_streak_ids'] ?? {},
      );

      // Get individual member streaks
      final memberStreaks = <String, StreakData>{};
      for (final entry in memberStreakIds.entries) {
        final streakDoc = await _streaksCollection.doc(entry.value).get();
        if (streakDoc.exists) {
          memberStreaks[entry.key] = StreakData.fromFirestore(streakDoc);
        }
      }

      return SharedStreak(
        id: doc.id,
        groupId: data['group_id'] ?? '',
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        type: StreakType.values.firstWhere(
          (e) => e.name == data['type'],
          orElse: () => StreakType.custom,
        ),
        memberIds: List<String>.from(data['member_ids'] ?? []),
        memberStreaks: memberStreaks,
        startDate: (data['start_date'] as Timestamp).toDate(),
        endDate: data['end_date'] != null
            ? (data['end_date'] as Timestamp).toDate()
            : null,
        settings: Map<String, dynamic>.from(data['settings'] ?? {}),
        isActive: data['is_active'] ?? true,
      );
    } catch (e) {
      Logger.d('Error getting shared streak details: $e');
      return null;
    }
  }

  /// Get streak leaderboard for a group
  Future<List<Map<String, dynamic>>> getGroupStreakLeaderboard(
    String groupId,
  ) async {
    try {
      final sharedStreaks = await _sharedStreaksCollection
          .where('group_id', isEqualTo: groupId)
          .where('is_active', isEqualTo: true)
          .get();

      final leaderboard = <Map<String, dynamic>>[];

      for (final doc in sharedStreaks.docs) {
        final sharedStreak = await getSharedStreakDetails(doc.id);
        if (sharedStreak != null) {
          for (final entry in sharedStreak.memberStreaks.entries) {
            leaderboard.add({
              'user_id': entry.key,
              'streak_type': sharedStreak.type.name,
              'streak_title': sharedStreak.title,
              'current_streak': entry.value.currentStreak,
              'best_streak': entry.value.bestStreak,
              'completed_today': entry.value.isCompletedToday,
              'weekly_completion': entry.value.weeklyCompletionRate,
            });
          }
        }
      }

      // Sort by current streak descending
      leaderboard.sort(
        (a, b) =>
            (b['current_streak'] as int).compareTo(a['current_streak'] as int),
      );

      return leaderboard;
    } catch (e) {
      Logger.d('Error getting group streak leaderboard: $e');
      return [];
    }
  }

  /// Send motivational message to group based on streak progress
  Future<String?> generateMotivationalMessage(String groupId) async {
    try {
      final leaderboard = await getGroupStreakLeaderboard(groupId);
      if (leaderboard.isEmpty) return null;

      final topStreaker = leaderboard.first;
      final totalMembers = leaderboard.length;
      final completedToday = leaderboard
          .where((member) => member['completed_today'] == true)
          .length;
      final completionRate = completedToday / totalMembers;

      if (completionRate >= 0.8) {
        return '🔥 Amazing! ${(completionRate * 100).round()}% of the group completed their streaks today! Keep up the incredible momentum!';
      } else if (completionRate >= 0.5) {
        return '💪 Good progress! ${(completionRate * 100).round()}% completion today. Let\'s support each other to reach 100%!';
      } else if (topStreaker['current_streak'] > 0) {
        return '⭐ Shoutout to our streak leader with ${topStreaker['current_streak']} days! Who\'s ready to catch up?';
      } else {
        return '🌟 Every journey starts with a single step. Today is a perfect day to start your streak!';
      }
    } catch (e) {
      Logger.d('Error generating motivational message: $e');
      return null;
    }
  }
}
