/// User Feedback Service for SnapAMeal Enhanced Features
/// Collects, analyzes, and reports user feedback and satisfaction metrics
library;


import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';
import '../utils/performance_monitor.dart';

/// Types of feedback that can be collected
enum FeedbackType {
  foodDetectionAccuracy,
  processingSpeed,
  inlineEditingExperience,
  nutritionalQueryQuality,
  overallSatisfaction,
  featureUsability,
  errorReporting,
}

/// User feedback data structure
class UserFeedback {
  final String id;
  final String userId;
  final FeedbackType type;
  final int rating; // 1-5 scale
  final String? comment;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final String version;

  UserFeedback({
    required this.id,
    required this.userId,
    required this.type,
    required this.rating,
    this.comment,
    this.metadata = const {},
    required this.timestamp,
    required this.version,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'rating': rating,
      'comment': comment,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'version': version,
    };
  }

  factory UserFeedback.fromJson(Map<String, dynamic> json) {
    return UserFeedback(
      id: json['id'],
      userId: json['userId'],
      type: FeedbackType.values.firstWhere((e) => e.name == json['type']),
      rating: json['rating'],
      comment: json['comment'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
      version: json['version'],
    );
  }
}

/// Feedback analysis results
class FeedbackAnalysis {
  final double averageRating;
  final int totalResponses;
  final Map<FeedbackType, double> ratingsByType;
  final Map<FeedbackType, int> responseCountsByType;
  final List<String> commonIssues;
  final List<String> positiveHighlights;
  final Map<String, dynamic> performanceCorrelations;

  FeedbackAnalysis({
    required this.averageRating,
    required this.totalResponses,
    required this.ratingsByType,
    required this.responseCountsByType,
    required this.commonIssues,
    required this.positiveHighlights,
    required this.performanceCorrelations,
  });

  Map<String, dynamic> toJson() {
    return {
      'averageRating': averageRating,
      'totalResponses': totalResponses,
      'ratingsByType': ratingsByType.map((k, v) => MapEntry(k.name, v)),
      'responseCountsByType': responseCountsByType.map((k, v) => MapEntry(k.name, v)),
      'commonIssues': commonIssues,
      'positiveHighlights': positiveHighlights,
      'performanceCorrelations': performanceCorrelations,
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }
}

/// User feedback collection and analysis service
class UserFeedbackService {
  static const String _collectionName = 'user_feedback';
  static const String _analyticsCollectionName = 'feedback_analytics';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collect feedback from user
  Future<bool> collectFeedback({
    required String userId,
    required FeedbackType type,
    required int rating,
    String? comment,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      Logger.d('📝 Collecting user feedback: $type, rating: $rating');

      final feedback = UserFeedback(
        id: _generateFeedbackId(),
        userId: userId,
        type: type,
        rating: rating,
        comment: comment,
        metadata: {
          ...?metadata,
          'app_version': '4.0.0',
          'platform': 'flutter_app',
          'performance_context': _getPerformanceContext(),
        },
        timestamp: DateTime.now(),
        version: '4.0.0',
      );

      await _firestore
          .collection(_collectionName)
          .doc(feedback.id)
          .set(feedback.toJson());

      Logger.d('✅ Feedback collected successfully: ${feedback.id}');
      
      // Trigger analytics update if we have enough new feedback
      _triggerAnalyticsUpdate();
      
      return true;
    } catch (e) {
      Logger.d('❌ Error collecting feedback: $e');
      return false;
    }
  }

  /// Collect feedback specifically for meal analysis accuracy
  Future<bool> collectMealAnalysisFeedback({
    required String userId,
    required String mealId,
    required int accuracyRating,
    required int speedRating,
    List<String>? incorrectlyIdentifiedFoods,
    List<String>? missedFoods,
    String? generalComment,
  }) async {
    return await collectFeedback(
      userId: userId,
      type: FeedbackType.foodDetectionAccuracy,
      rating: accuracyRating,
      comment: generalComment,
      metadata: {
        'meal_id': mealId,
        'speed_rating': speedRating,
        'incorrectly_identified_foods': incorrectlyIdentifiedFoods ?? [],
        'missed_foods': missedFoods ?? [],
        'feedback_category': 'meal_analysis',
      },
    );
  }

