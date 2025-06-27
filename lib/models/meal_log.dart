import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a meal logged by the user with AI analysis
class MealLog {
  final String id;
  final String userId;
  final String imagePath;
  final String imageUrl;
  final DateTime timestamp;
  final MealRecognitionResult recognitionResult;
  final String? userCaption;
  final String? aiCaption;
  final List<String> tags;
  final MoodRating? moodRating;
  final HungerLevel? hungerLevel;
  final List<RecipeSuggestion>? recipeSuggestions;
  final Map<String, dynamic> metadata;
  final String? myFitnessPalFoodId; // For MyFitnessPal integration

  MealLog({
    required this.id,
    required this.userId,
    required this.imagePath,
    required this.imageUrl,
    required this.timestamp,
    required this.recognitionResult,
    this.userCaption,
    this.aiCaption,
    required this.tags,
    this.moodRating,
    this.hungerLevel,
    this.recipeSuggestions,
    required this.metadata,
    this.myFitnessPalFoodId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'image_path': imagePath,
      'image_url': imageUrl,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'recognition_result': recognitionResult.toJson(),
      'user_caption': userCaption,
      'ai_caption': aiCaption,
      'tags': tags,
      'mood_rating': moodRating?.toJson(),
      'hunger_level': hungerLevel?.toJson(),
      'recipe_suggestions': recipeSuggestions?.map((r) => r.toJson()).toList(),
      'metadata': metadata,
      'myfitnesspal_food_id': myFitnessPalFoodId,
    };
  }

  factory MealLog.fromJson(Map<String, dynamic> json) {
    return MealLog(
      id: json['id'],
      userId: json['user_id'],
      imagePath: json['image_path'],
      imageUrl: json['image_url'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      recognitionResult: MealRecognitionResult.fromJson(
        json['recognition_result'],
      ),
      userCaption: json['user_caption'],
      aiCaption: json['ai_caption'],
      tags: List<String>.from(json['tags'] ?? []),
      moodRating: json['mood_rating'] != null
          ? MoodRating.fromJson(json['mood_rating'])
          : null,
      hungerLevel: json['hunger_level'] != null
          ? HungerLevel.fromJson(json['hunger_level'])
          : null,
      recipeSuggestions: json['recipe_suggestions'] != null
          ? (json['recipe_suggestions'] as List)
                .map((r) => RecipeSuggestion.fromJson(r))
                .toList()
          : null,
      metadata: json['metadata'] ?? {},
      myFitnessPalFoodId: json['myfitnesspal_food_id'],
    );
  }

  factory MealLog.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return MealLog.fromJson(data);
  }
}

/// Result of AI meal recognition analysis
class MealRecognitionResult {
  final List<FoodItem> detectedFoods;
  final NutritionInfo totalNutrition;
  final double confidenceScore;
  final String primaryFoodCategory;
  final List<String> allergenWarnings;
  final DateTime analysisTimestamp;

  MealRecognitionResult({
    required this.detectedFoods,
    required this.totalNutrition,
    required this.confidenceScore,
    required this.primaryFoodCategory,
    required this.allergenWarnings,
    required this.analysisTimestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'detected_foods': detectedFoods.map((f) => f.toJson()).toList(),
      'total_nutrition': totalNutrition.toJson(),
      'confidence_score': confidenceScore,
      'primary_food_category': primaryFoodCategory,
      'allergen_warnings': allergenWarnings,
      'analysis_timestamp': analysisTimestamp.millisecondsSinceEpoch,
    };
  }

  factory MealRecognitionResult.fromJson(Map<String, dynamic> json) {
    return MealRecognitionResult(
      detectedFoods: (json['detected_foods'] as List)
          .map((f) => FoodItem.fromJson(f))
          .toList(),
      totalNutrition: NutritionInfo.fromJson(json['total_nutrition']),
      confidenceScore: json['confidence_score']?.toDouble() ?? 0.0,
      primaryFoodCategory: json['primary_food_category'],
      allergenWarnings: List<String>.from(json['allergen_warnings'] ?? []),
      analysisTimestamp: DateTime.fromMillisecondsSinceEpoch(
        json['analysis_timestamp'],
      ),
    );
  }
}

/// Individual food item detected in the meal
class FoodItem {
  final String name;
  final String category;
  final double confidence;
  final NutritionInfo nutrition;
  final double estimatedWeight; // in grams
  final BoundingBox? boundingBox;
  final List<String> alternativeNames;

