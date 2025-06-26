import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fasting_session.dart';
import '../services/openai_service.dart';
import '../services/rag_service.dart';

/// Types of content that can be filtered
enum ContentType {
  image,
  text,
  story,
  snap,
  chat,
}

/// Content filtering categories
enum FilterCategory {
  food,              // All food-related content
  restaurant,        // Restaurant/dining content
  cooking,           // Cooking/recipe content
  drinks,            // Beverage content (except water)
  snacks,            // Snack/junk food content
  diet,              // Diet/weight loss content (may be allowed)
  fitness,           // Fitness content (usually allowed)
  health,            // General health content (usually allowed)
}

/// Content filtering severity levels
enum FilterSeverity {
  lenient,    // Filter obvious food content only
  moderate,   // Filter most food-related content
  strict,     // Filter all food-related and tempting content
  extreme,    // Filter everything except health/fitness motivation
}

/// Content filtering result
class ContentFilterResult {
  final bool shouldFilter;
  final FilterCategory? category;
  final double confidence;
  final String? reason;
  final List<String> detectedKeywords;
  final String? replacementContent;

  ContentFilterResult({
    required this.shouldFilter,
    this.category,
    required this.confidence,
    this.reason,
    this.detectedKeywords = const [],
    this.replacementContent,
  });

