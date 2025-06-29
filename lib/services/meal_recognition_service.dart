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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/services.dart';
import '../models/meal_log.dart';
import '../utils/performance_monitor.dart';

import 'openai_service.dart';
import 'rag_service.dart';

import '../services/usda_nutrition_service.dart';

/// Exception thrown when the image doesn't contain food
class NonFoodImageException implements Exception {
  final String message;
  final String detectedContent;
  
  const NonFoodImageException(this.message, this.detectedContent);
  
  @override
  String toString() => 'NonFoodImageException: $message';
}

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
    final timer = PerformanceMonitor().startTimer('analyze_meal_image', 'meal_recognition', 
        metadata: {'image_path': imagePath});

    if (!_isInitialized) {
      timer.fail('Service not initialized');
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

      // Phase 2: Hybrid processing with OpenAI food validation first, then TensorFlow optimization
      // Always validate that the image contains food using OpenAI first
      developer.log('Starting food validation with OpenAI Vision API');
      
      // First, validate that the image contains food (this will throw NonFoodImageException if not)
      final openAIResults = await _detectFoodsWithOpenAI(imageBytes);
      mealType = _lastMealType ?? MealType.unknown;
      mealTypeConfidence = _lastMealTypeConfidence ?? 0.0;
      mealTypeReason = _lastMealTypeReason ?? 'OpenAI Vision analysis';
      
      // If we reach here, the image contains food - now decide on best detection method
      if (_interpreter != null) {
        developer.log('Image contains food, starting hybrid processing: TensorFlow Lite + OpenAI');
        
        try {
          // Second pass: TensorFlow Lite for fast food classification (we know it contains food)
          final tfLiteResults = await _detectFoodsWithTFLite(image);
          final avgConfidence = _calculateOverallConfidence(tfLiteResults);
          
          developer.log('TensorFlow Lite results: ${tfLiteResults.length} foods, avg confidence: ${(avgConfidence * 100).toInt()}%');
          
          // Check if TensorFlow Lite results meet confidence threshold
          if (avgConfidence >= 0.7 && tfLiteResults.isNotEmpty) {
            // High confidence TensorFlow Lite results - use them with OpenAI meal type
            detectedFoods = tfLiteResults;
            mealTypeReason = 'TensorFlow Lite food detection with OpenAI meal type classification';
            developer.log('Using TensorFlow Lite results (high confidence) with OpenAI meal type');
          } else {
            // Low confidence - use OpenAI results that we already have
            developer.log('TensorFlow Lite confidence low, using OpenAI results');
            detectedFoods = openAIResults;
            mealTypeReason = 'OpenAI analysis (TensorFlow confidence too low)';
          }
        } catch (e) {
          developer.log('TensorFlow Lite processing failed: $e, using OpenAI results');
          // Use OpenAI results that we already have
          detectedFoods = openAIResults;
          mealTypeReason = 'OpenAI analysis (TensorFlow failed)';
        }
      } else {
        // TensorFlow Lite not available - use OpenAI results that we already have
        developer.log('TensorFlow Lite not available, using OpenAI Vision API results');
        detectedFoods = openAIResults;
        mealTypeReason = 'OpenAI Vision analysis (TensorFlow not available)';
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
      
      timer.complete(additionalMetadata: {
        'foods_detected': detectedFoods.length,
        'confidence_score': confidenceScore,
        'meal_type': mealType.value,
      });
      
      return result;
    } catch (e) {
      developer.log('Error analyzing meal image: $e');
      timer.fail(e.toString());
      rethrow;
    }
  }

  /// Detect foods using TensorFlow Lite model
  Future<List<FoodItem>> _detectFoodsWithTFLite(img.Image image) async {
    final timer = PerformanceMonitor().startTimer('tensorflow_inference', 'tensorflow');
    
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
      final scores = output[0] as List;

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

      timer.complete(additionalMetadata: {'foods_detected': detectedFoods.length});
      return detectedFoods;
    } catch (e) {
      developer.log('Error in TensorFlow Lite detection: $e');
      timer.fail(e.toString());
      rethrow;
    }
  }

  /// Detect foods using OpenAI Vision API as fallback
  Future<List<FoodItem>> _detectFoodsWithOpenAI(Uint8List imageBytes) async {
    final timer = PerformanceMonitor().startTimer('vision_analysis', 'openai');
    
    try {
      developer.log('Using OpenAI Vision API for food detection');

      // Convert image to base64
      final base64Image = base64Encode(imageBytes);

      // Create enhanced prompt for food detection with food validation
      final prompt = '''
Analyze this image to determine if it contains food and provide a comprehensive analysis:

FIRST - FOOD VALIDATION:
Determine if this image actually contains food items, ingredients, meals, or beverages. 
If the image contains:
- People, animals, landscapes, objects, documents, text, screenshots, etc. WITHOUT food → set "contains_food": false
- Food items, meals, ingredients, beverages, or anything edible → set "contains_food": true

1. MEAL TYPE CLASSIFICATION (only if contains_food is true):
   - "ingredients": Raw/uncooked ingredients that could be used to prepare a meal (raw chicken, vegetables, spices, uncooked pasta, etc.)
   - "ready_made": Fully prepared/cooked dishes ready to eat (pizza, burgers, cooked pasta dishes, sandwiches, etc.)
   - "mixed": Contains both ingredients and prepared items
   - "unknown": Cannot determine meal type

2. FOOD ITEM DETECTION (only if contains_food is true):
   For each visible food item, provide:
   - Name of the food
   - Estimated portion size in grams
   - Confidence level (0-1)
   - Food category (protein, carbs, vegetables, dairy, etc.)
   - Preparation state (raw, cooked, processed)

Format the response as JSON with this exact structure:
{
  "contains_food": true/false,
  "detected_content": "Brief description of what you see in the image",
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

If contains_food is false, set meal_type to "unknown", meal_type_confidence to 0.0, and foods to an empty array.
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
      
      // Check if the image contains food
      final containsFood = analysisResult['contains_food'] ?? false;
      final detectedContent = analysisResult['detected_content'] ?? 'Unknown content';
      
      if (!containsFood) {
        developer.log('Non-food image detected: $detectedContent');
        throw NonFoodImageException(
          'This image doesn\'t appear to contain any food items. Please take a photo of your meal, ingredients, or food items.',
          detectedContent,
        );
      }
      
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
      
      timer.complete(additionalMetadata: {'foods_detected': detectedFoods.length});
      return detectedFoods;
    } catch (e) {
      developer.log('Error in OpenAI food detection: $e');
      timer.fail(e.toString());
      
      // Re-throw NonFoodImageException so it can be handled properly by the UI
      if (e is NonFoodImageException) {
        rethrow;
      }
      
      // Return a generic food item as fallback for other types of errors
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
  /// Priority: Firebase Database -> USDA Database -> AI Estimation -> Default
  Future<NutritionInfo> estimateNutrition(
    String foodName,
    double weightGrams,
  ) async {
    try {
      // First, try Firebase foods collection (fastest, pre-populated)
      final firebaseNutrition = await _getNutritionFromFirebase(foodName, weightGrams);
      if (firebaseNutrition != null) {
        developer.log('Using Firebase nutrition data for: $foodName');
        return firebaseNutrition;
      }

      // Second, try USDA FoodData Central (most accurate, save to Firebase)
      final usdaNutrition = await _usdaService.getNutritionForFood(foodName, weightGrams);
      if (usdaNutrition != null) {
        developer.log('Using USDA nutrition data for: $foodName');
        // Backfill Firebase with USDA data for future use
        _backfillFirebaseWithUSDA(foodName, usdaNutrition, weightGrams);
        return usdaNutrition;
      }

      // Third, fallback to local hardcoded database (legacy)
      final localNutrition = _getNutritionFromDatabase(foodName, weightGrams);
      if (localNutrition != null) {
        developer.log('Using local nutrition data for: $foodName');
        return localNutrition;
      }

      // Final fallback to AI-estimated nutrition
      developer.log('Using AI nutrition estimation for: $foodName');
      final aiNutrition = await _estimateNutritionWithAI(foodName, weightGrams);
      // Save AI estimation to Firebase for future use
      _backfillFirebaseWithAI(foodName, aiNutrition);
      return aiNutrition;
    } catch (e) {
      developer.log('Error estimating nutrition for $foodName: $e');
      return _getDefaultNutrition(weightGrams);
    }
  }

  /// Get nutrition data from Firebase foods collection
  Future<NutritionInfo?> _getNutritionFromFirebase(
    String foodName,
    double weightGrams,
  ) async {
    // Check if Firebase service is available (circuit breaker)
    if (!PerformanceMonitor().isServiceAvailable('firebase')) {
      developer.log('🔴 Firebase circuit breaker is open - skipping Firebase query for: $foodName');
      return null;
    }
    
    final timer = PerformanceMonitor().startTimer('nutrition_lookup', 'firebase', 
        metadata: {'food_name': foodName});
    
    try {
      final firestore = FirebaseFirestore.instance;
      final searchTerms = _generateSearchKeywords(foodName);
      
      // Try exact name match first
      var query = await firestore
          .collection('foods')
          .where('foodName', isEqualTo: foodName)
          .limit(1)
          .get();
          
      // If no exact match, try fuzzy search with keywords
      if (query.docs.isEmpty) {
        query = await firestore
            .collection('foods')
            .where('searchableKeywords', arrayContainsAny: searchTerms)
            .orderBy('createdAt', descending: true)
            .limit(5)
            .get();
      }
      
      if (query.docs.isNotEmpty) {
        // Find best match using similarity scoring
        DocumentSnapshot? bestMatch;
        double bestScore = 0.0;
        
        for (final doc in query.docs) {
          final data = doc.data();
          final docFoodName = data['foodName']?.toString() ?? '';
          final score = _calculateFoodNameSimilarity(foodName, docFoodName);
          
          if (score > bestScore) {
            bestScore = score;
            bestMatch = doc;
          }
        }
        
        if (bestMatch != null && bestScore > 0.6) {
          final data = bestMatch.data() as Map<String, dynamic>;
          timer.complete(additionalMetadata: {'found_match': true, 'similarity_score': bestScore});
          return _parseFirebaseNutritionData(data, weightGrams);
        }
      }
      
      timer.complete(additionalMetadata: {'found_match': false});
      return null;
    } catch (e) {
      final errorMessage = 'Firebase foods query failed: $e';
      developer.log(errorMessage);
      
      // Log authentication status for debugging
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        developer.log('❌ User not authenticated during Firebase query');
        timer.fail('Authentication required for Firebase access');
      } else {
        developer.log('✅ User authenticated: ${user.uid}');
        timer.fail(errorMessage);
      }
      
      return null;
    }
  }

  /// Generate search keywords from food name for fuzzy matching
  List<String> _generateSearchKeywords(String foodName) {
    final keywords = <String>{};
    final cleanName = foodName.toLowerCase().trim();
    
    // Add the full name
    keywords.add(cleanName);
    
    // Add individual words (length > 2)
    final words = cleanName.split(RegExp(r'[,\s]+'))
        .where((word) => word.length > 2)
        .toList();
    keywords.addAll(words);
    
    // Add common variations
    if (cleanName.contains('chicken')) keywords.addAll(['poultry', 'fowl']);
    if (cleanName.contains('beef')) keywords.addAll(['steak', 'meat']);
    if (cleanName.contains('fish')) keywords.add('seafood');
    if (cleanName.contains('bread')) keywords.addAll(['toast', 'roll']);
    
    return keywords.toList();
  }

  /// Calculate similarity between two food names (0.0 to 1.0)
  double _calculateFoodNameSimilarity(String name1, String name2) {
    final n1 = name1.toLowerCase().trim();
    final n2 = name2.toLowerCase().trim();
    
    // Exact match
    if (n1 == n2) return 1.0;
    
    // One contains the other
    if (n1.contains(n2) || n2.contains(n1)) return 0.8;
    
    // Word overlap scoring
    final words1 = n1.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
    final words2 = n2.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
    
    if (words1.isEmpty || words2.isEmpty) return 0.0;
    
    final intersection = words1.intersection(words2);
    final union = words1.union(words2);
    
    return intersection.length / union.length;
  }

  /// Parse Firebase nutrition data into NutritionInfo
  NutritionInfo _parseFirebaseNutritionData(
    Map<String, dynamic> data,
    double weightGrams,
  ) {
    final nutritionPer100g = data['nutritionPer100g'] as Map<String, dynamic>? ?? {};
    final scaleFactor = weightGrams / 100.0;
    
    return NutritionInfo(
      calories: (nutritionPer100g['calories']?.toDouble() ?? 0.0) * scaleFactor,
      protein: (nutritionPer100g['protein']?.toDouble() ?? 0.0) * scaleFactor,
      carbs: (nutritionPer100g['carbs']?.toDouble() ?? 0.0) * scaleFactor,
      fat: (nutritionPer100g['fat']?.toDouble() ?? 0.0) * scaleFactor,
      fiber: (nutritionPer100g['fiber']?.toDouble() ?? 0.0) * scaleFactor,
      sugar: (nutritionPer100g['sugar']?.toDouble() ?? 0.0) * scaleFactor,
      sodium: (nutritionPer100g['sodium']?.toDouble() ?? 0.0) * scaleFactor,
      servingSize: weightGrams,
      vitamins: Map<String, double>.from(nutritionPer100g['vitamins'] ?? {}),
      minerals: Map<String, double>.from(nutritionPer100g['minerals'] ?? {}),
    );
  }

  /// Backfill Firebase with USDA nutrition data
  void _backfillFirebaseWithUSDA(
    String foodName,
    NutritionInfo nutrition,
    double weightGrams,
  ) {
    // Run in background to avoid blocking main flow
    Future(() async {
      try {
        // Skip Firebase backfill - foods collection is read-only for client-side code
        // This would be handled by server-side admin scripts instead
        developer.log('Would backfill Firebase with USDA data for: $foodName (skipped - foods collection is read-only)');
      } catch (e) {
        developer.log('Error backfilling Firebase with USDA data: $e');
      }
    });
  }

  /// Backfill Firebase with AI nutrition estimation
  void _backfillFirebaseWithAI(String foodName, NutritionInfo nutrition) {
    // Run in background to avoid blocking main flow
    Future(() async {
      try {
        // Skip Firebase backfill - foods collection is read-only for client-side code
        // This would be handled by server-side admin scripts instead
        developer.log('Would backfill Firebase with AI estimate for: $foodName (skipped - foods collection is read-only)');
      } catch (e) {
        developer.log('Error backfilling Firebase with AI data: $e');
      }
    });
  }

  /// Get nutrition data from local food database (legacy fallback)
  /// This method is now deprecated and should rarely be used since we have:
  /// 1. Firebase with 334+ real USDA foods
  /// 2. USDA FoodData Central API
  /// 3. AI nutrition estimation
  NutritionInfo? _getNutritionFromDatabase(
    String foodName,
    double weightGrams,
  ) {
    // Log usage to monitor if this legacy fallback is still being used
    developer.log('⚠️ Using legacy hardcoded database for: $foodName - consider adding to Firebase');
    
    // Return null to force the system to use AI estimation instead
    // This ensures we're not relying on hardcoded sample data
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
        (total, food) => total + food.nutrition.servingSize,
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