  FoodItem({
    required this.name,
    required this.category,
    required this.confidence,
    required this.nutrition,
    required this.estimatedWeight,
    this.boundingBox,
    required this.alternativeNames,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'confidence': confidence,
      'nutrition': nutrition.toJson(),
      'estimated_weight': estimatedWeight,
      'bounding_box': boundingBox?.toJson(),
      'alternative_names': alternativeNames,
    };
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'],
      category: json['category'],
      confidence: json['confidence']?.toDouble() ?? 0.0,
      nutrition: NutritionInfo.fromJson(json['nutrition']),
      estimatedWeight: json['estimated_weight']?.toDouble() ?? 0.0,
      boundingBox: json['bounding_box'] != null
          ? BoundingBox.fromJson(json['bounding_box'])
          : null,
      alternativeNames: List<String>.from(json['alternative_names'] ?? []),
    );
  }
}

/// Nutritional information for food items
class NutritionInfo {
  final double calories;
  final double protein; // grams
  final double carbs; // grams
  final double fat; // grams
  final double fiber; // grams
  final double sugar; // grams
  final double sodium; // mg
  final double servingSize; // serving size in grams
  final Map<String, double> vitamins; // vitamin -> amount
  final Map<String, double> minerals; // mineral -> amount

  NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.servingSize,
    required this.vitamins,
    required this.minerals,
  });

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'serving_size': servingSize,
      'vitamins': vitamins,
      'minerals': minerals,
    };
  }

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      calories: json['calories']?.toDouble() ?? 0.0,
      protein: json['protein']?.toDouble() ?? 0.0,
      carbs: json['carbs']?.toDouble() ?? 0.0,
      fat: json['fat']?.toDouble() ?? 0.0,
      fiber: json['fiber']?.toDouble() ?? 0.0,
      sugar: json['sugar']?.toDouble() ?? 0.0,
      sodium: json['sodium']?.toDouble() ?? 0.0,
      servingSize: json['serving_size']?.toDouble() ?? 100.0,
      vitamins: Map<String, double>.from(json['vitamins'] ?? {}),
      minerals: Map<String, double>.from(json['minerals'] ?? {}),
    );
  }

  /// Calculate total macros percentage breakdown
  Map<String, double> get macroPercentages {
    final totalCals = calories;
    if (totalCals == 0) return {'protein': 0, 'carbs': 0, 'fat': 0};

    return {
      'protein': (protein * 4) / totalCals * 100,
      'carbs': (carbs * 4) / totalCals * 100,
      'fat': (fat * 9) / totalCals * 100,
    };
  }
}

/// Bounding box for detected food items
class BoundingBox {
  final double x;
  final double y;
  final double width;
  final double height;

  BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  Map<String, dynamic> toJson() {
    return {'x': x, 'y': y, 'width': width, 'height': height};
  }

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      x: json['x']?.toDouble() ?? 0.0,
      y: json['y']?.toDouble() ?? 0.0,
      width: json['width']?.toDouble() ?? 0.0,
      height: json['height']?.toDouble() ?? 0.0,
    );
  }
}

/// User mood rating for the meal
class MoodRating {
  final int rating; // 1-5 scale
  final String description;
  final DateTime timestamp;

  MoodRating({
    required this.rating,
    required this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory MoodRating.fromJson(Map<String, dynamic> json) {
    return MoodRating(
      rating: json['rating'],
      description: json['description'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }
}

/// User hunger level for the meal
class HungerLevel {
  final int level; // 1-5 scale (1=very hungry, 5=very full)
  final String description;
  final DateTime timestamp;

  HungerLevel({
    required this.level,
    required this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory HungerLevel.fromJson(Map<String, dynamic> json) {
    return HungerLevel(
      level: json['level'],
      description: json['description'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }
}

/// AI-generated recipe suggestion based on meal content
class RecipeSuggestion {
  final String id;
  final String title;
  final String description;
  final List<String> ingredients;
  final List<String> instructions;
  final NutritionInfo estimatedNutrition;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int servings;
  final double healthScore; // 0-100
  final List<String> tags;
  final String source;

  RecipeSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.estimatedNutrition,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.servings,
    required this.healthScore,
    required this.tags,
    required this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'estimated_nutrition': estimatedNutrition.toJson(),
      'prep_time_minutes': prepTimeMinutes,
      'cook_time_minutes': cookTimeMinutes,
      'servings': servings,
      'health_score': healthScore,
      'tags': tags,
      'source': source,
    };
  }

  factory RecipeSuggestion.fromJson(Map<String, dynamic> json) {
    return RecipeSuggestion(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
      estimatedNutrition: NutritionInfo.fromJson(json['estimated_nutrition']),
      prepTimeMinutes: json['prep_time_minutes'],
      cookTimeMinutes: json['cook_time_minutes'],
      servings: json['servings'],
      healthScore: json['health_score']?.toDouble() ?? 0.0,
      tags: List<String>.from(json['tags'] ?? []),
      source: json['source'],
    );
  }
}
