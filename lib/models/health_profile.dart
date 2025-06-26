import 'package:cloud_firestore/cloud_firestore.dart';

enum Gender {
  male,
  female,
}

enum HealthGoalType {
  weightLoss,
  weightGain,
  muscleGain,
  enduranceImprovement,
  generalFitness,
  chronicDiseaseManagement,
  mentalWellness,
  nutritionImprovement,
  sleepImprovement,
  stressReduction,
  habitBuilding,
  // Additional health goals referenced in onboarding
  fatLoss,
  intermittentFasting,
  improveMetabolism,
  betterSleep,
  increaseEnergy,
  improveDigestion,
  longevity,
  mentalClarity,
  custom
}

enum ActivityLevel {
  sedentary,     // Little to no exercise
  lightlyActive, // Light exercise 1-3 days/week
  moderatelyActive, // Moderate exercise 3-5 days/week
  veryActive,    // Hard exercise 6-7 days/week
  extremelyActive, // Very hard exercise, physical job, or training twice a day
}

enum DietaryPreference {
  none,
  vegetarian,
  vegan,
  pescatarian,
  keto,
  paleo,
  mediterranean,
  lowCarb,
  lowFat,
  intermittentFasting,
  glutenFree,
  dairyFree,
  // Additional preferences referenced in onboarding
  nutFree,
  lowSodium,
  diabetic,
  custom
}

enum HealthCondition {
  none,
  diabetes,
  hypertension,
  heartDisease,
  arthritis,
  asthma,
  depression,
  anxiety,
  thyroidDisorder,
  foodAllergies,
  digestiveIssues,
  sleepApnea,
  chronicPain,
  custom
}

class HealthProfile {
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Basic Health Information
  final int? age;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final double? targetWeightKg;
  final ActivityLevel activityLevel;
  
  // Imperial unit properties (for UI display)
  double? get heightFeet => heightCm != null ? heightCm! / 30.48 : null;
  double? get heightInches => heightCm != null ? (heightCm! % 30.48) / 2.54 : null;
  double? get weightLbs => weightKg != null ? weightKg! * 2.20462 : null;
  double? get targetWeightLbs => targetWeightKg != null ? targetWeightKg! * 2.20462 : null;
  
  // Health Goals & Preferences
  final List<HealthGoalType> primaryGoals;
  final List<DietaryPreference> dietaryPreferences;
  final List<HealthCondition> healthConditions;
  final List<String> allergies;
  final List<String> medications;
  
  // Behavioral Patterns (tracked automatically)
  final Map<String, dynamic> mealPatterns; // Timing, frequency, portions
  final Map<String, dynamic> fastingPatterns; // Duration, frequency, success rate
  final Map<String, dynamic> exercisePatterns; // Type, duration, frequency
  final Map<String, dynamic> sleepPatterns; // Duration, quality, timing
  final Map<String, dynamic> appUsagePatterns; // Feature usage, engagement times
  
  // Preferences & Settings
  final bool receiveAdvice;
  final List<String> preferredAdviceCategories;
  final Map<String, dynamic> notificationPreferences;
  final String? timezone;
  final String? language;
  
  // AI Learning Data
  final Map<String, int> adviceFeedback; // advice_id -> rating (-1, 0, 1)
  final List<String> dismissedAdviceTypes;
  final Map<String, dynamic> personalizedInsights;
  final double? engagementScore;
  
  // Calculated Metrics
  final double? bmr; // Basal Metabolic Rate
  final double? tdee; // Total Daily Energy Expenditure
  final Map<String, double> healthScores; // Various health metrics (0-100)
  
  // Conversion methods
  static double feetInchesToCm(int feet, double inches) {
    return (feet * 30.48) + (inches * 2.54);
  }
  
  static double lbsToKg(double lbs) {
    return lbs / 2.20462;
  }

  const HealthProfile({
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.targetWeightKg,
    this.activityLevel = ActivityLevel.moderatelyActive,
    this.primaryGoals = const [],
    this.dietaryPreferences = const [],
    this.healthConditions = const [],
    this.allergies = const [],
    this.medications = const [],
    this.mealPatterns = const {},
    this.fastingPatterns = const {},
    this.exercisePatterns = const {},
    this.sleepPatterns = const {},
    this.appUsagePatterns = const {},
    this.receiveAdvice = true,
    this.preferredAdviceCategories = const [],
    this.notificationPreferences = const {},
    this.timezone,
    this.language,
    this.adviceFeedback = const {},
    this.dismissedAdviceTypes = const [],
    this.personalizedInsights = const {},
    this.engagementScore,
    this.bmr,
    this.tdee,
    this.healthScores = const {},
  });