  /// Collect feedback for inline editing experience
  Future<bool> collectInlineEditingFeedback({
    required String userId,
    required String correctionId,
    required int usabilityRating,
    required int searchQualityRating,
    bool wasSearchHelpful = true,
    String? improvementSuggestions,
  }) async {
    return await collectFeedback(
      userId: userId,
      type: FeedbackType.inlineEditingExperience,
      rating: usabilityRating,
      comment: improvementSuggestions,
      metadata: {
        'correction_id': correctionId,
        'search_quality_rating': searchQualityRating,
        'search_helpful': wasSearchHelpful,
        'feedback_category': 'inline_editing',
      },
    );
  }

  /// Collect feedback for nutritional query quality
  Future<bool> collectNutritionalQueryFeedback({
    required String userId,
    required String queryId,
    required String query,
    required int helpfulnessRating,
    required int accuracyRating,
    bool wasResponseRelevant = true,
    String? responseImprovements,
  }) async {
    return await collectFeedback(
      userId: userId,
      type: FeedbackType.nutritionalQueryQuality,
      rating: helpfulnessRating,
      comment: responseImprovements,
      metadata: {
        'query_id': queryId,
        'original_query': query,
        'accuracy_rating': accuracyRating,
        'response_relevant': wasResponseRelevant,
        'feedback_category': 'nutritional_queries',
      },
    );
  }

  /// Collect overall satisfaction feedback
  Future<bool> collectOverallSatisfactionFeedback({
    required String userId,
    required int overallRating,
    required Map<String, int> featureRatings,
    String? mostLikedFeature,
    String? leastLikedFeature,
    String? improvementSuggestions,
  }) async {
    return await collectFeedback(
      userId: userId,
      type: FeedbackType.overallSatisfaction,
      rating: overallRating,
      comment: improvementSuggestions,
      metadata: {
        'feature_ratings': featureRatings,
        'most_liked_feature': mostLikedFeature,
        'least_liked_feature': leastLikedFeature,
        'feedback_category': 'overall_satisfaction',
      },
    );
  }

  /// Report a bug or error
  Future<bool> reportError({
    required String userId,
    required String errorDescription,
    required String errorContext,
    Map<String, dynamic>? technicalDetails,
    String? reproductionSteps,
  }) async {
    return await collectFeedback(
      userId: userId,
      type: FeedbackType.errorReporting,
      rating: 1, // Errors are always 1 star
      comment: errorDescription,
      metadata: {
        'error_context': errorContext,
        'technical_details': technicalDetails ?? {},
        'reproduction_steps': reproductionSteps,
        'performance_data': PerformanceMonitor().getDashboardData(),
        'feedback_category': 'error_report',
      },
    );
  }

