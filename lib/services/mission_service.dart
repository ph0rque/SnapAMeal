import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:snapameal/models/mission.dart';
import 'package:snapameal/models/health_profile.dart';

import 'package:snapameal/utils/logger.dart';

class MissionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final MissionService _instance = MissionService._internal();
  factory MissionService() => _instance;
  MissionService._internal();

  /// Generate a personalized mission for a new user based on their goals
  Future<Mission?> generateStarterMission({
    required String userId,
    required String goalType,
    required HealthProfile healthProfile,
  }) async {
    try {
      Logger.d('Generating starter mission for user $userId with goal $goalType');

      // Try to generate mission using RAG service first
      Mission? mission;
      try {
        mission = await _generateMissionWithRAG(userId, goalType, healthProfile);
      } catch (e) {
        Logger.d('RAG mission generation failed, using fallback: $e');
        mission = _generateFallbackMission(userId, goalType, healthProfile);
      }

      if (mission != null) {
        // Save mission to Firestore
        await _firestore
            .collection('user_missions')
            .doc(mission.id)
            .set(mission.toFirestore());

        Logger.d('Generated and saved mission ${mission.id} for user $userId');
        return mission;
      }

      return null;
    } catch (e) {
      Logger.d('Error generating starter mission: $e');
      return null;
    }
  }

  /// Generate mission using RAG service
  Future<Mission?> _generateMissionWithRAG(
    String userId,
    String goalType,
    HealthProfile healthProfile,
  ) async {
    // For now, use a simple approach since RAG service integration is complex
    // In a full implementation, this would call RAGService with mission generation prompts
    return _generateFallbackMission(userId, goalType, healthProfile);
  }

  /// Generate fallback mission when RAG service is unavailable
  Mission _generateFallbackMission(
    String userId,
    String goalType,
    HealthProfile healthProfile,
  ) {
    final missionId = 'mission_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 7));

    String title;
    String description;
    List<MissionStep> steps;

    switch (goalType.toLowerCase()) {
      case 'weight_loss':
        title = 'Your First 7 Days: Weight Loss Journey';
        description = 'Start your weight loss journey with these proven strategies. Small, consistent steps lead to lasting results!';
        steps = _getWeightLossSteps();
        break;
      case 'muscle_gain':
        title = 'Your First 7 Days: Muscle Building';
        description = 'Build strength and muscle with this beginner-friendly plan. Focus on nutrition and consistent habits!';
        steps = _getMuscleGainSteps();
        break;
      case 'health':
      default:
        title = 'Your First 7 Days: Healthy Living';
        description = 'Kickstart your health journey with these fundamental wellness habits. Every small step counts!';
        steps = _getGeneralHealthSteps();
        break;
    }

    return Mission(
      id: missionId,
      userId: userId,
      title: title,
      description: description,
      steps: steps,
      goalType: goalType,
      createdAt: now,
      expiresAt: expiresAt,
      difficulty: _getDifficultyForProfile(healthProfile),
    );
  }

  List<MissionStep> _getWeightLossSteps() {
    return [
      MissionStep(
        id: 'step_1',
        title: 'Log Your First Meal',
        description: 'Take a photo of your next meal and log it in the app. This helps you become aware of your eating habits.',
        order: 1,
        actionType: 'log_meal',
      ),
      MissionStep(
        id: 'step_2',
        title: 'Start a 12-Hour Fast',
        description: 'Try intermittent fasting with a simple 12-hour window. For example, finish eating by 8 PM and don\'t eat until 8 AM.',
        order: 2,
        actionType: 'start_fast',
        actionData: {'duration_hours': 12},
      ),
      MissionStep(
        id: 'step_3',
        title: 'Log 3 Meals in One Day',
        description: 'Track all your meals for a full day to understand your eating patterns.',
        order: 3,
        actionType: 'log_meals_daily',
        actionData: {'target_count': 3},
      ),
      MissionStep(
        id: 'step_4',
        title: 'Complete a 16-Hour Fast',
        description: 'Level up your fasting by trying a 16:8 intermittent fasting schedule.',
        order: 4,
        actionType: 'start_fast',
        actionData: {'duration_hours': 16},
      ),
      MissionStep(
        id: 'step_5',
        title: 'Log Meals for 3 Consecutive Days',
        description: 'Build consistency by tracking your meals for three days in a row.',
        order: 5,
        actionType: 'log_meals_streak',
        actionData: {'target_days': 3},
      ),
      MissionStep(
        id: 'step_6',
        title: 'Share Your Progress',
        description: 'Share a healthy meal or fasting milestone with the SnapAMeal community for motivation.',
        order: 6,
        actionType: 'share_progress',
      ),
      MissionStep(
        id: 'step_7',
        title: 'Complete Your First Week',
        description: 'Reflect on your progress and plan your next steps. You\'ve built the foundation for lasting change!',
        order: 7,
        actionType: 'reflection',
      ),
    ];
  }

  List<MissionStep> _getMuscleGainSteps() {
    return [
      MissionStep(
        id: 'step_1',
        title: 'Log a Protein-Rich Meal',
        description: 'Take a photo of a meal with good protein content (chicken, fish, beans, etc.) and log it.',
        order: 1,
        actionType: 'log_meal',
        actionData: {'focus': 'protein'},
      ),
      MissionStep(
        id: 'step_2',
        title: 'Track Your Daily Protein',
        description: 'Log all meals for one day and pay attention to your protein intake.',
        order: 2,
        actionType: 'track_macros',
        actionData: {'focus': 'protein'},
      ),
      MissionStep(
        id: 'step_3',
        title: 'Plan a Post-Workout Meal',
        description: 'Log a meal within 2 hours after exercise to support muscle recovery.',
        order: 3,
        actionType: 'post_workout_meal',
      ),
      MissionStep(
        id: 'step_4',
        title: 'Hit Your Protein Goal',
        description: 'Aim for adequate protein intake (0.8-1g per kg body weight) for one full day.',
        order: 4,
        actionType: 'protein_goal',
      ),
      MissionStep(
        id: 'step_5',
        title: 'Log 5 Balanced Meals',
        description: 'Track 5 meals that include protein, carbs, and healthy fats.',
        order: 5,
        actionType: 'balanced_meals',
        actionData: {'target_count': 5},
      ),
      MissionStep(
        id: 'step_6',
        title: 'Share a Muscle-Building Meal',
        description: 'Share your best muscle-building meal with the community.',
        order: 6,
        actionType: 'share_progress',
      ),
      MissionStep(
        id: 'step_7',
        title: 'Plan Your Nutrition Strategy',
        description: 'Review your week and plan your ongoing nutrition approach for muscle gain.',
        order: 7,
        actionType: 'reflection',
      ),
    ];
  }

  List<MissionStep> _getGeneralHealthSteps() {
    return [
      MissionStep(
        id: 'step_1',
        title: 'Log Your First Meal',
        description: 'Start building awareness by taking a photo and logging your next meal.',
        order: 1,
        actionType: 'log_meal',
      ),
      MissionStep(
        id: 'step_2',
        title: 'Try Mindful Eating',
        description: 'Log a meal and take time to really taste and enjoy it without distractions.',
        order: 2,
        actionType: 'mindful_eating',
      ),
      MissionStep(
        id: 'step_3',
        title: 'Add More Vegetables',
        description: 'Log a meal that includes at least 2 different vegetables.',
        order: 3,
        actionType: 'log_meal',
        actionData: {'focus': 'vegetables'},
      ),
      MissionStep(
        id: 'step_4',
        title: 'Stay Hydrated',
        description: 'Focus on drinking water throughout the day and log meals that include hydrating foods.',
        order: 4,
        actionType: 'hydration_focus',
      ),
      MissionStep(
        id: 'step_5',
        title: 'Track for 3 Days',
        description: 'Build consistency by logging your meals for three consecutive days.',
        order: 5,
        actionType: 'log_meals_streak',
        actionData: {'target_days': 3},
      ),
      MissionStep(
        id: 'step_6',
        title: 'Connect with Others',
        description: 'Share a healthy meal or tip with the SnapAMeal community.',
        order: 6,
        actionType: 'share_progress',
      ),
      MissionStep(
        id: 'step_7',
        title: 'Celebrate Your Progress',
        description: 'Reflect on the healthy habits you\'ve started building this week!',
        order: 7,
        actionType: 'reflection',
      ),
    ];
  }

  MissionDifficulty _getDifficultyForProfile(HealthProfile profile) {
    // Simple logic based on activity level
    final activityLevel = profile.activityLevel?.name.toLowerCase();
    
    if (activityLevel != null) {
      if (activityLevel.contains('very_active') || activityLevel.contains('athlete')) {
        return MissionDifficulty.advanced;
      } else if (activityLevel.contains('moderately_active') || activityLevel.contains('active')) {
        return MissionDifficulty.intermediate;
      }
    }
    return MissionDifficulty.beginner;
  }

  /// Get current active mission for user
  Future<Mission?> getCurrentMission([String? userId]) async {
    try {
      userId ??= FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return null;

      final snapshot = await _firestore
          .collection('user_missions')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Mission.fromFirestore(snapshot.docs.first);
      }

      return null;
    } catch (e) {
      Logger.d('Error getting current mission: $e');
      return null;
    }
  }

  /// Complete a mission step
  Future<bool> completeStep(String missionId, String stepId) async {
    try {
      final missionDoc = await _firestore
          .collection('user_missions')
          .doc(missionId)
          .get();

      if (!missionDoc.exists) return false;

      final mission = Mission.fromFirestore(missionDoc);
      final updatedSteps = mission.steps.map((step) {
        if (step.id == stepId) {
          return step.copyWith(
            isCompleted: true,
            completedAt: DateTime.now(),
          );
        }
        return step;
      }).toList();

      // Check if all steps are completed
      final allCompleted = updatedSteps.every((step) => step.isCompleted);
      final newStatus = allCompleted ? MissionStatus.completed : mission.status;
      final completedAt = allCompleted ? DateTime.now() : mission.completedAt;

      await _firestore
          .collection('user_missions')
          .doc(missionId)
          .update({
        'steps': updatedSteps.map((step) => step.toMap()).toList(),
        'status': newStatus.name,
        'completedAt': completedAt != null ? Timestamp.fromDate(completedAt) : null,
      });

      Logger.d('Completed step $stepId for mission $missionId');
      return true;
    } catch (e) {
      Logger.d('Error completing step: $e');
      return false;
    }
  }

  /// Get mission history for user
  Future<List<Mission>> getMissionHistory([String? userId]) async {
    try {
      userId ??= FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('user_missions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => Mission.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.d('Error getting mission history: $e');
      return [];
    }
  }

  /// Check if user has any active missions
  Future<bool> hasActiveMission([String? userId]) async {
    final mission = await getCurrentMission(userId);
    return mission != null && mission.isActive && !mission.isExpired;
  }

  /// Auto-complete steps based on user actions
  Future<void> checkAutoCompletions(String userId, String actionType, Map<String, dynamic> actionData) async {
    try {
      final currentMission = await getCurrentMission(userId);
      if (currentMission == null || !currentMission.isActive) return;

      // Find steps that can be auto-completed based on this action
      for (final step in currentMission.steps) {
        if (!step.isCompleted && step.actionType == actionType) {
          bool shouldComplete = false;

          switch (actionType) {
            case 'log_meal':
              shouldComplete = true; // Any meal log completes this
              break;
            case 'start_fast':
              final requiredHours = step.actionData['duration_hours'] as int?;
              final actualHours = actionData['duration_hours'] as int?;
              shouldComplete = requiredHours != null && actualHours != null && actualHours >= requiredHours;
              break;
            case 'log_meals_daily':
              final targetCount = step.actionData['target_count'] as int?;
              final actualCount = actionData['meal_count'] as int?;
              shouldComplete = targetCount != null && actualCount != null && actualCount >= targetCount;
              break;
            // Add more auto-completion logic as needed
          }

          if (shouldComplete) {
            await completeStep(currentMission.id, step.id);
          }
        }
      }
    } catch (e) {
      Logger.d('Error checking auto-completions: $e');
    }
  }
} 