  // Factory constructor from Firestore document
  factory HealthProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HealthProfile(
      userId: doc.id,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      age: data['age'],
      gender: data['gender'],
      heightCm: data['heightCm']?.toDouble(),
      weightKg: data['weightKg']?.toDouble(),
      targetWeightKg: data['targetWeightKg']?.toDouble(),
      activityLevel: ActivityLevel.values.firstWhere(
        (level) => level.name == data['activityLevel'],
        orElse: () => ActivityLevel.moderatelyActive,
      ),
      primaryGoals: (data['primaryGoals'] as List<dynamic>?)
          ?.map((goal) => HealthGoalType.values.firstWhere(
                (type) => type.name == goal,
                orElse: () => HealthGoalType.custom,
              ))
          .toList() ?? [],
      dietaryPreferences: (data['dietaryPreferences'] as List<dynamic>?)
          ?.map((pref) => DietaryPreference.values.firstWhere(
                (type) => type.name == pref,
                orElse: () => DietaryPreference.custom,
              ))
          .toList() ?? [],
      healthConditions: (data['healthConditions'] as List<dynamic>?)
          ?.map((condition) => HealthCondition.values.firstWhere(
                (type) => type.name == condition,
                orElse: () => HealthCondition.custom,
              ))
          .toList() ?? [],
      allergies: List<String>.from(data['allergies'] ?? []),
      medications: List<String>.from(data['medications'] ?? []),
      mealPatterns: Map<String, dynamic>.from(data['mealPatterns'] ?? {}),
      fastingPatterns: Map<String, dynamic>.from(data['fastingPatterns'] ?? {}),
      exercisePatterns: Map<String, dynamic>.from(data['exercisePatterns'] ?? {}),
      sleepPatterns: Map<String, dynamic>.from(data['sleepPatterns'] ?? {}),
      appUsagePatterns: Map<String, dynamic>.from(data['appUsagePatterns'] ?? {}),
      receiveAdvice: data['receiveAdvice'] ?? true,
      preferredAdviceCategories: List<String>.from(data['preferredAdviceCategories'] ?? []),
      notificationPreferences: Map<String, dynamic>.from(data['notificationPreferences'] ?? {}),
      timezone: data['timezone'],
      language: data['language'],
      adviceFeedback: Map<String, int>.from(data['adviceFeedback'] ?? {}),
      dismissedAdviceTypes: List<String>.from(data['dismissedAdviceTypes'] ?? []),
      personalizedInsights: Map<String, dynamic>.from(data['personalizedInsights'] ?? {}),
      engagementScore: data['engagementScore']?.toDouble(),
      bmr: data['bmr']?.toDouble(),
      tdee: data['tdee']?.toDouble(),
      healthScores: Map<String, double>.from(
        (data['healthScores'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, value.toDouble()),
        ) ?? {},
      ),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'age': age,
      'gender': gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'targetWeightKg': targetWeightKg,
      'activityLevel': activityLevel.name,
      'primaryGoals': primaryGoals.map((goal) => goal.name).toList(),
      'dietaryPreferences': dietaryPreferences.map((pref) => pref.name).toList(),
      'healthConditions': healthConditions.map((condition) => condition.name).toList(),
      'allergies': allergies,
      'medications': medications,
      'mealPatterns': mealPatterns,
      'fastingPatterns': fastingPatterns,
      'exercisePatterns': exercisePatterns,
      'sleepPatterns': sleepPatterns,
      'appUsagePatterns': appUsagePatterns,
      'receiveAdvice': receiveAdvice,
      'preferredAdviceCategories': preferredAdviceCategories,
      'notificationPreferences': notificationPreferences,
      'timezone': timezone,
      'language': language,
      'adviceFeedback': adviceFeedback,
      'dismissedAdviceTypes': dismissedAdviceTypes,
      'personalizedInsights': personalizedInsights,
      'engagementScore': engagementScore,
      'bmr': bmr,
      'tdee': tdee,
      'healthScores': healthScores,
    };
  }



  // Calculate BMR using Mifflin-St Jeor Equation
  double? calculateBMR() {
    if (weightKg == null || heightCm == null || age == null || gender == null) return null;
    
    if (gender!.toLowerCase() == 'male') {
      return (10 * weightKg!) + (6.25 * heightCm!) - (5 * age!) + 5;
    } else {
      return (10 * weightKg!) + (6.25 * heightCm!) - (5 * age!) - 161;
    }
  }

  // Calculate TDEE (Total Daily Energy Expenditure)
  double? calculateTDEE() {
    final bmrValue = calculateBMR();
    if (bmrValue == null) return null;
    
    switch (activityLevel) {
      case ActivityLevel.sedentary:
        return bmrValue * 1.2;
      case ActivityLevel.lightlyActive:
        return bmrValue * 1.375;
      case ActivityLevel.moderatelyActive:
        return bmrValue * 1.55;
      case ActivityLevel.veryActive:
        return bmrValue * 1.725;
      case ActivityLevel.extremelyActive:
        return bmrValue * 1.9;
    }
  }



  // Copy with method for updates
  HealthProfile copyWith({
    DateTime? updatedAt,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    ActivityLevel? activityLevel,
    List<HealthGoalType>? primaryGoals,
    List<DietaryPreference>? dietaryPreferences,
    List<HealthCondition>? healthConditions,
    List<String>? allergies,
    List<String>? medications,
    Map<String, dynamic>? mealPatterns,
    Map<String, dynamic>? fastingPatterns,
    Map<String, dynamic>? exercisePatterns,
    Map<String, dynamic>? sleepPatterns,
    Map<String, dynamic>? appUsagePatterns,
    bool? receiveAdvice,
    List<String>? preferredAdviceCategories,
    Map<String, dynamic>? notificationPreferences,
    String? timezone,
    String? language,
    Map<String, int>? adviceFeedback,
    List<String>? dismissedAdviceTypes,
    Map<String, dynamic>? personalizedInsights,
    double? engagementScore,
    Map<String, double>? healthScores,
  }) {
    return HealthProfile(
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      primaryGoals: primaryGoals ?? this.primaryGoals,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      healthConditions: healthConditions ?? this.healthConditions,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      mealPatterns: mealPatterns ?? this.mealPatterns,
      fastingPatterns: fastingPatterns ?? this.fastingPatterns,
      exercisePatterns: exercisePatterns ?? this.exercisePatterns,
      sleepPatterns: sleepPatterns ?? this.sleepPatterns,
      appUsagePatterns: appUsagePatterns ?? this.appUsagePatterns,
      receiveAdvice: receiveAdvice ?? this.receiveAdvice,
      preferredAdviceCategories: preferredAdviceCategories ?? this.preferredAdviceCategories,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
      timezone: timezone ?? this.timezone,
      language: language ?? this.language,
      adviceFeedback: adviceFeedback ?? this.adviceFeedback,
      dismissedAdviceTypes: dismissedAdviceTypes ?? this.dismissedAdviceTypes,
      personalizedInsights: personalizedInsights ?? this.personalizedInsights,
      engagementScore: engagementScore ?? this.engagementScore,
      bmr: calculateBMR(),
      tdee: calculateTDEE(),
      healthScores: healthScores ?? this.healthScores,
    );
  }

  // Utility methods for display
  String get activityLevelDisplayName {
    switch (activityLevel) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
      case ActivityLevel.extremelyActive:
        return 'Extremely Active';
    }
  }

  List<String> get primaryGoalsDisplayNames {
    return primaryGoals.map((goal) {
      switch (goal) {
        case HealthGoalType.weightLoss:
          return 'Weight Loss';
        case HealthGoalType.weightGain:
          return 'Weight Gain';
        case HealthGoalType.muscleGain:
          return 'Muscle Gain';
        case HealthGoalType.enduranceImprovement:
          return 'Endurance Improvement';
        case HealthGoalType.generalFitness:
          return 'General Fitness';
        case HealthGoalType.chronicDiseaseManagement:
          return 'Chronic Disease Management';
        case HealthGoalType.mentalWellness:
          return 'Mental Wellness';
        case HealthGoalType.nutritionImprovement:
          return 'Nutrition Improvement';
        case HealthGoalType.sleepImprovement:
          return 'Sleep Improvement';
        case HealthGoalType.stressReduction:
          return 'Stress Reduction';
        case HealthGoalType.habitBuilding:
          return 'Habit Building';
        case HealthGoalType.fatLoss:
          return 'Fat Loss';
        case HealthGoalType.intermittentFasting:
          return 'Intermittent Fasting';
        case HealthGoalType.improveMetabolism:
          return 'Improve Metabolism';
        case HealthGoalType.betterSleep:
          return 'Better Sleep';
        case HealthGoalType.increaseEnergy:
          return 'Increase Energy';
        case HealthGoalType.improveDigestion:
          return 'Improve Digestion';
        case HealthGoalType.longevity:
          return 'Longevity';
        case HealthGoalType.mentalClarity:
          return 'Mental Clarity';
        case HealthGoalType.custom:
          return 'Custom Goal';
      }
    }).toList();
  }

  // Convenience getters for backward compatibility
  double? get currentWeight => weightKg;
  double? get targetWeight => targetWeightKg;
  List<HealthGoalType> get healthGoals => primaryGoals;
  String? get name => gender != null ? 'User' : null; // Placeholder name
} 