import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';
import 'rag_service.dart';

/// Service for generating and managing personalized weekly and monthly reviews
class WeeklyReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RAGService? _ragService;

  // Collection references
  late final CollectionReference _reviewsCollection;
  late final CollectionReference _storiesCollection;
  late final CollectionReference _mealLogsCollection;
  late final CollectionReference _fastingSessionsCollection;
  late final CollectionReference _userHealthProfilesCollection;

  WeeklyReviewService({RAGService? ragService}) : _ragService = ragService {
    _reviewsCollection = _firestore.collection('user_reviews');
    _storiesCollection = _firestore.collection('stories');
    _mealLogsCollection = _firestore.collection('meal_logs');
    _fastingSessionsCollection = _firestore.collection('fasting_sessions');
    _userHealthProfilesCollection = _firestore.collection('user_health_profiles');
  }

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Generate weekly review for a user
  Future<Map<String, dynamic>?> generateWeeklyReview({
    required String userId,
    DateTime? weekStart,
  }) async {
    try {
      // Default to start of current week if not provided
      weekStart ??= _getStartOfWeek(DateTime.now());
      final weekEnd = weekStart.add(const Duration(days: 7));

      // Check if review already exists for this week
      final existingReview = await _getExistingReview(userId, weekStart, 'weekly');
      if (existingReview != null) {
        Logger.d('Weekly review already exists for user $userId, week ${_formatDate(weekStart)}');
        return existingReview;
      }

      // Collect user activity data for the week
      final activityData = await _collectUserActivityData(userId, weekStart, weekEnd);
      
      // Get user profile for personalization
      final userProfile = await _getUserProfile(userId);

      // Generate review using RAG service or fallback
      Map<String, dynamic> review;
      try {
        if (_ragService != null && activityData['stories'].isNotEmpty) {
          final rawReview = await _ragService!.generateWeeklyDigest(
            userId: userId,
            weekStart: weekStart,
            stories: activityData['stories'],
            userProfile: userProfile,
          );
          review = Map<String, dynamic>.from(rawReview);
        } else {
          review = _generateFallbackWeeklyReview(activityData, weekStart, userProfile);
        }
      } catch (e) {
        Logger.d('RAG service failed, using fallback: $e');
        review = _generateFallbackWeeklyReview(activityData, weekStart, userProfile);
      }

      // Save review to Firestore
      final reviewDoc = <String, dynamic>{
        'user_id': userId,
        'review_type': 'weekly',
        'week_of': Timestamp.fromDate(weekStart),
        'generated_at': Timestamp.now(),
        'activity_data': activityData,
        'review_content': review,
        'is_ai_generated': _ragService != null,
        'status': 'active',
      };

      try {
        final docRef = await _reviewsCollection.add(reviewDoc);
        Logger.d('Generated and saved weekly review for user $userId: ${docRef.id}');
        
        return <String, dynamic>{
          'id': docRef.id,
          ...reviewDoc,
        };
      } catch (e) {
        Logger.d('Error saving weekly review to Firestore: $e');
        // Return review data even if saving fails
        return <String, dynamic>{
          'id': 'unsaved_${DateTime.now().millisecondsSinceEpoch}',
          ...reviewDoc,
          'is_saved': false,
        };
      }
    } catch (e) {
      Logger.d('Error generating weekly review: $e');
      return null;
    }
  }

  /// Generate monthly review for a user
  Future<Map<String, dynamic>?> generateMonthlyReview({
    required String userId,
    DateTime? monthStart,
  }) async {
    try {
      // Default to start of current month if not provided
      monthStart ??= DateTime(DateTime.now().year, DateTime.now().month, 1);
      final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);

      // Check if review already exists for this month
      final existingReview = await _getExistingReview(userId, monthStart, 'monthly');
      if (existingReview != null) {
        Logger.d('Monthly review already exists for user $userId, month ${_formatDate(monthStart)}');
        return existingReview;
      }

      // Collect user activity data for the month
      final activityData = await _collectUserActivityData(userId, monthStart, monthEnd);
      
      // Get user profile for personalization
      final userProfile = await _getUserProfile(userId);

      // Generate review using RAG service or fallback
      Map<String, dynamic> review;
      try {
        if (_ragService != null && activityData['stories'].isNotEmpty) {
          final rawReview = await _ragService!.generateMonthlyDigest(
            userId: userId,
            monthStart: monthStart,
            stories: activityData['stories'],
            userProfile: userProfile,
          );
          review = Map<String, dynamic>.from(rawReview);
        } else {
          review = _generateFallbackMonthlyReview(activityData, monthStart, userProfile);
        }
      } catch (e) {
        Logger.d('RAG service failed, using fallback: $e');
        review = _generateFallbackMonthlyReview(activityData, monthStart, userProfile);
      }

      // Save review to Firestore
      final reviewDoc = <String, dynamic>{
        'user_id': userId,
        'review_type': 'monthly',
        'month_of': Timestamp.fromDate(monthStart),
        'generated_at': Timestamp.now(),
        'activity_data': activityData,
        'review_content': review,
        'is_ai_generated': _ragService != null,
        'status': 'active',
      };

      try {
        final docRef = await _reviewsCollection.add(reviewDoc);
        Logger.d('Generated and saved monthly review for user $userId: ${docRef.id}');
        
        return <String, dynamic>{
          'id': docRef.id,
          ...reviewDoc,
        };
      } catch (e) {
        Logger.d('Error saving monthly review to Firestore: $e');
        // Return review data even if saving fails
        return <String, dynamic>{
          'id': 'unsaved_${DateTime.now().millisecondsSinceEpoch}',
          ...reviewDoc,
          'is_saved': false,
        };
      }
    } catch (e) {
      Logger.d('Error generating monthly review: $e');
      return null;
    }
  }

  /// Collect comprehensive user activity data for a time period
  Future<Map<String, dynamic>> _collectUserActivityData(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Collect stories
      final storiesSnapshot = await _storiesCollection
          .where('user_id', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .get();

      final stories = storiesSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      // Collect meal logs
      final mealLogsSnapshot = await _mealLogsCollection
          .where('user_id', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp', descending: true)
          .get();

      final mealLogs = mealLogsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      // Collect fasting sessions
      final fastingSnapshot = await _fastingSessionsCollection
          .where('user_id', isEqualTo: userId)
          .where('start_time', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('start_time', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('start_time', descending: true)
          .get();

      final fastingSessions = fastingSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      // Calculate activity metrics
      final metrics = _calculateActivityMetrics(stories, mealLogs, fastingSessions, startDate, endDate);

      return <String, dynamic>{
        'stories': stories,
        'meal_logs': mealLogs,
        'fasting_sessions': fastingSessions,
        'metrics': metrics,
        'period': <String, dynamic>{
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
          'days': endDate.difference(startDate).inDays,
        },
      };
    } catch (e) {
      Logger.d('Error collecting user activity data: $e');
      // Return empty data structure but still proceed with generation
      return <String, dynamic>{
        'stories': <Map<String, dynamic>>[],
        'meal_logs': <Map<String, dynamic>>[],
        'fasting_sessions': <Map<String, dynamic>>[],
        'metrics': <String, dynamic>{},
        'period': <String, dynamic>{
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
          'days': endDate.difference(startDate).inDays,
        },
      };
    }
  }

  /// Calculate activity metrics from collected data
  Map<String, dynamic> _calculateActivityMetrics(
    List<Map<String, dynamic>> stories,
    List<Map<String, dynamic>> mealLogs,
    List<Map<String, dynamic>> fastingSessions,
    DateTime startDate,
    DateTime endDate,
  ) {
    final totalDays = endDate.difference(startDate).inDays;
    
    // Story metrics
    final storyMetrics = {
      'total_count': stories.length,
      'daily_average': totalDays > 0 ? stories.length / totalDays : 0,
      'milestone_count': stories.where((story) {
        final permanence = story['permanence'] as Map<String, dynamic>?;
        final tier = permanence?['tier'] as String?;
        return tier == 'milestone' || tier == 'monthly' || tier == 'weekly';
      }).length,
      'engagement_total': stories.fold<int>(0, (total, story) {
        final engagement = story['engagement'] as Map<String, dynamic>? ?? {};
        return total + 
               (engagement['views'] as int? ?? 0) +
               (engagement['likes'] as int? ?? 0) +
               (engagement['comments'] as int? ?? 0);
      }),
    };

    // Meal metrics
    final mealMetrics = {
      'total_count': mealLogs.length,
      'daily_average': totalDays > 0 ? mealLogs.length / totalDays : 0,
      'unique_foods': _getUniqueFoods(mealLogs).length,
      'most_common_meal_type': _getMostCommonMealType(mealLogs),
    };

    // Fasting metrics
    final fastingMetrics = {
      'total_sessions': fastingSessions.length,
      'completed_sessions': fastingSessions.where((session) => 
        session['status'] == 'completed').length,
      'average_duration': _calculateAverageFastingDuration(fastingSessions),
      'longest_fast': _getLongestFast(fastingSessions),
    };

    // Activity patterns
    final activityPatterns = _analyzeActivityPatterns(stories, mealLogs, fastingSessions);

    return {
      'stories': storyMetrics,
      'meals': mealMetrics,
      'fasting': fastingMetrics,
      'patterns': activityPatterns,
      'overall': {
        'active_days': _getActiveDays(stories, mealLogs, fastingSessions).length,
        'total_activities': stories.length + mealLogs.length + fastingSessions.length,
        'consistency_score': _calculateConsistencyScore(stories, mealLogs, fastingSessions, totalDays),
      },
    };
  }

  /// Get unique foods from meal logs
  Set<String> _getUniqueFoods(List<Map<String, dynamic>> mealLogs) {
    final foods = <String>{};
    for (final meal in mealLogs) {
      final detectedFoods = meal['detected_foods'] as List<dynamic>? ?? [];
      foods.addAll(detectedFoods.cast<String>());
    }
    return foods;
  }

  /// Get most common meal type
  String _getMostCommonMealType(List<Map<String, dynamic>> mealLogs) {
    final mealTypeCounts = <String, int>{};
    for (final meal in mealLogs) {
      final mealType = meal['meal_type'] as String? ?? 'unknown';
      mealTypeCounts[mealType] = (mealTypeCounts[mealType] ?? 0) + 1;
    }
    
    if (mealTypeCounts.isEmpty) return 'none';
    
    return mealTypeCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Calculate average fasting duration in hours
  double _calculateAverageFastingDuration(List<Map<String, dynamic>> fastingSessions) {
    final completedSessions = fastingSessions.where((session) => 
      session['status'] == 'completed' && 
      session['end_time'] != null).toList();
    
    if (completedSessions.isEmpty) return 0.0;
    
    final totalDuration = completedSessions.fold<double>(0.0, (total, session) {
      final startTime = (session['start_time'] as Timestamp).toDate();
      final endTime = (session['end_time'] as Timestamp).toDate();
      return total + endTime.difference(startTime).inHours;
    });
    
    return totalDuration / completedSessions.length;
  }

  /// Get longest fast duration in hours
  double _getLongestFast(List<Map<String, dynamic>> fastingSessions) {
    double longest = 0.0;
    
    for (final session in fastingSessions) {
      if (session['status'] == 'completed' && session['end_time'] != null) {
        final startTime = (session['start_time'] as Timestamp).toDate();
        final endTime = (session['end_time'] as Timestamp).toDate();
        final duration = endTime.difference(startTime).inHours.toDouble();
        if (duration > longest) longest = duration;
      }
    }
    
    return longest;
  }

  /// Analyze activity patterns by day of week
  Map<String, dynamic> _analyzeActivityPatterns(
    List<Map<String, dynamic>> stories,
    List<Map<String, dynamic>> mealLogs,
    List<Map<String, dynamic>> fastingSessions,
  ) {
    final weekdayActivity = <int, int>{};
    final hourlyActivity = <int, int>{};
    
    // Analyze all activities
    final allActivities = [
      ...stories.map((s) => s['timestamp']),
      ...mealLogs.map((m) => m['timestamp']),
      ...fastingSessions.map((f) => f['start_time']),
    ];
    
    for (final timestamp in allActivities) {
      if (timestamp != null) {
        final date = (timestamp as Timestamp).toDate();
        final weekday = date.weekday;
        final hour = date.hour;
        
        weekdayActivity[weekday] = (weekdayActivity[weekday] ?? 0) + 1;
        hourlyActivity[hour] = (hourlyActivity[hour] ?? 0) + 1;
      }
    }
    
    return {
      'most_active_weekday': _getMostActiveWeekday(weekdayActivity),
      'most_active_hour': _getMostActiveHour(hourlyActivity),
      'weekday_distribution': weekdayActivity,
      'hourly_distribution': hourlyActivity,
    };
  }

  /// Get most active weekday name
  String _getMostActiveWeekday(Map<int, int> weekdayActivity) {
    if (weekdayActivity.isEmpty) return 'Unknown';
    
    final mostActive = weekdayActivity.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[mostActive.key - 1];
  }

  /// Get most active hour
  String _getMostActiveHour(Map<int, int> hourlyActivity) {
    if (hourlyActivity.isEmpty) return 'Unknown';
    
    final mostActive = hourlyActivity.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    final hour = mostActive.key;
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    
    return '$displayHour:00 $period';
  }

  /// Get unique active days
  Set<String> _getActiveDays(
    List<Map<String, dynamic>> stories,
    List<Map<String, dynamic>> mealLogs,
    List<Map<String, dynamic>> fastingSessions,
  ) {
    final activeDays = <String>{};
    
    final allActivities = [
      ...stories.map((s) => s['timestamp']),
      ...mealLogs.map((m) => m['timestamp']),
      ...fastingSessions.map((f) => f['start_time']),
    ];
    
    for (final timestamp in allActivities) {
      if (timestamp != null) {
        final date = (timestamp as Timestamp).toDate();
        activeDays.add(_formatDate(date));
      }
    }
    
    return activeDays;
  }

  /// Calculate consistency score (0-1)
  double _calculateConsistencyScore(
    List<Map<String, dynamic>> stories,
    List<Map<String, dynamic>> mealLogs,
    List<Map<String, dynamic>> fastingSessions,
    int totalDays,
  ) {
    if (totalDays <= 0) return 0.0;
    
    final activeDays = _getActiveDays(stories, mealLogs, fastingSessions);
    return activeDays.length / totalDays;
  }

  /// Check if review already exists for the period
  Future<Map<String, dynamic>?> _getExistingReview(
    String userId,
    DateTime periodStart,
    String reviewType,
  ) async {
    try {
      final snapshot = await _reviewsCollection
          .where('user_id', isEqualTo: userId)
          .where('review_type', isEqualTo: reviewType)
          .where(
            reviewType == 'weekly' ? 'week_of' : 'month_of',
            isEqualTo: Timestamp.fromDate(periodStart),
          )
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      
      return null;
    } catch (e) {
      Logger.d('Error checking existing review: $e');
      // Continue with generation even if check fails
      return null;
    }
  }

  /// Get user profile for personalization
  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final healthDoc = await _userHealthProfilesCollection.doc(userId).get();
      
      final userData = userDoc.data() ?? {};
      final healthData = healthDoc.data() ?? {};
      
      return {
        ...userData,
        'health_profile': healthData,
      };
    } catch (e) {
      Logger.d('Error getting user profile: $e');
      // Return fallback only if Firestore access completely fails
      return {
        'health_profile': {
          'health_goals': ['general_wellness'],
          'dietary_preferences': [],
        },
      };
    }
  }

  /// Generate fallback weekly review when RAG service is unavailable
  Map<String, dynamic> _generateFallbackWeeklyReview(
    Map<String, dynamic> activityData,
    DateTime weekStart,
    Map<String, dynamic>? userProfile,
  ) {
    final metrics = Map<String, dynamic>.from(activityData['metrics'] as Map? ?? {});
    final storyMetrics = Map<String, dynamic>.from(metrics['stories'] as Map? ?? {});
    final mealMetrics = Map<String, dynamic>.from(metrics['meals'] as Map? ?? {});
    final overallMetrics = Map<String, dynamic>.from(metrics['overall'] as Map? ?? {});
    
    final storyCount = storyMetrics['total_count'] as int? ?? 0;
    final mealCount = mealMetrics['total_count'] as int? ?? 0;
    final activeDays = overallMetrics['active_days'] as int? ?? 0;
    
    return <String, dynamic>{
      'digest_type': 'weekly',
      'week_of': _formatDate(weekStart),
      'summary': _generateWeeklySummary(storyCount, mealCount, activeDays),
      'highlights': _generateWeeklyHighlights(activityData),
      'insights': _generateWeeklyInsights(activityData),
      'weekly_insights': _generateSpecificWeeklyInsights(activityData),
      'next_week_goals': _generateNextWeekGoals(userProfile),
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Generate fallback monthly review when RAG service is unavailable
  Map<String, dynamic> _generateFallbackMonthlyReview(
    Map<String, dynamic> activityData,
    DateTime monthStart,
    Map<String, dynamic>? userProfile,
  ) {
    final metrics = Map<String, dynamic>.from(activityData['metrics'] as Map? ?? {});
    final storyMetrics = Map<String, dynamic>.from(metrics['stories'] as Map? ?? {});
    final mealMetrics = Map<String, dynamic>.from(metrics['meals'] as Map? ?? {});
    final overallMetrics = Map<String, dynamic>.from(metrics['overall'] as Map? ?? {});
    
    final storyCount = storyMetrics['total_count'] as int? ?? 0;
    final mealCount = mealMetrics['total_count'] as int? ?? 0;
    final activeDays = overallMetrics['active_days'] as int? ?? 0;
    
    return <String, dynamic>{
      'digest_type': 'monthly',
      'month_of': _formatDate(monthStart),
      'summary': _generateMonthlySummary(storyCount, mealCount, activeDays),
      'highlights': _generateMonthlyHighlights(activityData),
      'insights': _generateMonthlyInsights(activityData),
      'monthly_trends': _generateMonthlyTrends(activityData),
      'growth_areas': _generateGrowthAreas(activityData),
      'achievement_badges': _generateAchievementBadges(activityData),
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Generate weekly summary text
  String _generateWeeklySummary(int storyCount, int mealCount, int activeDays) {
    if (storyCount == 0 && mealCount == 0) {
      return 'This week was quiet on your health journey. Sometimes taking a break is just what we need!';
    }
    
    final activities = <String>[];
    if (storyCount > 0) activities.add('$storyCount ${storyCount == 1 ? 'story' : 'stories'}');
    if (mealCount > 0) activities.add('$mealCount ${mealCount == 1 ? 'meal' : 'meals'}');
    
    return 'This week you shared ${activities.join(' and ')}, staying active for $activeDays ${activeDays == 1 ? 'day' : 'days'}. Keep up the great work on your wellness journey!';
  }

  /// Generate monthly summary text
  String _generateMonthlySummary(int storyCount, int mealCount, int activeDays) {
    if (storyCount == 0 && mealCount == 0) {
      return 'This month was a period of reflection on your health journey. Every journey has different phases!';
    }
    
    final activities = <String>[];
    if (storyCount > 0) activities.add('$storyCount ${storyCount == 1 ? 'story' : 'stories'}');
    if (mealCount > 0) activities.add('$mealCount ${mealCount == 1 ? 'meal' : 'meals'}');
    
    return 'This month you documented ${activities.join(' and ')}, staying engaged for $activeDays ${activeDays == 1 ? 'day' : 'days'}. Your consistency is building healthy habits!';
  }

  /// Generate weekly highlights
  List<String> _generateWeeklyHighlights(Map<String, dynamic> activityData) {
    final highlights = <String>[];
    final metrics = activityData['metrics'] as Map<String, dynamic>? ?? {};
    
    final storyMetrics = metrics['stories'] as Map<String, dynamic>? ?? {};
    final milestoneCount = storyMetrics['milestone_count'] as int? ?? 0;
    if (milestoneCount > 0) {
      highlights.add('Created $milestoneCount milestone ${milestoneCount == 1 ? 'story' : 'stories'}');
    }
    
    final patterns = metrics['patterns'] as Map<String, dynamic>? ?? {};
    final mostActiveDay = patterns['most_active_weekday'] as String?;
    if (mostActiveDay != null && mostActiveDay != 'Unknown') {
      highlights.add('Most active on $mostActiveDay');
    }
    
    final overallMetrics = metrics['overall'] as Map<String, dynamic>? ?? {};
    final consistencyScore = overallMetrics['consistency_score'] as double? ?? 0.0;
    if (consistencyScore >= 0.7) {
      highlights.add('Maintained excellent consistency');
    } else if (consistencyScore >= 0.5) {
      highlights.add('Showed good consistency');
    }
    
    if (highlights.isEmpty) {
      highlights.add('Continued your wellness journey');
    }
    
    return highlights;
  }

  /// Generate monthly highlights
  List<String> _generateMonthlyHighlights(Map<String, dynamic> activityData) {
    final highlights = <String>[];
    final metrics = activityData['metrics'] as Map<String, dynamic>? ?? {};
    
    final storyMetrics = metrics['stories'] as Map<String, dynamic>? ?? {};
    final storyCount = storyMetrics['total_count'] as int? ?? 0;
    if (storyCount >= 20) {
      highlights.add('Shared $storyCount stories - amazing documentation!');
    } else if (storyCount >= 10) {
      highlights.add('Shared $storyCount stories consistently');
    }
    
    final mealMetrics = metrics['meals'] as Map<String, dynamic>? ?? {};
    final uniqueFoods = mealMetrics['unique_foods'] as int? ?? 0;
    if (uniqueFoods >= 20) {
      highlights.add('Explored $uniqueFoods different foods');
    }
    
    final fastingMetrics = metrics['fasting'] as Map<String, dynamic>? ?? {};
    final completedFasts = fastingMetrics['completed_sessions'] as int? ?? 0;
    if (completedFasts >= 10) {
      highlights.add('Completed $completedFasts fasting sessions');
    }
    
    if (highlights.isEmpty) {
      highlights.add('Maintained your health journey');
    }
    
    return highlights;
  }

  /// Generate weekly insights
  List<String> _generateWeeklyInsights(Map<String, dynamic> activityData) {
    return [
      'Consistency in small actions leads to big results',
      'Your health journey is unique to you',
      'Every logged meal and story helps track your progress',
    ];
  }

  /// Generate monthly insights
  List<String> _generateMonthlyInsights(Map<String, dynamic> activityData) {
    return [
      'Monthly patterns help identify what works best for you',
      'Tracking your journey provides valuable insights over time',
      'Celebrating progress keeps you motivated for the long term',
    ];
  }

  /// Generate specific weekly insights
  List<String> _generateSpecificWeeklyInsights(Map<String, dynamic> activityData) {
    final insights = <String>[];
    final metrics = activityData['metrics'] as Map<String, dynamic>? ?? {};
    
    final patterns = metrics['patterns'] as Map<String, dynamic>? ?? {};
    final mostActiveHour = patterns['most_active_hour'] as String?;
    if (mostActiveHour != null && mostActiveHour != 'Unknown') {
      insights.add('You\'re most active around $mostActiveHour');
    }
    
    final mealMetrics = metrics['meals'] as Map<String, dynamic>? ?? {};
    final avgMeals = mealMetrics['daily_average'] as double? ?? 0.0;
    if (avgMeals >= 3) {
      insights.add('Great job maintaining regular meal logging');
    }
    
    return insights.isNotEmpty ? insights : ['Keep up the great work!'];
  }

  /// Generate monthly trends
  Map<String, dynamic> _generateMonthlyTrends(Map<String, dynamic> activityData) {
    return <String, dynamic>{
      'content_growth': 'steady',
      'engagement_trend': 'positive',
      'consistency': 'improving',
    };
  }

  /// Generate growth areas
  List<String> _generateGrowthAreas(Map<String, dynamic> activityData) {
    return [
      'Try new types of healthy activities',
      'Engage more with the community',
      'Set specific weekly goals',
    ];
  }

  /// Generate achievement badges
  List<Map<String, dynamic>> _generateAchievementBadges(Map<String, dynamic> activityData) {
    final badges = <Map<String, dynamic>>[];
    final metrics = activityData['metrics'] as Map<String, dynamic>? ?? {};
    
    final storyMetrics = metrics['stories'] as Map<String, dynamic>? ?? {};
    final storyCount = storyMetrics['total_count'] as int? ?? 0;
    
    if (storyCount >= 30) {
      badges.add({
        'name': 'Story Master',
        'icon': 'camera',
        'description': 'Shared 30+ stories this month',
      });
    }
    
    final overallMetrics = metrics['overall'] as Map<String, dynamic>? ?? {};
    final consistencyScore = overallMetrics['consistency_score'] as double? ?? 0.0;
    
    if (consistencyScore >= 0.8) {
      badges.add({
        'name': 'Consistency Champion',
        'icon': 'star',
        'description': 'Maintained 80%+ daily activity',
      });
    }
    
    return badges;
  }

  /// Generate next week goals
  List<String> _generateNextWeekGoals(Map<String, dynamic>? userProfile) {
    final goals = <String>[];
    
    // Get user's health goals for personalized suggestions
    final healthProfile = userProfile?['health_profile'] as Map<String, dynamic>?;
    final userGoals = healthProfile?['health_goals'] as List<dynamic>? ?? [];
    
    if (userGoals.contains('weight_loss')) {
      goals.add('Log meals consistently to track nutrition');
    } else if (userGoals.contains('muscle_gain')) {
      goals.add('Document workout progress with photos');
    } else if (userGoals.contains('energy')) {
      goals.add('Track energy levels throughout the day');
    }
    
    // Add general goals
    goals.addAll([
      'Share at least 3 health-focused stories',
      'Try one new healthy recipe',
      'Connect with community members',
    ]);
    
    return goals.take(3).toList();
  }

  /// Get reviews for a user
  Stream<List<Map<String, dynamic>>> getUserReviews({
    required String userId,
    String? reviewType,
    int limit = 10,
  }) {
    try {
      Query query = _reviewsCollection
          .where('user_id', isEqualTo: userId)
          .where('status', isEqualTo: 'active');
      
      if (reviewType != null) {
        query = query.where('review_type', isEqualTo: reviewType);
      }
      
      return query
          .orderBy('generated_at', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          }).toList())
          .handleError((error) {
            Logger.d('Error in user reviews stream: $error');
            return <Map<String, dynamic>>[];
          });
    } catch (e) {
      Logger.d('Error setting up user reviews stream: $e');
      return Stream.value(<Map<String, dynamic>>[]);
    }
  }

  /// Batch generate weekly reviews for all users
  Future<void> generateWeeklyReviewsForAllUsers() async {
    try {
      Logger.d('Starting batch weekly review generation');
      
      // Get all users (this might need pagination for large user bases)
      final usersSnapshot = await _firestore.collection('users').get();
      
      int generated = 0;
      int errors = 0;
      
      for (final userDoc in usersSnapshot.docs) {
        try {
          final userId = userDoc.id;
          final review = await generateWeeklyReview(userId: userId);
          
          if (review != null) {
            generated++;
            Logger.d('Generated weekly review for user $userId');
          } else {
            errors++;
          }
        } catch (e) {
          errors++;
          Logger.d('Error generating weekly review for user ${userDoc.id}: $e');
        }
        
        // Add small delay to avoid overwhelming Firestore
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      Logger.d('Batch weekly review generation complete: $generated generated, $errors errors');
    } catch (e) {
      Logger.d('Error in batch weekly review generation: $e');
    }
  }

  /// Batch generate monthly reviews for all users
  Future<void> generateMonthlyReviewsForAllUsers() async {
    try {
      Logger.d('Starting batch monthly review generation');
      
      // Get all users (this might need pagination for large user bases)
      final usersSnapshot = await _firestore.collection('users').get();
      
      int generated = 0;
      int errors = 0;
      
      for (final userDoc in usersSnapshot.docs) {
        try {
          final userId = userDoc.id;
          final review = await generateMonthlyReview(userId: userId);
          
          if (review != null) {
            generated++;
            Logger.d('Generated monthly review for user $userId');
          } else {
            errors++;
          }
        } catch (e) {
          errors++;
          Logger.d('Error generating monthly review for user ${userDoc.id}: $e');
        }
        
        // Add small delay to avoid overwhelming Firestore
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      Logger.d('Batch monthly review generation complete: $generated generated, $errors errors');
    } catch (e) {
      Logger.d('Error in batch monthly review generation: $e');
    }
  }

  /// Delete old reviews to manage storage
  Future<void> cleanupOldReviews({int keepMonths = 12}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: keepMonths * 30));
      
      final snapshot = await _reviewsCollection
          .where('generated_at', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();
      
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      Logger.d('Cleaned up ${snapshot.docs.length} old reviews');
    } catch (e) {
      Logger.d('Error cleaning up old reviews: $e');
    }
  }

  /// Get start of week (Monday)
  DateTime _getStartOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }


} 