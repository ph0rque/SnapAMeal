import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';
import '../models/meal_log.dart';

/// Service for integrating with USDA FoodData Central API
/// Provides comprehensive nutrition data for accurate meal analysis
class USDANutritionService {
  static const String _searchEndpoint = '/foods/search';
  static const String _foodDetailsEndpoint = '/food';
  
  // Cache for API responses to minimize requests and improve performance
  final Map<String, dynamic> _searchCache = {};
  final Map<String, USDAFoodDetails> _foodDetailsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(hours: 6);

  /// Search for foods in USDA database
  Future<List<USDAFoodSearchResult>> searchFoods(String query) async {
    if (query.trim().isEmpty) return [];
    
    try {
      // Check cache first
      final cacheKey = 'search_$query';
      if (_isCacheValid(cacheKey)) {
        final cachedData = _searchCache[cacheKey];
        return _parseSearchResults(cachedData);
      }

      final url = Uri.parse('${AIConfig.usdaBaseUrl}$_searchEndpoint');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Api-Key': AIConfig.usdaApiKey,
        },
        body: jsonEncode({
          'query': query,
          'dataType': ['Foundation', 'SR Legacy', 'Survey (FNDDS)'],
          'pageSize': AIConfig.maxUsdaSearchResults,
          'pageNumber': 1,
          'sortBy': 'dataType.keyword',
          'sortOrder': 'asc'
        }),
      ).timeout(Duration(seconds: AIConfig.usdaTimeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Cache the results
        _searchCache[cacheKey] = data;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        return _parseSearchResults(data);
      } else {
        developer.log('USDA search failed: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      developer.log('Error searching USDA foods: $e');
      return [];
    }
  }

  /// Get detailed nutrition information for a specific food
  Future<USDAFoodDetails?> getFoodDetails(int fdcId) async {
    try {
      // Check cache first
      final cacheKey = fdcId.toString();
      if (_foodDetailsCache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
        return _foodDetailsCache[cacheKey];
      }

      final url = Uri.parse('${AIConfig.usdaBaseUrl}$_foodDetailsEndpoint/$fdcId');
      final response = await http.get(
        url.replace(queryParameters: {
          'api_key': AIConfig.usdaApiKey,
          'format': 'abridged',
          'nutrients': '203,204,205,208,269,291,301,303,306,307,601,605,606'
        }),
      ).timeout(Duration(seconds: AIConfig.usdaTimeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final foodDetails = USDAFoodDetails.fromJson(data);
        
        // Cache the results
        _foodDetailsCache[cacheKey] = foodDetails;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        return foodDetails;
      } else {
        developer.log('USDA food details failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      developer.log('Error getting USDA food details: $e');
      return null;
    }
  }

  /// Convert USDA nutrition data to our NutritionInfo model
  NutritionInfo convertToNutritionInfo(
    USDAFoodDetails usdaFood,
    double weightGrams,
  ) {
    final scaleFactor = weightGrams / 100.0; // USDA data is per 100g
    
    return NutritionInfo(
      calories: _getNutrientValue(usdaFood.foodNutrients, 208) * scaleFactor,
      protein: _getNutrientValue(usdaFood.foodNutrients, 203) * scaleFactor,
      carbs: _getNutrientValue(usdaFood.foodNutrients, 205) * scaleFactor,
      fat: _getNutrientValue(usdaFood.foodNutrients, 204) * scaleFactor,
      fiber: _getNutrientValue(usdaFood.foodNutrients, 291) * scaleFactor,
      sugar: _getNutrientValue(usdaFood.foodNutrients, 269) * scaleFactor,
      sodium: _getNutrientValue(usdaFood.foodNutrients, 307) * scaleFactor,
      servingSize: weightGrams,
      vitamins: _extractVitamins(usdaFood.foodNutrients, scaleFactor),
      minerals: _extractMinerals(usdaFood.foodNutrients, scaleFactor),
    );
  }

  /// Get the best matching food from USDA database
  Future<NutritionInfo?> getNutritionForFood(String foodName, double weightGrams) async {
    if (AIConfig.usdaApiKey.isEmpty) {
      developer.log('USDA API key not configured');
      return null;
    }

    try {
      // Search for the food
      final searchResults = await searchFoods(foodName);
      if (searchResults.isEmpty) {
        developer.log('No USDA results found for: $foodName');
        return null;
      }

      // Get the best match (first result with highest data quality)
      final bestMatch = _getBestMatch(searchResults, foodName);
      if (bestMatch == null) {
        developer.log('No suitable USDA match found for: $foodName');
        return null;
      }

      // Get detailed nutrition information
      final foodDetails = await getFoodDetails(bestMatch.fdcId);
      if (foodDetails == null) {
        developer.log('Failed to get USDA details for: ${bestMatch.description}');
        return null;
      }

      // Convert to our nutrition format
      final nutrition = convertToNutritionInfo(foodDetails, weightGrams);
      developer.log('Successfully retrieved USDA nutrition for: $foodName');
      return nutrition;
    } catch (e) {
      developer.log('Error getting USDA nutrition for $foodName: $e');
      return null;
    }
  }

  /// Parse search results from USDA API response
  List<USDAFoodSearchResult> _parseSearchResults(Map<String, dynamic> data) {
    final foods = data['foods'] as List? ?? [];
    return foods.map((food) => USDAFoodSearchResult.fromJson(food)).toList();
  }

  /// Get nutrient value by nutrient number
  double _getNutrientValue(List<USDANutrient> nutrients, int nutrientNumber) {
    try {
      final nutrient = nutrients.firstWhere(
        (n) => n.nutrientNumber == nutrientNumber,
      );
      return nutrient.amount;
    } catch (e) {
      return 0.0;
    }
  }

  /// Extract vitamin information
  Map<String, double> _extractVitamins(List<USDANutrient> nutrients, double scaleFactor) {
    final vitamins = <String, double>{};
    
    // Common vitamins with their USDA nutrient numbers
    const vitaminMapping = {
      'A': 318, // Vitamin A, RAE
      'C': 401, // Vitamin C
      'D': 324, // Vitamin D
      'E': 323, // Vitamin E
      'K': 430, // Vitamin K
      'B1': 404, // Thiamin
      'B2': 405, // Riboflavin
      'B3': 406, // Niacin
      'B6': 415, // Pyridoxine
      'B12': 418, // Cobalamin
      'Folate': 417, // Folate
    };

    for (final entry in vitaminMapping.entries) {
      final value = _getNutrientValue(nutrients, entry.value);
      if (value > 0) {
        vitamins[entry.key] = value * scaleFactor;
      }
    }
    
    return vitamins;
  }

  /// Extract mineral information
  Map<String, double> _extractMinerals(List<USDANutrient> nutrients, double scaleFactor) {
    final minerals = <String, double>{};
    
    // Common minerals with their USDA nutrient numbers
    const mineralMapping = {
      'Calcium': 301,
      'Iron': 303,
      'Magnesium': 304,
      'Phosphorus': 305,
      'Potassium': 306,
      'Zinc': 309,
      'Copper': 312,
      'Manganese': 315,
      'Selenium': 317,
    };

    for (final entry in mineralMapping.entries) {
      final value = _getNutrientValue(nutrients, entry.value);
      if (value > 0) {
        minerals[entry.key] = value * scaleFactor;
      }
    }
    
    return minerals;
  }

  /// Get the best matching food from search results
  USDAFoodSearchResult? _getBestMatch(List<USDAFoodSearchResult> results, String query) {
    if (results.isEmpty) return null;
    
    // Prioritize by data type quality and description similarity
    results.sort((a, b) {
      // Prioritize Foundation Foods (highest quality) > SR Legacy > Survey
      final aScore = _getDataTypeScore(a.dataType);
      final bScore = _getDataTypeScore(b.dataType);
      
      if (aScore != bScore) {
        return bScore.compareTo(aScore); // Higher score first
      }
      
      // Then sort by description similarity
      final aSimilarity = _calculateSimilarity(query.toLowerCase(), a.description.toLowerCase());
      final bSimilarity = _calculateSimilarity(query.toLowerCase(), b.description.toLowerCase());
      
      return bSimilarity.compareTo(aSimilarity);
    });
    
    return results.first;
  }

  /// Get data type quality score
  int _getDataTypeScore(String dataType) {
    switch (dataType.toLowerCase()) {
      case 'foundation':
        return 3;
      case 'sr legacy':
        return 2;
      case 'survey (fndds)':
        return 1;
      default:
        return 0;
    }
  }

  /// Calculate basic similarity between strings
  double _calculateSimilarity(String a, String b) {
    if (a == b) return 1.0;
    
    final aWords = a.split(' ');
    final bWords = b.split(' ');
    
    int matches = 0;
    for (final aWord in aWords) {
      if (bWords.any((bWord) => bWord.contains(aWord) || aWord.contains(bWord))) {
        matches++;
      }
    }
    
    return matches / aWords.length;
  }

  /// Check if cache entry is still valid
  bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  /// Clear expired cache entries
  void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) >= _cacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _searchCache.remove(key);
      _foodDetailsCache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    developer.log('Cleared ${expiredKeys.length} expired USDA cache entries');
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'searchCache': _searchCache.length,
      'foodDetailsCache': _foodDetailsCache.length,
      'totalEntries': _cacheTimestamps.length,
    };
  }
}

/// USDA Food Search Result model
class USDAFoodSearchResult {
  final int fdcId;
  final String description;
  final String dataType;
  final String? brandOwner;
  final String? ingredients;