  Map<String, dynamic> toMap() {
    return {
      'shouldFilter': shouldFilter,
      'category': category?.name,
      'confidence': confidence,
      'reason': reason,
      'detectedKeywords': detectedKeywords,
      'replacementContent': replacementContent,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

/// Alternative content to show instead of filtered content
class AlternativeContent {
  final String title;
  final String description;
  final String? imageUrl;
  final String? actionText;
  final VoidCallback? onAction;

  AlternativeContent({
    required this.title,
    required this.description,
    this.imageUrl,
    this.actionText,
    this.onAction,
  });
}

/// Service for filtering food content during fasting periods
class ContentFilterService {
  final OpenAIService _openAIService;
  final RAGService _ragService;
  final FirebaseFirestore _firestore;

  // Content filtering cache
  final Map<String, ContentFilterResult> _filterCache = {};
  
  // Food-related keywords for quick detection
  static const List<String> _foodKeywords = [
    // Basic food terms
    'food', 'eat', 'eating', 'meal', 'dinner', 'lunch', 'breakfast',
    'snack', 'hungry', 'appetite', 'delicious', 'tasty', 'yummy',
    
    // Cooking terms
    'cooking', 'recipe', 'chef', 'kitchen', 'restaurant', 'menu',
    'order', 'delivery', 'takeout', 'dine', 'dining',
    
    // Food categories
    'pizza', 'burger', 'pasta', 'bread', 'cake', 'cookie', 'candy',
    'chocolate', 'ice cream', 'dessert', 'sweet', 'savory',
    'meat', 'chicken', 'beef', 'pork', 'fish', 'seafood',
    'vegetable', 'fruit', 'salad', 'soup', 'sandwich',
    
    // Drinks
    'drink', 'beverage', 'coffee', 'tea', 'soda', 'juice', 'alcohol',
    'beer', 'wine', 'cocktail', 'smoothie', 'shake',
    
    // Food actions
    'bite', 'chew', 'swallow', 'taste', 'flavor', 'spicy', 'sweet',
    'salty', 'bitter', 'sour', 'fresh', 'crispy', 'creamy',
    
    // Restaurant/ordering
    'uber eats', 'doordash', 'grubhub', 'postmates', 'foodpanda',
    'delivery', 'order food', 'restaurant', 'cafe', 'bar', 'pub',
  ];

  static const List<String> _healthyKeywords = [
    'water', 'hydration', 'fasting', 'meditation', 'exercise', 'workout',
    'fitness', 'health', 'wellness', 'mindfulness', 'discipline',
    'motivation', 'strength', 'energy', 'focus', 'goals',
  ];

  ContentFilterService({
    required OpenAIService openAIService,
    required RAGService ragService,
    FirebaseFirestore? firestore,
  })  : _openAIService = openAIService,
        _ragService = ragService,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Check if content should be filtered based on fasting session
  Future<ContentFilterResult> shouldFilterContent({
    required String content,
    required ContentType contentType,
    required FastingSession? fastingSession,
    Uint8List? imageData,
    FilterSeverity? customSeverity,
  }) async {
    // Don't filter if not fasting
    if (fastingSession?.isActive != true) {
      return ContentFilterResult(
        shouldFilter: false,
        confidence: 1.0,
        reason: 'User not actively fasting',
      );
    }

    // Determine filter severity based on session progress and user preferences
    final severity = customSeverity ?? _determineFilterSeverity(fastingSession);
    
    // Check cache first
    final cacheKey = _generateCacheKey(content, contentType, severity);
    if (_filterCache.containsKey(cacheKey)) {
      return _filterCache[cacheKey]!;
    }

    ContentFilterResult result;

    try {
      // Multi-layered filtering approach
      result = await _performContentAnalysis(
        content: content,
        contentType: contentType,
        severity: severity,
        imageData: imageData,
        fastingSession: fastingSession,
      );

      // Cache the result
      _filterCache[cacheKey] = result;
      
      // Log filter decision for analytics
      await _logFilterDecision(result, fastingSession);
      
    } catch (e) {
      debugPrint('Error in content filtering: $e');
      // Fallback to keyword-based filtering
      result = _performKeywordFiltering(content, severity);
    }

    return result;
  }

  /// Determine filter severity based on fasting session
  FilterSeverity _determineFilterSeverity(FastingSession session) {
    // More strict filtering early in fasting when willpower is typically weaker
    final hoursElapsed = session.elapsedTime.inHours;
    final progressPercentage = session.progressPercentage;

    // Extended fasts need stricter filtering
    if (session.type == FastingType.extended24 || 
        session.type == FastingType.extended36 || 
        session.type == FastingType.extended48) {
      if (progressPercentage < 0.25) return FilterSeverity.extreme;
      if (progressPercentage < 0.5) return FilterSeverity.strict;
      return FilterSeverity.moderate;
    }

    // Regular fasts (16:8, 18:6, etc.)
    if (hoursElapsed < 4) return FilterSeverity.strict;
    if (hoursElapsed < 8) return FilterSeverity.moderate;
    return FilterSeverity.lenient;
  }

  /// Perform comprehensive content analysis
  Future<ContentFilterResult> _performContentAnalysis({
    required String content,
    required ContentType contentType,
    required FilterSeverity severity,
    Uint8List? imageData,
    FastingSession? fastingSession,
  }) async {
    // 1. Quick keyword check
    final keywordResult = _performKeywordFiltering(content, severity);
    if (keywordResult.shouldFilter && keywordResult.confidence > 0.8) {
      return keywordResult;
    }

    // 2. AI-powered content analysis for ambiguous cases
    if (keywordResult.confidence < 0.8) {
      final aiResult = await _performAIAnalysis(
        content: content,
        contentType: contentType,
        severity: severity,
        fastingSession: fastingSession,
      );
      
      // Combine keyword and AI results
      return _combineResults(keywordResult, aiResult);
    }

    return keywordResult;
  }

  /// Perform keyword-based filtering
  ContentFilterResult _performKeywordFiltering(String content, FilterSeverity severity) {
    final lowercaseContent = content.toLowerCase();
    final detectedKeywords = <String>[];
    double confidence = 0.0;
    FilterCategory? category;
    bool shouldFilter = false;

    // Check for food keywords
    for (final keyword in _foodKeywords) {
      if (lowercaseContent.contains(keyword)) {
        detectedKeywords.add(keyword);
        confidence += 0.1;
        
        // Categorize the content
        if (_isFoodCategory(keyword)) category = FilterCategory.food;
        else if (_isRestaurantCategory(keyword)) category = FilterCategory.restaurant;
        else if (_isCookingCategory(keyword)) category = FilterCategory.cooking;
        else if (_isDrinkCategory(keyword)) category = FilterCategory.drinks;
      }
    }

    // Check for healthy keywords (reduce filter probability)
    for (final keyword in _healthyKeywords) {
      if (lowercaseContent.contains(keyword)) {
        confidence -= 0.05; // Reduce filter confidence for healthy content
      }
    }

    // Determine if should filter based on severity and confidence
    confidence = confidence.clamp(0.0, 1.0);
    shouldFilter = _shouldFilterBasedOnSeverity(severity, confidence, category);

    String? reason;
    if (shouldFilter) {
      reason = 'Content contains food-related keywords: ${detectedKeywords.take(3).join(", ")}';
    }

    return ContentFilterResult(
      shouldFilter: shouldFilter,
      category: category,
      confidence: confidence,
      reason: reason,
      detectedKeywords: detectedKeywords,
      replacementContent: shouldFilter ? _generateReplacementContent(category) : null,
    );
  }

  /// Perform AI-powered content analysis
  Future<ContentFilterResult> _performAIAnalysis({
    required String content,
    required ContentType contentType,
    required FilterSeverity severity,
    FastingSession? fastingSession,
  }) async {
    try {
      final prompt = _buildAnalysisPrompt(content, contentType, severity, fastingSession);
      
      final response = await _openAIService.generateChatCompletion(
        messages: [
          {'role': 'system', 'content': 'You are a content filtering expert for a health and fasting app.'},
          {'role': 'user', 'content': prompt},
        ],
        maxTokens: 200,
        temperature: 0.1, // Low temperature for consistent results
      );

      return _parseAIResponse(response);
    } catch (e) {
      debugPrint('AI analysis failed: $e');
      // Fallback to conservative filtering
      return ContentFilterResult(
        shouldFilter: true,
        confidence: 0.5,
        reason: 'AI analysis failed, applying conservative filtering',
      );
    }
  }

  /// Build prompt for AI content analysis
  String _buildAnalysisPrompt(
    String content,
    ContentType contentType,
    FilterSeverity severity,
    FastingSession? fastingSession,
  ) {
    return '''
Analyze this ${contentType.name} content for a user who is actively fasting (${fastingSession?.typeDescription ?? 'unknown type'}):

Content: "$content"

Filter Severity: ${severity.name}
- lenient: Only filter obvious food content
- moderate: Filter most food-related content  
- strict: Filter all food-related and tempting content
- extreme: Filter everything except health/fitness motivation

Determine:
1. Should this content be filtered? (true/false)
2. Confidence level (0.0-1.0)
3. Category (food, restaurant, cooking, drinks, snacks, diet, fitness, health)
4. Brief reason

Respond in JSON format:
{
  "shouldFilter": boolean,
  "confidence": number,
  "category": "string",
  "reason": "string"
}
''';
  }

  /// Parse AI response
  ContentFilterResult _parseAIResponse(String response) {
    try {
      // Simple JSON parsing (in production, use proper JSON parser)
      final shouldFilter = response.contains('"shouldFilter": true');
      final confidence = _extractConfidence(response);
      final category = _extractCategory(response);
      final reason = _extractReason(response);

      return ContentFilterResult(
        shouldFilter: shouldFilter,
        confidence: confidence,
        category: category,
        reason: reason,
      );
    } catch (e) {
      debugPrint('Failed to parse AI response: $e');
      return ContentFilterResult(
        shouldFilter: true,
        confidence: 0.5,
        reason: 'Failed to parse AI analysis',
      );
    }
  }

  /// Extract confidence from AI response
  double _extractConfidence(String response) {
    final regex = RegExp(r'"confidence":\s*([0-9.]+)');
    final match = regex.firstMatch(response);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '0.5') ?? 0.5;
    }
    return 0.5;
  }

  /// Extract category from AI response
  FilterCategory? _extractCategory(String response) {
    for (final category in FilterCategory.values) {
      if (response.contains('"category": "${category.name}"')) {
        return category;
      }
    }
    return null;
  }

  /// Extract reason from AI response
  String? _extractReason(String response) {
    final regex = RegExp(r'"reason":\s*"([^"]+)"');
    final match = regex.firstMatch(response);
    return match?.group(1);
  }

  /// Combine keyword and AI results
  ContentFilterResult _combineResults(
    ContentFilterResult keywordResult,
    ContentFilterResult aiResult,
  ) {
    // Weight AI result more heavily but consider keyword detection
    final combinedConfidence = (aiResult.confidence * 0.7) + (keywordResult.confidence * 0.3);
    final shouldFilter = aiResult.shouldFilter || 
                        (keywordResult.shouldFilter && combinedConfidence > 0.6);

    return ContentFilterResult(
      shouldFilter: shouldFilter,
      confidence: combinedConfidence,
      category: aiResult.category ?? keywordResult.category,
      reason: aiResult.reason ?? keywordResult.reason,
      detectedKeywords: keywordResult.detectedKeywords,
      replacementContent: shouldFilter ? _generateReplacementContent(aiResult.category ?? keywordResult.category) : null,
    );
  }

  /// Determine if should filter based on severity
  bool _shouldFilterBasedOnSeverity(
    FilterSeverity severity,
    double confidence,
    FilterCategory? category,
  ) {
    switch (severity) {
      case FilterSeverity.lenient:
        return confidence > 0.8 && category == FilterCategory.food;
      case FilterSeverity.moderate:
        return confidence > 0.6 && (category == FilterCategory.food || 
                                   category == FilterCategory.restaurant ||
                                   category == FilterCategory.snacks);
      case FilterSeverity.strict:
        return confidence > 0.4 && (category == FilterCategory.food || 
                                   category == FilterCategory.restaurant ||
                                   category == FilterCategory.cooking ||
                                   category == FilterCategory.snacks ||
                                   category == FilterCategory.drinks);
      case FilterSeverity.extreme:
        return confidence > 0.3; // Filter almost everything except health content
    }
  }

  /// Check if keyword belongs to food category
  bool _isFoodCategory(String keyword) {
    return ['food', 'eat', 'meal', 'snack', 'pizza', 'burger', 'pasta', 'bread'].contains(keyword);
  }

  /// Check if keyword belongs to restaurant category
  bool _isRestaurantCategory(String keyword) {
    return ['restaurant', 'delivery', 'order', 'menu', 'dine'].contains(keyword);
  }

  /// Check if keyword belongs to cooking category
  bool _isCookingCategory(String keyword) {
    return ['cooking', 'recipe', 'chef', 'kitchen'].contains(keyword);
  }

  /// Check if keyword belongs to drink category
  bool _isDrinkCategory(String keyword) {
    return ['drink', 'coffee', 'soda', 'juice', 'alcohol', 'beer'].contains(keyword);
  }

  /// Generate replacement content for filtered items
  String? _generateReplacementContent(FilterCategory? category) {
    switch (category) {
      case FilterCategory.food:
        return 'Stay strong! Focus on your fasting goals 💪';
      case FilterCategory.restaurant:
        return 'You\'re doing great with your fast! 🎯';
      case FilterCategory.cooking:
        return 'Fasting builds discipline and strength 🧠';
      case FilterCategory.drinks:
        return 'Water is your best friend during fasting 💧';
      case FilterCategory.snacks:
        return 'Every hour of fasting is progress! ⏰';
      default:
        return 'Content filtered to support your fasting journey 🌟';
    }
  }

  /// Generate alternative motivational content
  Future<AlternativeContent> generateAlternativeContent(
    FilterCategory category,
    FastingSession fastingSession,
  ) async {
    try {
      // Use RAG to generate personalized motivational content
      final healthContext = HealthQueryContext(
        userId: fastingSession.userId,
        queryType: 'motivation',
        userProfile: {
          'fasting_type': fastingSession.type.name,
          'session_progress': fastingSession.progressPercentage,
          'filtered_category': category.name,
        },
        currentGoals: ['fasting', 'discipline', 'health'],
        dietaryRestrictions: [],
        recentActivity: {
          'hours_fasting': fastingSession.elapsedTime.inHours,
          'session_goal': fastingSession.personalGoal,
        },
        contextTimestamp: DateTime.now(),
      );

      final motivationalText = await _ragService.generateContextualizedResponse(
        userQuery: 'Generate motivational content to replace filtered ${category.name} content during my ${fastingSession.typeDescription} session.',
        healthContext: healthContext,
        maxContextLength: 300,
      );

      return AlternativeContent(
        title: 'Stay Focused! 🎯',
        description: motivationalText ?? _generateReplacementContent(category) ?? 'Keep going with your fasting journey!',
        actionText: 'View Progress',
      );
    } catch (e) {
      debugPrint('Error generating alternative content: $e');
      return AlternativeContent(
        title: 'Content Filtered',
        description: _generateReplacementContent(category) ?? 'Content filtered to support your goals',
      );
    }
  }

  /// Filter story content
  Future<List<DocumentSnapshot>> filterStoryContent(
    List<DocumentSnapshot> stories,
    FastingSession? fastingSession,
  ) async {
    if (fastingSession?.isActive != true) return stories;

    final filteredStories = <DocumentSnapshot>[];
    
    for (final story in stories) {
      final data = story.data() as Map<String, dynamic>?;
      if (data == null) continue;

      final text = data['text'] as String? ?? '';
      final result = await shouldFilterContent(
        content: text,
        contentType: ContentType.story,
        fastingSession: fastingSession,
      );

      if (!result.shouldFilter) {
        filteredStories.add(story);
      }
    }

    return filteredStories;
  }

  /// Filter chat messages
  Future<List<DocumentSnapshot>> filterChatMessages(
    List<DocumentSnapshot> messages,
    FastingSession? fastingSession,
  ) async {
    if (fastingSession?.isActive != true) return messages;

    final filteredMessages = <DocumentSnapshot>[];
    
    for (final message in messages) {
      final data = message.data() as Map<String, dynamic>?;
      if (data == null) continue;

      final text = data['message'] as String? ?? '';
      final result = await shouldFilterContent(
        content: text,
        contentType: ContentType.chat,
        fastingSession: fastingSession,
      );

      if (!result.shouldFilter) {
        filteredMessages.add(message);
      }
    }

    return filteredMessages;
  }

  /// Generate cache key
  String _generateCacheKey(String content, ContentType type, FilterSeverity severity) {
    return '${content.hashCode}_${type.name}_${severity.name}';
  }

  /// Log filter decision for analytics
  Future<void> _logFilterDecision(ContentFilterResult result, FastingSession? session) async {
    try {
      if (session != null) {
        await _firestore.collection('filter_analytics').add({
          'userId': session.userId,
          'sessionId': session.id,
          'filterResult': result.toMap(),
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Failed to log filter decision: $e');
    }
  }

  /// Clear filter cache
  void clearCache() {
    _filterCache.clear();
  }

  /// Get filter statistics
  Map<String, dynamic> getFilterStats() {
    var totalFiltered = 0;
    var totalAnalyzed = _filterCache.length;
    final categoryStats = <String, int>{};

    for (final result in _filterCache.values) {
      if (result.shouldFilter) {
        totalFiltered++;
        final category = result.category?.name ?? 'unknown';
        categoryStats[category] = (categoryStats[category] ?? 0) + 1;
      }
    }

    return {
      'totalAnalyzed': totalAnalyzed,
      'totalFiltered': totalFiltered,
      'filterRate': totalAnalyzed > 0 ? totalFiltered / totalAnalyzed : 0.0,
      'categoryStats': categoryStats,
    };
  }
}
