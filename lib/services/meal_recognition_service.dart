/// Meal Recognition Service for SnapAMeal Phase II
/// Provides AI-powered food detection, calorie estimation, and nutrition analysis
library;

import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:developer' as developer;
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'package:flutter/services.dart';
import '../models/meal_log.dart';

import 'openai_service.dart';
import 'rag_service.dart';

import '../services/usda_nutrition_service.dart';

/// Comprehensive meal recognition service with AI-powered analysis
class MealRecognitionService {
  static const int _inputSize = 224;
  static const int _maxDetections = 5;

  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isInitialized = false;

  final OpenAIService _openAIService;
  final RAGService _ragService;
  final USDANutritionService _usdaService;

  // Fields to store meal type information between method calls
  MealType? _lastMealType;
  double? _lastMealTypeConfidence;
  String? _lastMealTypeReason;

  MealRecognitionService(this._openAIService, this._ragService)
      : _usdaService = USDANutritionService();

  /// Initialize the meal recognition service
  Future<bool> initialize() async {
    try {
      developer.log('Initializing MealRecognitionService...');

      // Load TensorFlow Lite model
      await _loadModel();

      // Load food labels
      await _loadLabels();

      _isInitialized = true;
      developer.log('MealRecognitionService initialized successfully');
      return true;
    } catch (e) {
      developer.log('Failed to initialize MealRecognitionService: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Load the TensorFlow Lite model
  Future<void> _loadModel() async {
    try {
      // For now, we'll use a pre-trained MobileNet model
      // In production, this would be a custom-trained food classification model
      final options = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset(
        'models/mobilenet_v1_1.0_224.tflite',
        options: options,
      );
      developer.log('TensorFlow Lite model loaded successfully');
    } catch (e) {
      developer.log(
        'Failed to load TensorFlow model, using fallback nutrition estimation: $e',
      );
      // Fallback: We'll use OpenAI Vision API instead of local model
      _interpreter = null;
    }
  }

  /// Load food classification labels
  Future<void> _loadLabels() async {
    try {
      final labelData = await rootBundle.loadString(
        'assets/models/food_labels.txt',
      );
      _labels = labelData
          .split('\n')
          .where((label) => label.isNotEmpty)
          .toList();
      developer.log('Loaded ${_labels?.length ?? 0} food labels');
    } catch (e) {
      developer.log(
        'Failed to load labels file, using default food categories: $e',
      );
      _labels = _getDefaultFoodCategories();
    }
  }

  /// Get default food categories if labels file is not available
  List<String> _getDefaultFoodCategories() {
    return [
      'pizza',
      'burger',
      'salad',
      'pasta',
      'sandwich',
      'soup',
      'chicken',
      'beef',
      'fish',
      'rice',
      'bread',
      'eggs',
      'fruit',
      'vegetables',
      'cheese',
      'yogurt',
      'cereal',
      'nuts',
      'beans',
      'pasta sauce',
    ];
  }

  /// Analyze a meal image and return recognition results
  Future<MealRecognitionResult> analyzeMealImage(String imagePath) async {
    if (!_isInitialized) {
      throw Exception('MealRecognitionService not initialized');
    }

    try {
      developer.log('Analyzing meal image: $imagePath');

      // Load and preprocess the image
      final imageFile = File(imagePath);
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      List<FoodItem> detectedFoods;
      MealType mealType;
      double mealTypeConfidence;
      String? mealTypeReason;

      // Temporarily disable TensorFlow Lite to use advanced OpenAI Vision API
      // with meal type classification and USDA nutrition integration
      if (false && _interpreter != null) {
        // Use TensorFlow Lite model for detection
        detectedFoods = await _detectFoodsWithTFLite(image);
        // Fallback meal type detection for TensorFlow
        mealType = _determineMealTypeFromFoods(detectedFoods);
        mealTypeConfidence = 0.7; // Lower confidence for heuristic-based detection
        mealTypeReason = 'Determined from food type analysis';
      } else {
        // Use OpenAI Vision API for advanced analysis
        detectedFoods = await _detectFoodsWithOpenAI(imageBytes);
        
        // Use OpenAI's meal type classification
        mealType = _lastMealType ?? MealType.unknown;
        mealTypeConfidence = _lastMealTypeConfidence ?? 0.0;
        mealTypeReason = _lastMealTypeReason;
      }

      // Calculate total nutrition (always performed)
      final totalNutrition = _calculateTotalNutrition(detectedFoods);

      // Determine primary food category
      final primaryCategory = _determinePrimaryCategory(detectedFoods);

      // Check for allergen warnings
      final allergenWarnings = _checkAllergens(detectedFoods);

      // Calculate overall confidence score
      final confidenceScore = _calculateOverallConfidence(detectedFoods);

      final result = MealRecognitionResult(
        detectedFoods: detectedFoods,
        totalNutrition: totalNutrition,
        confidenceScore: confidenceScore,
        primaryFoodCategory: primaryCategory,
        allergenWarnings: allergenWarnings,
        analysisTimestamp: DateTime.now(),
        mealType: mealType,
        mealTypeConfidence: mealTypeConfidence,
        mealTypeReason: mealTypeReason,
      );

      developer.log(
        'Meal analysis completed: ${detectedFoods.length} foods detected, '
        'meal type: ${mealType.value} (${(mealTypeConfidence * 100).toInt()}% confidence)',
      );
      
      return result;
    } catch (e) {
      developer.log('Error analyzing meal image: $e');
      rethrow;
    }
  }

  /// Detect foods using TensorFlow Lite model
  Future<List<FoodItem>> _detectFoodsWithTFLite(img.Image image) async {
    try {
      // Preprocess image for model input
      final input = _preprocessImage(image);

      // Run inference
      final output = List.filled(
        _labels!.length,
        0.0,
      ).reshape([1, _labels!.length]);
      _interpreter!.run(input, output);

      // Parse results
      final List<FoodItem> detectedFoods = [];
      final scores = output[0] as List<double>;

      // Get top predictions
      final predictions = <MapEntry<int, double>>[];
      for (int i = 0; i < scores.length; i++) {
        predictions.add(MapEntry(i, scores[i]));
      }

      predictions.sort((a, b) => b.value.compareTo(a.value));

      // Convert top predictions to FoodItem objects
      for (int i = 0; i < math.min(_maxDetections, predictions.length); i++) {
        final prediction = predictions[i];
        if (prediction.value > 0.1) {
          // Confidence threshold
          final foodName = _labels![prediction.key];
          final nutrition = await estimateNutrition(
            foodName,
            100.0,
          ); // Default 100g

          detectedFoods.add(
            FoodItem(
              name: foodName,
              category: _categorizeFoodItem(foodName),
              confidence: prediction.value,
              nutrition: nutrition,
              estimatedWeight: 100.0,
              alternativeNames: _getAlternativeNames(foodName),
            ),
          );
        }
      }

      return detectedFoods;
    } catch (e) {
      developer.log('Error in TensorFlow Lite detection: $e');
      rethrow;
    }
  }

  /// Detect foods using OpenAI Vision API as fallback
  Future<List<FoodItem>> _detectFoodsWithOpenAI(Uint8List imageBytes) async {
    try {
      developer.log('Using OpenAI Vision API for food detection');

      // Convert image to base64
      final base64Image = base64Encode(imageBytes);

      // Create enhanced prompt for food detection with meal type classification
      final prompt = '''
Analyze this food image and provide a comprehensive analysis:

1. MEAL TYPE CLASSIFICATION:
   - "ingredients": Raw/uncooked ingredients that could be used to prepare a meal (raw chicken, vegetables, spices, uncooked pasta, etc.)
   - "ready_made": Fully prepared/cooked dishes ready to eat (pizza, burgers, cooked pasta dishes, sandwiches, etc.)
   - "mixed": Contains both ingredients and prepared items
   - "unknown": Cannot determine meal type

2. FOOD ITEM DETECTION:
   For each visible food item, provide:
   - Name of the food
   - Estimated portion size in grams
   - Confidence level (0-1)
   - Food category (protein, carbs, vegetables, dairy, etc.)
   - Preparation state (raw, cooked, processed)

Format the response as JSON with this exact structure:
{
  "meal_type": "ingredients|ready_made|mixed|unknown",
  "meal_type_confidence": 0.85,
  "meal_type_reason": "Brief explanation of why this meal type was chosen",
  "foods": [
    {
      "name": "food name",
      "estimated_weight": 150.0,
      "confidence": 0.85,
      "category": "protein",
      "preparation_state": "raw|cooked|processed"
    }
  ]
}
''';

      // Use OpenAI to analyze the image
      final response = await _openAIService.analyzeImageWithPrompt(
        'data:image/jpeg;base64,$base64Image',
        prompt,
      );

      if (response == null) {
        throw Exception('No response from OpenAI Vision API');
      }

      // Parse the response - clean markdown code blocks if present
      String cleanResponse = response.trim();
      if (cleanResponse.startsWith('```json')) {
        cleanResponse = cleanResponse.substring(7); // Remove ```json
      }
      if (cleanResponse.startsWith('```')) {
        cleanResponse = cleanResponse.substring(3); // Remove ```
      }
      if (cleanResponse.endsWith('```')) {
        cleanResponse = cleanResponse.substring(0, cleanResponse.length - 3); // Remove trailing ```
      }
      cleanResponse = cleanResponse.trim();
      
      final analysisResult = jsonDecode(cleanResponse);
      final List<FoodItem> detectedFoods = [];

      // Store meal type information for later use
      _lastMealType = MealType.fromString(analysisResult['meal_type'] ?? 'unknown');
      _lastMealTypeConfidence = analysisResult['meal_type_confidence']?.toDouble() ?? 0.0;
      _lastMealTypeReason = analysisResult['meal_type_reason'];

      if (analysisResult['foods'] != null) {
        for (final foodData in analysisResult['foods']) {
          final nutrition = await estimateNutrition(
            foodData['name'],
            foodData['estimated_weight']?.toDouble() ?? 100.0,
          );

          final foodItem = FoodItem(
            name: foodData['name'],
            category: foodData['category'] ?? 'unknown',
            confidence: foodData['confidence']?.toDouble() ?? 0.5,
            nutrition: nutrition,
            estimatedWeight:
                foodData['estimated_weight']?.toDouble() ?? 100.0,
            alternativeNames: _getAlternativeNames(foodData['name']),
          );
          
          detectedFoods.add(foodItem);
        }
      }
      
      return detectedFoods;
    } catch (e) {
      developer.log('Error in OpenAI food detection: $e');
      
      // Return a generic food item as fallback
      return [await _createGenericFoodItem()];
    }
  }

  /// Preprocess image for TensorFlow Lite model input
  Float32List _preprocessImage(img.Image image) {
    // Resize image to model input size
    final resized = img.copyResize(
      image,
      width: _inputSize,
      height: _inputSize,
    );

    // Convert to Float32List and normalize
    final input = Float32List(_inputSize * _inputSize * 3);
    int pixelIndex = 0;

    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        // Extract RGB values from Pixel object
        input[pixelIndex++] = pixel.r / 255.0;
        input[pixelIndex++] = pixel.g / 255.0;
        input[pixelIndex++] = pixel.b / 255.0;
      }
    }

    return Float32List.fromList(input);
  }

  /// Estimate nutrition information for a food item
  /// Priority: USDA Database -> Local Database -> AI Estimation -> Default
  Future<NutritionInfo> estimateNutrition(
    String foodName,
    double weightGrams,
  ) async {
    try {
      // First, try USDA FoodData Central (most accurate)
      final usdaNutrition = await _usdaService.getNutritionForFood(foodName, weightGrams);
      if (usdaNutrition != null) {
        developer.log('Using USDA nutrition data for: $foodName');
        return usdaNutrition;
      }

      // Fallback to local database
      final localNutrition = _getNutritionFromDatabase(foodName, weightGrams);
      if (localNutrition != null) {
        developer.log('Using local nutrition data for: $foodName');
        return localNutrition;
      }

      // Fallback to AI-estimated nutrition
      developer.log('Using AI nutrition estimation for: $foodName');
      return await _estimateNutritionWithAI(foodName, weightGrams);
    } catch (e) {
      developer.log('Error estimating nutrition for $foodName: $e');
      return _getDefaultNutrition(weightGrams);
    }
  }

  /// Get nutrition data from local food database
  NutritionInfo? _getNutritionFromDatabase(
    String foodName,
    double weightGrams,
  ) {
    // This would integrate with a comprehensive food database like USDA FoodData Central
    // For now, return basic estimates for common foods
    final commonFoods = {
      'chicken breast': {
        'calories': 165,
        'protein': 31,
        'carbs': 0,
        'fat': 3.6,
      },
      'banana': {'calories': 89, 'protein': 1.1, 'carbs': 23, 'fat': 0.3},
      'rice': {'calories': 130, 'protein': 2.7, 'carbs': 28, 'fat': 0.3},
      'broccoli': {'calories': 34, 'protein': 2.8, 'carbs': 7, 'fat': 0.4},
      'salmon': {'calories': 208, 'protein': 22, 'carbs': 0, 'fat': 12},
      'apple': {'calories': 52, 'protein': 0.3, 'carbs': 14, 'fat': 0.2},
      'bread': {'calories': 265, 'protein': 9, 'carbs': 49, 'fat': 3.2},
      'egg': {'calories': 155, 'protein': 13, 'carbs': 1.1, 'fat': 11},
    };

    final lowerFoodName = foodName.toLowerCase();
    for (final entry in commonFoods.entries) {
      if (lowerFoodName.contains(entry.key)) {
        final baseNutrition = entry.value;
        final scaleFactor = weightGrams / 100.0; // Base values are per 100g

        return NutritionInfo(
          calories: (baseNutrition['calories']! * scaleFactor),
          protein: (baseNutrition['protein']! * scaleFactor),
          carbs: (baseNutrition['carbs']! * scaleFactor),
          fat: (baseNutrition['fat']! * scaleFactor),
          fiber: (baseNutrition['fiber'] ?? 2.0) * scaleFactor,
          sugar: (baseNutrition['sugar'] ?? 5.0) * scaleFactor,
          sodium: (baseNutrition['sodium'] ?? 50.0) * scaleFactor,
          servingSize: weightGrams,
          vitamins: {},
          minerals: {},
        );
      }
    }

    return null;
  }

  /// Estimate nutrition using AI
  Future<NutritionInfo> _estimateNutritionWithAI(
    String foodName,
    double weightGrams,
  ) async {
    try {
      final prompt =
          '''
Provide detailed nutrition information for ${weightGrams}g of $foodName.
Return the response as JSON with this exact structure:
{
  "calories": 0.0,
  "protein": 0.0,
  "carbs": 0.0,
  "fat": 0.0,
  "fiber": 0.0,
  "sugar": 0.0,
  "sodium": 0.0
}

All values should be numbers (not strings) and represent the total amount for the specified weight.
''';

      final response = await _openAIService.getChatCompletion(prompt);
      if (response != null) {
        final nutritionData = jsonDecode(response);
        return NutritionInfo(
          calories: nutritionData['calories']?.toDouble() ?? 0.0,
          protein: nutritionData['protein']?.toDouble() ?? 0.0,
          carbs: nutritionData['carbs']?.toDouble() ?? 0.0,
          fat: nutritionData['fat']?.toDouble() ?? 0.0,
          fiber: nutritionData['fiber']?.toDouble() ?? 0.0,
          sugar: nutritionData['sugar']?.toDouble() ?? 0.0,
          sodium: nutritionData['sodium']?.toDouble() ?? 0.0,
          servingSize: weightGrams,
          vitamins: {},
          minerals: {},
        );
      }
    } catch (e) {
      developer.log('Error getting AI nutrition estimate: $e');
    }

    return _getDefaultNutrition(weightGrams);
  }

  /// Get default nutrition estimation
  NutritionInfo _getDefaultNutrition(double weightGrams) {
    // Very basic estimation - 4 cal/g for protein/carbs, 9 cal/g for fat
    final estimatedCalories = weightGrams * 2.0; // Rough average
    return NutritionInfo(
      calories: estimatedCalories,
      protein: estimatedCalories * 0.15 / 4, // 15% protein
      carbs: estimatedCalories * 0.50 / 4, // 50% carbs
      fat: estimatedCalories * 0.35 / 9, // 35% fat
      fiber: weightGrams * 0.02,
      sugar: weightGrams * 0.05,
      sodium: weightGrams * 0.5,
      servingSize: weightGrams,
      vitamins: {},
      minerals: {},
    );
  }

  /// Calculate total nutrition from all detected foods
  NutritionInfo _calculateTotalNutrition(List<FoodItem> foods) {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;
    double totalSugar = 0;
    double totalSodium = 0;

    for (final food in foods) {
      totalCalories += food.nutrition.calories;
      totalProtein += food.nutrition.protein;
      totalCarbs += food.nutrition.carbs;
      totalFat += food.nutrition.fat;
      totalFiber += food.nutrition.fiber;
      totalSugar += food.nutrition.sugar;
      totalSodium += food.nutrition.sodium;
    }

    return NutritionInfo(
      calories: totalCalories,
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
      fiber: totalFiber,
      sugar: totalSugar,
      sodium: totalSodium,
      servingSize: foods.fold(
        0.0,
        (sum, food) => sum + food.nutrition.servingSize,
      ),
      vitamins: {},
      minerals: {},
    );
  }

  /// Determine the primary food category
  String _determinePrimaryCategory(List<FoodItem> foods) {
    if (foods.isEmpty) return 'unknown';

    final categoryWeights = <String, double>{};
    for (final food in foods) {
      categoryWeights[food.category] =
          (categoryWeights[food.category] ?? 0) + food.confidence;
    }

    return categoryWeights.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Check for common allergens
  List<String> _checkAllergens(List<FoodItem> foods) {
    final Set<String> allergens = {};

    final allergenMap = {
      'nuts': ['almond', 'peanut', 'walnut', 'cashew', 'pecan', 'hazelnut'],
      'dairy': ['milk', 'cheese', 'butter', 'cream', 'yogurt'],
      'gluten': ['wheat', 'bread', 'pasta', 'flour', 'cereal'],
      'shellfish': ['shrimp', 'crab', 'lobster', 'oyster', 'clam'],
      'eggs': ['egg', 'mayonnaise'],
      'soy': ['soy', 'tofu', 'edamame'],
    };

    for (final food in foods) {
      final foodName = food.name.toLowerCase();
      for (final allergen in allergenMap.entries) {
        for (final trigger in allergen.value) {
          if (foodName.contains(trigger)) {
            allergens.add(allergen.key);
            break;
          }
        }
      }
    }

    return allergens.toList();
  }

  /// Calculate overall confidence score
  double _calculateOverallConfidence(List<FoodItem> foods) {
    if (foods.isEmpty) return 0.0;

    double totalConfidence = 0;
    for (final food in foods) {
      totalConfidence += food.confidence;
    }

    return totalConfidence / foods.length;
  }

  /// Categorize a food item
  String _categorizeFoodItem(String foodName) {
    final name = foodName.toLowerCase();

    if (name.contains('chicken') ||
        name.contains('beef') ||
        name.contains('fish') ||
        name.contains('pork') ||
        name.contains('egg')) {
      return 'protein';
    } else if (name.contains('rice') ||
        name.contains('bread') ||
        name.contains('pasta') ||
        name.contains('potato') ||
        name.contains('cereal')) {
      return 'carbohydrates';
    } else if (name.contains('broccoli') ||
        name.contains('spinach') ||
        name.contains('carrot') ||
        name.contains('lettuce') ||
        name.contains('tomato')) {
      return 'vegetables';
    } else if (name.contains('apple') ||
        name.contains('banana') ||
        name.contains('orange') ||
        name.contains('berry') ||
        name.contains('grape')) {
      return 'fruits';
    } else if (name.contains('cheese') ||
        name.contains('milk') ||
        name.contains('yogurt')) {
      return 'dairy';
    } else if (name.contains('oil') ||
        name.contains('butter') ||
        name.contains('nut')) {
      return 'fats';
    }

    return 'other';
  }

  /// Get alternative names for a food item
  List<String> _getAlternativeNames(String foodName) {
    final alternatives = <String, List<String>>{
      'chicken': ['poultry', 'fowl'],
      'beef': ['steak', 'ground beef', 'hamburger'],
      'fish': ['seafood', 'salmon', 'tuna'],
      'rice': ['grain', 'brown rice', 'white rice'],
      'bread': ['toast', 'roll', 'bun'],
      'apple': ['fruit'],
      'banana': ['fruit'],
      'broccoli': ['vegetable', 'green vegetable'],
    };

    final name = foodName.toLowerCase();
    for (final entry in alternatives.entries) {
      if (name.contains(entry.key)) {
        return entry.value;
      }
    }

    return [];
  }

  /// Determine meal type from detected foods (fallback for TensorFlow)
  MealType _determineMealTypeFromFoods(List<FoodItem> foods) {
    if (foods.isEmpty) return MealType.unknown;

    int rawIngredients = 0;
    int cookedItems = 0;

    for (final food in foods) {
      final name = food.name.toLowerCase();
      
      // Check for raw ingredients indicators
      if (name.contains('raw') || 
          name.contains('fresh') ||
          name.contains('uncooked') ||
          _isTypicalRawIngredient(name)) {
        rawIngredients++;
      }
      // Check for cooked/prepared food indicators  
      else if (name.contains('cooked') ||
               name.contains('grilled') ||
               name.contains('fried') ||
               name.contains('baked') ||
               _isTypicalPreparedFood(name)) {
        cookedItems++;
      }
    }

    // Determine meal type based on ingredient analysis
    if (rawIngredients > cookedItems) {
      return MealType.ingredients;
    } else if (cookedItems > rawIngredients) {
      return MealType.readyMade;
    } else if (rawIngredients > 0 && cookedItems > 0) {
      return MealType.mixed;
    }
    
    return MealType.unknown;
  }

  /// Helper method to identify typical raw ingredients
  bool _isTypicalRawIngredient(String foodName) {
    const rawIngredients = [
      'chicken breast', 'ground beef', 'salmon fillet',
      'broccoli', 'carrot', 'onion', 'garlic', 'spinach',
      'rice', 'pasta', 'flour', 'egg',
      'olive oil', 'salt', 'pepper', 'herbs', 'spices'
    ];
    
    return rawIngredients.any((ingredient) => 
      foodName.contains(ingredient));
  }

  /// Helper method to identify typical prepared foods
  bool _isTypicalPreparedFood(String foodName) {
    const preparedFoods = [
      'pizza', 'burger', 'sandwich', 'salad',
      'soup', 'stew', 'casserole', 'pasta dish',
      'stir fry', 'curry', 'taco', 'burrito'
    ];
    
    return preparedFoods.any((food) => 
      foodName.contains(food));
  }

  /// Create a generic food item as fallback
  Future<FoodItem> _createGenericFoodItem() async {
    final nutrition = _getDefaultNutrition(100.0);
    return FoodItem(
      name: 'Mixed Food',
      category: 'mixed',
      confidence: 0.3,
      nutrition: nutrition,
      estimatedWeight: 100.0,
      alternativeNames: ['food', 'meal'],
    );
  }

  /// Generate AI caption for a meal
  Future<String> generateMealCaption(
    MealRecognitionResult result,
    String captionType,
  ) async {
    try {
      final foods = result.detectedFoods.map((f) => f.name).join(', ');
      final totalCals = result.totalNutrition.calories.round();

      String prompt;
      switch (captionType.toLowerCase()) {
        case 'witty':
          prompt =
              '''
Generate a witty, humorous caption for a meal containing: $foods
Total calories: $totalCals
Keep it under 100 characters and make it engaging and fun.
''';
          break;
        case 'motivational':
          prompt =
              '''
Generate an encouraging, motivational caption for a meal containing: $foods
Total calories: $totalCals
Focus on healthy eating and fitness goals. Keep it under 100 characters.
''';
          break;
        case 'health_tip':
          prompt =
              '''
Generate a helpful health tip based on this meal: $foods
Total calories: $totalCals
Provide useful nutritional or wellness advice. Keep it under 150 characters.
''';
          break;
        default:
          prompt =
              '''
Generate a simple, descriptive caption for this meal: $foods
Total calories: $totalCals
Keep it informative and under 100 characters.
''';
      }

      final response = await _openAIService.getChatCompletion(prompt);
      return response?.trim() ?? 'Delicious meal! 🍽️';
    } catch (e) {
      developer.log('Error generating meal caption: $e');
      return 'Enjoy your meal! 🍽️';
    }
  }

  /// Generate recipe suggestions based on meal content
  Future<List<RecipeSuggestion>> generateRecipeSuggestions(
    MealRecognitionResult result,
  ) async {
    try {
      final detectedFoods = result.detectedFoods.map((f) => f.name).toList();

      // Create health context (simplified for now)
      final healthContext = HealthQueryContext(
        userId: 'current_user', // This should come from auth
        queryType: 'meal_analysis',
        userProfile: {'fitnessLevel': 'moderate', 'healthConditions': []},
        currentGoals: ['healthy_eating', 'nutrition'],
        dietaryRestrictions: [],
        recentActivity: {
          'lastMeal': DateTime.now()
              .subtract(Duration(hours: 3))
              .toIso8601String(),
          'exerciseToday': false,
        },
        contextTimestamp: DateTime.now(),
      );

      // Use enhanced RAG recipe search
      final recipeResults = await _ragService.searchRecipeSuggestions(
        detectedFoods: detectedFoods,
        healthContext: healthContext,
        maxResults: 5,
      );

      // Generate personalized recommendations
      final recipeText = await _ragService.generateRecipeRecommendations(
        detectedFoods: detectedFoods,
        healthContext: healthContext,
        recipeResults: recipeResults,
      );

      final suggestions = <RecipeSuggestion>[];

      // Try to parse AI-generated suggestions first
      if (recipeText != null && recipeText.isNotEmpty) {
        final aiSuggestions = _parseAIRecipeSuggestions(recipeText, result);
        suggestions.addAll(aiSuggestions);
      }

      // Fallback to knowledge base results if AI parsing fails
      if (suggestions.isEmpty && recipeResults.isNotEmpty) {
        final fallbackSuggestions = _createFallbackRecipeSuggestions(
          recipeResults,
          result,
        );
        suggestions.addAll(fallbackSuggestions);
      }

      return suggestions.take(3).toList();
    } catch (e) {
      developer.log('Error generating recipe suggestions: $e');
      return [];
    }
  }

  /// Parse AI-generated recipe text into structured suggestions
  List<RecipeSuggestion> _parseAIRecipeSuggestions(
    String recipeText,
    MealRecognitionResult result,
  ) {
    final suggestions = <RecipeSuggestion>[];

    // Split by numbered items or clear breaks
    final sections = recipeText.split(RegExp(r'\d+\.|\n\n+'));

    for (int i = 0; i < sections.length; i++) {
      final section = sections[i].trim();
      if (section.length > 50) {
        // Minimum meaningful content
        final title = _extractRecipeTitle(section);
        suggestions.add(
          RecipeSuggestion(
            id: 'ai_recipe_${DateTime.now().millisecondsSinceEpoch}_$i',
            title: title,
            description: section.length > 200
                ? '${section.substring(0, 200)}...'
                : section,
            ingredients: result.detectedFoods.map((f) => f.name).toList(),
            instructions: [section],
            estimatedNutrition: result.totalNutrition,
            prepTimeMinutes: 20,
            cookTimeMinutes: 30,
            servings: 4,
            healthScore: 80.0,
            tags: [result.primaryFoodCategory, 'healthy', 'ai_generated'],
            source: 'AI Generated',
          ),
        );
      }
    }

    return suggestions;
  }

  /// Create fallback suggestions from search results
  List<RecipeSuggestion> _createFallbackRecipeSuggestions(
    List<SearchResult> results,
    MealRecognitionResult mealResult,
  ) {
    return results
        .map(
          (result) => RecipeSuggestion(
            id: 'kb_recipe_${result.document.id}',
            title: result.document.title,
            description: result.document.content.length > 200
                ? '${result.document.content.substring(0, 200)}...'
                : result.document.content,
            ingredients: mealResult.detectedFoods.map((f) => f.name).toList(),
            instructions: [result.document.content],
            estimatedNutrition: mealResult.totalNutrition,
            prepTimeMinutes: 25,
            cookTimeMinutes: 35,
            servings: 4,
            healthScore: result.document.confidenceScore * 100,
            tags: [result.document.category, 'knowledge_base'],
            source: result.document.source,
          ),
        )
        .toList();
  }

  /// Extract recipe title from text
  String _extractRecipeTitle(String text) {
    final lines = text.split('\n');
    final firstLine = lines.first.trim();

    // Clean up the title
    final cleaned = firstLine
        .replaceAll(RegExp(r'^\d+\.?\s*'), '') // Remove numbering
        .replaceAll(
          RegExp(r'^Recipe:?\s*', caseSensitive: false),
          '',
        ) // Remove "Recipe:"
        .split('.')
        .first // Take first sentence
        .split(':')
        .first; // Take part before colon

    return cleaned.length > 60 ? '${cleaned.substring(0, 60)}...' : cleaned;
  }

  /// Dispose of resources
  void dispose() {
    _interpreter?.close();
    _usdaService.clearExpiredCache();
    _isInitialized = false;
  }

  /// Get USDA service cache statistics
  Map<String, int> getUSDAStats() {
    return _usdaService.getCacheStats();
  }
}