  USDAFoodSearchResult({
    required this.fdcId,
    required this.description,
    required this.dataType,
    this.brandOwner,
    this.ingredients,
  });

  factory USDAFoodSearchResult.fromJson(Map<String, dynamic> json) {
    return USDAFoodSearchResult(
      fdcId: json['fdcId'] as int,
      description: json['description'] as String,
      dataType: json['dataType'] as String,
      brandOwner: json['brandOwner'] as String?,
      ingredients: json['ingredients'] as String?,
    );
  }
}

/// USDA Food Details model
class USDAFoodDetails {
  final int fdcId;
  final String description;
  final String dataType;
  final List<USDANutrient> foodNutrients;

  USDAFoodDetails({
    required this.fdcId,
    required this.description,
    required this.dataType,
    required this.foodNutrients,
  });

  factory USDAFoodDetails.fromJson(Map<String, dynamic> json) {
    final nutrients = (json['foodNutrients'] as List? ?? [])
        .map((nutrient) => USDANutrient.fromJson(nutrient))
        .toList();

    return USDAFoodDetails(
      fdcId: json['fdcId'] as int,
      description: json['description'] as String,
      dataType: json['dataType'] as String,
      foodNutrients: nutrients,
    );
  }
}

/// USDA Nutrient model
class USDANutrient {
  final int nutrientId;
  final int nutrientNumber;
  final String nutrientName;
  final double amount;
  final String unitName;

  USDANutrient({
    required this.nutrientId,
    required this.nutrientNumber,
    required this.nutrientName,
    required this.amount,
    required this.unitName,
  });

  factory USDANutrient.fromJson(Map<String, dynamic> json) {
    return USDANutrient(
      nutrientId: json['nutrientId'] as int,
      nutrientNumber: json['nutrientNumber'] as int,
      nutrientName: json['nutrientName'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      unitName: json['unitName'] as String,
    );
  }
} 