  /// Get feedback analysis for a specific time period
  Future<FeedbackAnalysis> analyzeFeedback({
    DateTime? startDate,
    DateTime? endDate,
    List<FeedbackType>? filterTypes,
  }) async {
    try {
      Logger.d('📊 Analyzing user feedback');

      final start = startDate ?? DateTime.now().subtract(Duration(days: 30));
      final end = endDate ?? DateTime.now();

      Query query = _firestore
          .collection(_collectionName)
          .where('timestamp', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('timestamp', isLessThanOrEqualTo: end.toIso8601String());

      final snapshot = await query.get();
      final feedbacks = snapshot.docs
          .map((doc) => UserFeedback.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter by types if specified
      final filteredFeedbacks = filterTypes != null
          ? feedbacks.where((f) => filterTypes.contains(f.type)).toList()
          : feedbacks;

      return _generateAnalysis(filteredFeedbacks);
    } catch (e) {
      Logger.d('❌ Error analyzing feedback: $e');
      // Return empty analysis on error
      return FeedbackAnalysis(
        averageRating: 0.0,
        totalResponses: 0,
        ratingsByType: {},
        responseCountsByType: {},
        commonIssues: [],
        positiveHighlights: [],
        performanceCorrelations: {},
      );
    }
  }

  /// Get recent critical feedback that needs immediate attention
  Future<List<UserFeedback>> getCriticalFeedback({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('rating', isLessThanOrEqualTo: 2) // 1-2 star ratings
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => UserFeedback.fromJson(doc.data()))
          .toList();
    } catch (e) {
      Logger.d('❌ Error fetching critical feedback: $e');
      return [];
    }
  }

  /// Get feedback trends over time
  Future<Map<String, dynamic>> getFeedbackTrends({
    required Duration period,
    FeedbackType? type,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(period);

      Query query = _firestore
          .collection(_collectionName)
          .where('timestamp', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('timestamp', isLessThanOrEqualTo: endDate.toIso8601String());

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      final snapshot = await query.get();
      final feedbacks = snapshot.docs
          .map((doc) => UserFeedback.fromJson(doc.data() as Map<String, dynamic>))
          .toList();

      return _calculateTrends(feedbacks, period);
    } catch (e) {
      Logger.d('❌ Error calculating feedback trends: $e');
      return {};
    }
  }

  /// Generate feedback analysis from collected data
  FeedbackAnalysis _generateAnalysis(List<UserFeedback> feedbacks) {
    if (feedbacks.isEmpty) {
      return FeedbackAnalysis(
        averageRating: 0.0,
        totalResponses: 0,
        ratingsByType: {},
        responseCountsByType: {},
        commonIssues: [],
        positiveHighlights: [],
        performanceCorrelations: {},
      );
    }

    // Calculate overall metrics
    final totalRating = feedbacks.fold<int>(0, (total, f) => total + f.rating);
    final averageRating = totalRating / feedbacks.length;

    // Group by feedback type
    final ratingsByType = <FeedbackType, double>{};
    final responseCountsByType = <FeedbackType, int>{};

    for (final type in FeedbackType.values) {
      final typeFeedbacks = feedbacks.where((f) => f.type == type).toList();
      if (typeFeedbacks.isNotEmpty) {
        final typeTotal = typeFeedbacks.fold<int>(0, (total, f) => total + f.rating);
        ratingsByType[type] = typeTotal / typeFeedbacks.length;
        responseCountsByType[type] = typeFeedbacks.length;
      }
    }

    // Extract common issues and positive highlights
    final commonIssues = _extractCommonIssues(feedbacks);
    final positiveHighlights = _extractPositiveHighlights(feedbacks);

    // Correlate with performance data
    final performanceCorrelations = _correlateWithPerformance(feedbacks);

    return FeedbackAnalysis(
      averageRating: averageRating,
      totalResponses: feedbacks.length,
      ratingsByType: ratingsByType,
      responseCountsByType: responseCountsByType,
      commonIssues: commonIssues,
      positiveHighlights: positiveHighlights,
      performanceCorrelations: performanceCorrelations,
    );
  }

  /// Extract common issues from low-rated feedback
  List<String> _extractCommonIssues(List<UserFeedback> feedbacks) {
    final lowRatedFeedbacks = feedbacks.where((f) => f.rating <= 2).toList();
    final issues = <String>[];

    // Analyze comments for common themes
    final commentWords = <String, int>{};
    for (final feedback in lowRatedFeedbacks) {
      if (feedback.comment != null) {
        final words = feedback.comment!.toLowerCase().split(RegExp(r'\W+'));
        for (final word in words) {
          if (word.length > 3) {
            commentWords[word] = (commentWords[word] ?? 0) + 1;
          }
        }
      }
    }

    // Extract most common issue keywords
    final sortedWords = commentWords.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedWords.take(5)) {
      if (entry.value >= 2) {
        issues.add('${entry.key} (mentioned ${entry.value} times)');
      }
    }

    return issues;
  }

  /// Extract positive highlights from high-rated feedback
  List<String> _extractPositiveHighlights(List<UserFeedback> feedbacks) {
    final highRatedFeedbacks = feedbacks.where((f) => f.rating >= 4).toList();
    final highlights = <String>[];

    // Analyze positive comments
    final positiveWords = <String, int>{};
    for (final feedback in highRatedFeedbacks) {
      if (feedback.comment != null) {
        final words = feedback.comment!.toLowerCase().split(RegExp(r'\W+'));
        for (final word in words) {
          if (word.length > 3 && _isPositiveWord(word)) {
            positiveWords[word] = (positiveWords[word] ?? 0) + 1;
          }
        }
      }
    }

    final sortedPositives = positiveWords.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedPositives.take(3)) {
      if (entry.value >= 2) {
        highlights.add('${entry.key} (mentioned ${entry.value} times)');
      }
    }

    return highlights;
  }

  /// Check if a word is generally positive
  bool _isPositiveWord(String word) {
    const positiveWords = {
      'good', 'great', 'excellent', 'amazing', 'fast', 'accurate', 
      'helpful', 'easy', 'convenient', 'useful', 'love', 'like',
      'perfect', 'wonderful', 'fantastic', 'awesome', 'brilliant'
    };
    return positiveWords.contains(word);
  }

  /// Correlate feedback with performance metrics
  Map<String, dynamic> _correlateWithPerformance(List<UserFeedback> feedbacks) {
    final performanceData = PerformanceMonitor().getDashboardData();
    
    return {
      'total_operations_during_feedback_period': performanceData['total_operations'],
      'average_response_time_ms': performanceData['average_response_time_ms'],
      'success_rate': performanceData['successful_operations'] / 
          (performanceData['total_operations'] + 1), // Avoid division by zero
      'cost_per_feedback': performanceData['total_cost_usd'] / 
          (feedbacks.length + 1),
    };
  }

  /// Calculate feedback trends over time
  Map<String, dynamic> _calculateTrends(List<UserFeedback> feedbacks, Duration period) {
    // Group feedback by day/week depending on period
    final groupBy = period.inDays > 30 ? 'week' : 'day';
    final groupedData = <String, List<UserFeedback>>{};

    for (final feedback in feedbacks) {
      final key = groupBy == 'week' 
          ? '${feedback.timestamp.year}-W${_getWeekOfYear(feedback.timestamp)}'
          : '${feedback.timestamp.year}-${feedback.timestamp.month.toString().padLeft(2, '0')}-${feedback.timestamp.day.toString().padLeft(2, '0')}';
      
      groupedData[key] ??= [];
      groupedData[key]!.add(feedback);
    }

    // Calculate trends
    final trendData = <String, double>{};
    for (final entry in groupedData.entries) {
      final avgRating = entry.value.fold<int>(0, (total, f) => total + f.rating) / entry.value.length;
      trendData[entry.key] = avgRating;
    }

    return {
      'trend_data': trendData,
      'period_type': groupBy,
      'total_periods': trendData.length,
      'trend_direction': _calculateTrendDirection(trendData.values.toList()),
    };
  }

  /// Calculate trend direction (improving, declining, stable)
  String _calculateTrendDirection(List<double> values) {
    if (values.length < 2) return 'insufficient_data';
    
    final first = values.take(values.length ~/ 2).fold<double>(0, (total, v) => total + v) / (values.length ~/ 2);
    final second = values.skip(values.length ~/ 2).fold<double>(0, (total, v) => total + v) / (values.length - values.length ~/ 2);
    
    final difference = second - first;
    
    if (difference > 0.2) return 'improving';
    if (difference < -0.2) return 'declining';
    return 'stable';
  }

  /// Helper methods
  String _generateFeedbackId() {
    return 'feedback_${DateTime.now().millisecondsSinceEpoch}';
  }

  Map<String, dynamic> _getPerformanceContext() {
    final performanceData = PerformanceMonitor().getDashboardData();
    return {
      'recent_avg_response_time': performanceData['average_response_time_ms'],
      'recent_success_rate': performanceData['successful_operations'] / 
          (performanceData['total_operations'] + 1),
    };
  }

  int _getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil();
  }

  void _triggerAnalyticsUpdate() {
    // Trigger background analytics update if enough new feedback has been collected
    Future(() async {
      try {
        final analysis = await analyzeFeedback();
        await _firestore
            .collection(_analyticsCollectionName)
            .doc('latest_analysis')
            .set(analysis.toJson());
      } catch (e) {
        Logger.d('Error updating analytics: $e');
      }
    });
  }
} 