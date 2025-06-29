/// RAG (Retrieval-Augmented Generation) Service for SnapAMeal Phase II
/// Orchestrates between OpenAI and Pinecone for context-aware health advice
library;

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';
import '../utils/logger.dart';
import 'openai_service.dart';
import 'content_validation_service.dart';
import '../data/fallback_content.dart';

/// Represents a knowledge document stored in the vector database
class KnowledgeDocument {
  final String id;
  final String content;
  final String title;
  final String category;
  final String source;
  final double confidenceScore;
  final List<String> tags;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  KnowledgeDocument({
    required this.id,
    required this.content,
    required this.title,
    required this.category,
    required this.source,
    required this.confidenceScore,
    required this.tags,
    required this.createdAt,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'title': title,
      'category': category,
      'source': source,
      'confidence_score': confidenceScore,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory KnowledgeDocument.fromJson(Map<String, dynamic> json) {
    return KnowledgeDocument(
      id: json['id'],
      content: json['content'],
      title: json['title'],
      category: json['category'],
      source: json['source'],
      confidenceScore: json['confidence_score']?.toDouble() ?? 0.0,
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      metadata: json['metadata'] ?? {},
    );
  }
}

/// Represents search results from vector similarity search
class SearchResult {
  final KnowledgeDocument document;
  final double similarityScore;
  final double relevanceScore;
  final String matchReason;
  final List<String> matchedKeywords;

  SearchResult({
    required this.document,
    required this.similarityScore,
    required this.relevanceScore,
    required this.matchReason,
    required this.matchedKeywords,
  });

  Map<String, dynamic> toJson() {
    return {
      'document': document.toJson(),
      'similarity_score': similarityScore,
      'relevance_score': relevanceScore,
      'match_reason': matchReason,
      'matched_keywords': matchedKeywords,
    };
  }

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      document: KnowledgeDocument.fromJson(json['document']),
      similarityScore: json['similarity_score']?.toDouble() ?? 0.0,
      relevanceScore: json['relevance_score']?.toDouble() ?? 0.0,
      matchReason: json['match_reason'] ?? '',
      matchedKeywords: List<String>.from(json['matched_keywords'] ?? []),
    );
  }
}

/// Health-specific query context for better RAG results
class HealthQueryContext {
  final String userId;
  final String
  queryType; // 'advice', 'meal_analysis', 'fasting', 'workout', 'general'
  final Map<String, dynamic> userProfile;
  final List<String> currentGoals;
  final List<String> dietaryRestrictions;
  final Map<String, dynamic> recentActivity;
  final DateTime contextTimestamp;

  HealthQueryContext({
    required this.userId,
    required this.queryType,
    required this.userProfile,
    required this.currentGoals,
    required this.dietaryRestrictions,
    required this.recentActivity,
    required this.contextTimestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'query_type': queryType,
      'user_profile': userProfile,
      'current_goals': currentGoals,
      'dietary_restrictions': dietaryRestrictions,
      'recent_activity': recentActivity,
      'context_timestamp': contextTimestamp.toIso8601String(),
    };
  }
}

/// Represents a contextualized query with enhanced context
class ContextualizedQuery {
  final String originalQuery;
  final String expandedQuery;
  final List<String> keyTerms;
  final List<String> relatedConcepts;
  final Map<String, double> termWeights;
  final HealthQueryContext? healthContext;

  ContextualizedQuery({
    required this.originalQuery,
    required this.expandedQuery,
    required this.keyTerms,
    required this.relatedConcepts,
    required this.termWeights,
    this.healthContext,
  });
}

/// Comprehensive RAG service with advanced retrieval and context injection
class RAGService {
  final OpenAIService _openAIService;

  // Performance tracking
  int _totalQueries = 0;
  int _successfulQueries = 0;
  double _averageResponseTime = 0.0;
  final Map<String, int> _queryTypeStats = {};

  RAGService(this._openAIService);

  /// Initialize the service and retrieve the index host URL
  Future<bool> initialize() async {
    try {
      // First check if index host is already cached
      if (AIConfig.indexHost != null) {
        return true;
      }

      // Get index information from Pinecone
      final response = await http.get(
        Uri.parse(
          '${AIConfig.pineconeBaseUrl}/indexes/${AIConfig.pineconeIndexName}',
        ),
        headers: {
          'Api-Key': AIConfig.pineconeApiKey,
          'Content-Type': 'application/json',
          'X-Pinecone-API-Version': AIConfig.pineconeApiVersion,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final host = data['host'];
        if (host != null) {
          AIConfig.setIndexHost(host);
          developer.log('Pinecone index host set: $host');
          return true;
        }
      } else {
        developer.log(
          'Failed to get index info: ${response.statusCode} - ${response.body}',
        );
      }

      return false;
    } catch (e) {
      developer.log('Error initializing RAG service: $e');
      return false;
    }
  }

  /// Test Pinecone connectivity and return detailed status
  Future<Map<String, dynamic>> testConnectionWithDetails() async {
    final result = <String, dynamic>{
      'success': false,
      'api_key_valid': false,
      'index_exists': false,
      'index_host': null,
      'connection_test': false,
      'error': null,
    };

    try {
      developer.log('🔍 Testing Pinecone connection...');

      // Step 1: Test API key by listing indexes
      final listResponse = await http.get(
        Uri.parse('${AIConfig.pineconeBaseUrl}/indexes'),
        headers: {
          'Api-Key': AIConfig.pineconeApiKey,
          'Content-Type': 'application/json',
          'X-Pinecone-API-Version': AIConfig.pineconeApiVersion,
        },
      );

      if (listResponse.statusCode == 200) {
        result['api_key_valid'] = true;
        developer.log('✅ API key is valid');

        // Step 2: Check if our specific index exists
        final indexes = jsonDecode(listResponse.body);
        final indexList = indexes['indexes'] as List;
        final ourIndex = indexList.firstWhere(
          (index) => index['name'] == AIConfig.pineconeIndexName,
          orElse: () => null,
        );

        if (ourIndex != null) {
          result['index_exists'] = true;
          result['index_host'] = ourIndex['host'];
          AIConfig.setIndexHost(ourIndex['host']);
          developer.log('✅ Index "${AIConfig.pineconeIndexName}" found');
          developer.log('Host: ${ourIndex['host']}');

          // Step 3: Test direct connection to index
          final statsResponse = await http.post(
            Uri.parse('https://${ourIndex['host']}/describe_index_stats'),
            headers: {
              'Api-Key': AIConfig.pineconeApiKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({}),
          );

          if (statsResponse.statusCode == 200) {
            result['connection_test'] = true;
            result['success'] = true;
            final stats = jsonDecode(statsResponse.body);
            result['index_stats'] = stats;
            developer.log('✅ Index connection successful!');
            developer.log('Vector count: ${stats['totalVectorCount']}');
          } else {
            result['error'] =
                'Failed to connect to index: ${statsResponse.statusCode}';
            developer.log(
              '❌ Index connection failed: ${statsResponse.statusCode}',
            );
          }
        } else {
          result['error'] = 'Index "${AIConfig.pineconeIndexName}" not found';
          developer.log('❌ Index not found');
        }
      } else {
        result['error'] = 'Invalid API key: ${listResponse.statusCode}';
        developer.log('❌ API key invalid: ${listResponse.statusCode}');
      }
    } catch (e) {
      result['error'] = e.toString();
      developer.log('❌ Connection test error: $e');
    }

    return result;
  }

  /// Test Pinecone connectivity (simple version)
  Future<bool> testConnection() async {
    final result = await testConnectionWithDetails();
    return result['success'] == true;
  }

  /// Store a single document in the vector database
  Future<bool> storeDocument(KnowledgeDocument document) async {
    try {
      // Ensure service is initialized
      if (!(await initialize())) {
        throw Exception('Failed to initialize RAG service');
      }

      // Generate embedding for the document
      final embedding = await _openAIService.generateEmbedding(
        '${document.title} ${document.content}',
      );

      if (embedding == null) {
        throw Exception('Failed to generate embedding for document');
      }

      // Prepare metadata
      final metadata = {
        'title': document.title,
        'category': document.category,
        'source': document.source,
        'confidence_score': document.confidenceScore,
        'tags': document.tags,
        'created_at': document.createdAt.toIso8601String(),
        'content_length': document.content.length,
        ...document.metadata,
      };

      // Store in Pinecone using the modern API
      final response = await http.post(
        Uri.parse('https://${AIConfig.indexHost}/vectors/upsert'),
        headers: {
          'Api-Key': AIConfig.pineconeApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'vectors': [
            {'id': document.id, 'values': embedding, 'metadata': metadata},
          ],
          'namespace': AIConfig.pineconeNamespace,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      Logger.d('Error storing document: $e');
      return false;
    }
  }

  /// Store multiple documents in batch with rate limiting
  Future<List<bool>> storeDocuments(List<KnowledgeDocument> documents) async {
    final results = <bool>[];

    for (int i = 0; i < documents.length; i++) {
      final result = await storeDocument(documents[i]);
      results.add(result);

      // Rate limiting - wait between requests
      if (i < documents.length - 1) {
        await Future.delayed(Duration(milliseconds: AIConfig.rateLimitDelayMs));
      }
    }

    return results;
  }

  /// Alias for storeDocuments - for backward compatibility
  Future<bool> storeBatchDocuments(List<KnowledgeDocument> documents) async {
    final results = await storeDocuments(documents);
    return results.every((result) => result);
  }

  /// Expand and contextualize a user query for better retrieval
  Future<ContextualizedQuery> expandQuery(
    String originalQuery,
    HealthQueryContext? healthContext,
  ) async {
    try {
      // Extract key terms using simple NLP
      final keyTerms = _extractKeyTerms(originalQuery);

      // Generate related concepts using GPT
      final relatedConcepts = await _generateRelatedConcepts(
        originalQuery,
        healthContext,
      );

      // Create expanded query
      final expandedQuery = _buildExpandedQuery(
        originalQuery,
        keyTerms,
        relatedConcepts,
        healthContext,
      );

      // Calculate term weights
      final termWeights = _calculateTermWeights(keyTerms, relatedConcepts);

      return ContextualizedQuery(
        originalQuery: originalQuery,
        expandedQuery: expandedQuery,
        keyTerms: keyTerms,
        relatedConcepts: relatedConcepts,
        termWeights: termWeights,
        healthContext: healthContext,
      );
    } catch (e) {
      Logger.d('Error expanding query: $e');
      // Fallback to original query
      return ContextualizedQuery(
        originalQuery: originalQuery,
        expandedQuery: originalQuery,
        keyTerms: _extractKeyTerms(originalQuery),
        relatedConcepts: [],
        termWeights: {},
        healthContext: healthContext,
      );
    }
  }

  /// Perform semantic search with advanced filtering and ranking
  Future<List<SearchResult>> performSemanticSearch({
    required String query,
    HealthQueryContext? healthContext,
    int maxResults = 10,
    double minSimilarityScore = 0.7,
    List<String>? categoryFilter,
    List<String>? tagFilter,
  }) async {
    final startTime = DateTime.now();
    _totalQueries++;

    try {
      // Expand query for better retrieval
      final contextualizedQuery = await expandQuery(query, healthContext);

      // Generate embedding for the expanded query
      final queryEmbedding = await _openAIService.generateEmbedding(
        contextualizedQuery.expandedQuery,
      );

      if (queryEmbedding == null) {
        throw Exception('Failed to generate query embedding');
      }

      // Build filter conditions
      final filter = _buildFilterConditions(
        categoryFilter,
        tagFilter,
        healthContext,
      );

      // Ensure service is initialized
      if (!(await initialize())) {
        throw Exception('Failed to initialize RAG service');
      }

      // Query Pinecone using the correct index host
      final response = await http.post(
        Uri.parse('https://${AIConfig.indexHost}/query'),
        headers: {
          'Api-Key': AIConfig.pineconeApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'vector': queryEmbedding,
          'topK': maxResults * 2, // Get more results for better filtering
          'includeMetadata': true,
          'includeValues': false,
          'namespace': AIConfig.pineconeNamespace,
          if (filter.isNotEmpty) 'filter': filter,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Pinecone query failed: ${response.body}');
      }

      final responseData = jsonDecode(response.body);
      final matches = responseData['matches'] as List;

      // Convert to SearchResult objects and rank
      final searchResults = await _processAndRankResults(
        matches,
        contextualizedQuery,
        minSimilarityScore,
      );

      // Limit results
      final limitedResults = searchResults.take(maxResults).toList();

      // Update performance stats
      _successfulQueries++;
      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      _averageResponseTime =
          (_averageResponseTime * (_successfulQueries - 1) + responseTime) /
          _successfulQueries;

      // Update query type stats
      final queryType = healthContext?.queryType ?? 'general';
      _queryTypeStats[queryType] = (_queryTypeStats[queryType] ?? 0) + 1;

      return limitedResults;
    } catch (e) {
      Logger.d('Error performing semantic search: $e');
      return [];
    }
  }

  /// Generate contextualized response using RAG
  Future<String?> generateContextualizedResponse({
    required String userQuery,
    required HealthQueryContext healthContext,
    int maxContextLength = 4000,
  }) async {
    try {
      // Perform semantic search
      final searchResults = await performSemanticSearch(
        query: userQuery,
        healthContext: healthContext,
        maxResults: 8,
        categoryFilter: _getRelevantCategories(healthContext.queryType),
      );

      if (searchResults.isEmpty) {
        return await _generateFallbackResponse(userQuery, healthContext);
      }

      // Build context from search results
      final context = _buildLLMContext(searchResults, maxContextLength);

      // Create personalized prompt
      final systemPrompt = _buildSystemPrompt(healthContext);
      final userPrompt = _buildUserPrompt(userQuery, context, healthContext);

      // Generate response using OpenAI
      final response = await _openAIService.getChatCompletionWithMessages(
        messages: [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        maxTokens: 500,
        temperature: 0.7,
      );

      // Add safety disclaimer to the response
      return response != null ? _addSafetyDisclaimer(response) : null;
    } catch (e) {
      Logger.d('Error generating contextualized response: $e');
      return null;
    }
  }

  /// Query nutritional facts and comparisons from the knowledge base
  Future<String?> queryNutritionalFacts({
    required String query,
    String? userId,
    List<String>? dietaryRestrictions,
    int maxResults = 5,
  }) async {
    try {
      Logger.d('🔍 Querying nutritional facts: $query');

      // Create specialized health context for nutritional queries
      final healthContext = HealthQueryContext(
        userId: userId ?? 'anonymous',
        queryType: 'nutrition_facts',
        userProfile: {},
        currentGoals: ['nutrition_education'],
        dietaryRestrictions: dietaryRestrictions ?? [],
        recentActivity: {},
        contextTimestamp: DateTime.now(),
      );

      // Enhanced search with nutrition-specific filtering
      final searchResults = await performSemanticSearch(
        query: query,
        healthContext: healthContext,
        maxResults: maxResults,
        minSimilarityScore: 0.6, // Lower threshold for broader nutrition results
        categoryFilter: _getNutritionCategories(),
        tagFilter: ['nutrition_facts'],
      );

      if (searchResults.isEmpty) {
        return await _generateNutritionFallbackResponse(query, dietaryRestrictions);
      }

      // Build specialized nutrition context
      final context = _buildNutritionContext(searchResults);

      // Create nutrition-specific prompt
      final systemPrompt = _buildNutritionSystemPrompt(dietaryRestrictions);
      final userPrompt = _buildNutritionUserPrompt(query, context);

      // Generate response using OpenAI
      final response = await _openAIService.getChatCompletionWithMessages(
        messages: [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        maxTokens: 600,
        temperature: 0.3, // Lower temperature for more factual responses
      );

      Logger.d('✅ Generated nutritional response: ${response?.substring(0, 100)}...');
      return response != null ? _addNutritionDisclaimer(response) : null;
    } catch (e) {
      Logger.d('❌ Error querying nutritional facts: $e');
      return null;
    }
  }

  /// Compare nutritional content between foods
  Future<String?> compareNutritionalContent({
    required List<String> foodNames,
    String? comparisonAspect, // e.g., "protein", "calories", "vitamins"
    List<String>? dietaryRestrictions,
  }) async {
    try {
      Logger.d('⚖️ Comparing nutritional content: ${foodNames.join(" vs ")}');

      if (foodNames.length < 2) {
        return 'Please provide at least two foods to compare.';
      }

             // Search for each food individually to get comprehensive data
      final allResults = <SearchResult>[];
      
      for (final foodName in foodNames) {
        final foodQuery = 'nutritional information $foodName';
        final results = await performSemanticSearch(
          query: foodQuery,
          maxResults: 3,
          minSimilarityScore: 0.5,
          categoryFilter: _getNutritionCategories(),
          tagFilter: ['nutrition_facts'],
        );
        
        // Filter results that actually mention this food
        final relevantResults = results.where((result) =>
          result.document.title.toLowerCase().contains(foodName.toLowerCase()) ||
          result.document.content.toLowerCase().contains(foodName.toLowerCase())
        ).toList();
        
        allResults.addAll(relevantResults);
      }

      if (allResults.isEmpty) {
        return await _generateComparisonFallbackResponse(foodNames, comparisonAspect);
      }

      // Build comparison context
      final context = _buildComparisonContext(allResults, foodNames);

      // Create comparison-specific prompt
      final systemPrompt = _buildComparisonSystemPrompt(dietaryRestrictions);
      final userPrompt = _buildComparisonUserPrompt(foodNames, comparisonAspect, context);

      // Generate comparison response
      final response = await _openAIService.getChatCompletionWithMessages(
        messages: [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        maxTokens: 700,
        temperature: 0.2, // Very factual for comparisons
      );

      Logger.d('✅ Generated comparison response');
      return response != null ? _addNutritionDisclaimer(response) : null;
    } catch (e) {
      Logger.d('❌ Error comparing nutritional content: $e');
      return null;
    }
  }

  /// Find foods high in specific nutrients
  Future<String?> findFoodsHighInNutrient({
    required String nutrient,
    List<String>? dietaryRestrictions,
    int maxSuggestions = 8,
  }) async {
    try {
      Logger.d('🔍 Finding foods high in: $nutrient');

      // Create nutrient-specific query
      final query = 'foods high in $nutrient excellent source rich $nutrient content';

      // Search with nutrition focus
      final searchResults = await performSemanticSearch(
        query: query,
        maxResults: maxSuggestions * 2, // Get more results to filter
        minSimilarityScore: 0.4, // Lower threshold for broader results
        categoryFilter: _getNutritionCategories(),
        tagFilter: ['nutrition_facts'],
      );

      if (searchResults.isEmpty) {
        return await _generateNutrientFallbackResponse(nutrient, dietaryRestrictions);
      }

      // Filter and rank results by nutrient relevance
      final relevantResults = _filterByNutrientRelevance(searchResults, nutrient);

      // Build nutrient-focused context
      final context = _buildNutrientContext(relevantResults, nutrient);

      // Create nutrient-specific prompt
      final systemPrompt = _buildNutrientSystemPrompt(dietaryRestrictions);
      final userPrompt = _buildNutrientUserPrompt(nutrient, context);

      // Generate response
      final response = await _openAIService.getChatCompletionWithMessages(
        messages: [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        maxTokens: 600,
        temperature: 0.3,
      );

      Logger.d('✅ Generated nutrient-rich foods response');
      return response != null ? _addNutritionDisclaimer(response) : null;
    } catch (e) {
      Logger.d('❌ Error finding foods high in nutrient: $e');
      return null;
    }
  }

  /// Extract key terms from query using simple NLP
  List<String> _extractKeyTerms(String query) {
    // Simple keyword extraction - could be enhanced with proper NLP
    final words = query
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(' ')
        .where((word) => word.length > 2)
        .toList();

    // Remove common stop words
    final stopWords = {
      'the',
      'and',
      'for',
      'are',
      'but',
      'not',
      'you',
      'all',
      'can',
      'had',
      'her',
      'was',
      'one',
      'our',
      'out',
      'day',
      'get',
      'has',
      'him',
      'his',
      'how',
      'its',
      'may',
      'new',
      'now',
      'old',
      'see',
      'two',
      'who',
      'boy',
      'did',
      'she',
      'use',
      'way',
      'will',
      'what',
      'with',
      'have',
      'from',
    };

    return words.where((word) => !stopWords.contains(word)).toList();
  }

  /// Generate related concepts using GPT
  Future<List<String>> _generateRelatedConcepts(
    String query,
    HealthQueryContext? healthContext,
  ) async {
    try {
      final prompt =
          '''
Generate 3-5 related general wellness and nutrition concepts for this query: "$query"

${healthContext != null ? 'User context: ${healthContext.queryType}, Goals: ${healthContext.currentGoals.join(", ")}' : ''}

SAFETY GUIDELINES: Focus on general wellness concepts only. Avoid medical terms, conditions, or treatment-related concepts.

Return only the general wellness concepts, one per line, no explanations:
''';

      final response = await _openAIService.getChatCompletionWithMessages(
        messages: [
          {'role': 'user', 'content': prompt},
        ],
        maxTokens: 100,
        temperature: 0.3,
      );

      if (response != null) {
        return response
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty && !line.startsWith('-'))
            .take(5)
            .toList();
      }
    } catch (e) {
      Logger.d('Error generating related concepts: $e');
    }

    return [];
  }

  /// Build expanded query with related concepts
  String _buildExpandedQuery(
    String originalQuery,
    List<String> keyTerms,
    List<String> relatedConcepts,
    HealthQueryContext? healthContext,
  ) {
    final parts = [originalQuery];

    // Add key terms
    if (keyTerms.isNotEmpty) {
      parts.add(keyTerms.take(3).join(' '));
    }

    // Add related concepts
    if (relatedConcepts.isNotEmpty) {
      parts.add(relatedConcepts.take(2).join(' '));
    }

    // Add health context
    if (healthContext != null) {
      parts.add(healthContext.queryType);
      if (healthContext.currentGoals.isNotEmpty) {
        parts.add(healthContext.currentGoals.first);
      }
    }

    return parts.join(' ');
  }

  /// Calculate term weights for ranking
  Map<String, double> _calculateTermWeights(
    List<String> keyTerms,
    List<String> relatedConcepts,
  ) {
    final weights = <String, double>{};

    // Higher weight for key terms
    for (final term in keyTerms) {
      weights[term] = 1.0;
    }

    // Lower weight for related concepts
    for (final concept in relatedConcepts) {
      weights[concept] = 0.7;
    }

    return weights;
  }

  /// Build filter conditions for Pinecone query
  Map<String, dynamic> _buildFilterConditions(
    List<String>? categoryFilter,
    List<String>? tagFilter,
    HealthQueryContext? healthContext,
  ) {
    final filter = <String, dynamic>{};

    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      filter['category'] = {'\$in': categoryFilter};
    }

    if (tagFilter != null && tagFilter.isNotEmpty) {
      filter['tags'] = {'\$in': tagFilter};
    }

    // Add health context filters
    if (healthContext != null) {
      // Filter by confidence score
      filter['confidence_score'] = {'\$gte': 0.8};

      // Add dietary restriction filters if applicable
      if (healthContext.dietaryRestrictions.isNotEmpty) {
        final restrictionFilters = <String, dynamic>{};
        for (final restriction in healthContext.dietaryRestrictions) {
          restrictionFilters['tags'] = {
            '\$nin': [restriction.toLowerCase()],
          };
        }
      }
    }

    return filter;
  }

  /// Process and rank search results
  Future<List<SearchResult>> _processAndRankResults(
    List<dynamic> matches,
    ContextualizedQuery contextualizedQuery,
    double minSimilarityScore,
  ) async {
    final results = <SearchResult>[];

    for (final match in matches) {
      final score = match['score']?.toDouble() ?? 0.0;
      if (score < minSimilarityScore) continue;

      final metadata = match['metadata'] ?? {};

      // Create KnowledgeDocument from metadata
      final document = KnowledgeDocument(
        id: match['id'] ?? '',
        content: metadata['content'] ?? '',
        title: metadata['title'] ?? '',
        category: metadata['category'] ?? '',
        source: metadata['source'] ?? '',
        confidenceScore: metadata['confidence_score']?.toDouble() ?? 0.0,
        tags: List<String>.from(metadata['tags'] ?? []),
        createdAt:
            DateTime.tryParse(metadata['created_at'] ?? '') ?? DateTime.now(),
        metadata: metadata,
      );

      // Calculate relevance score
      final relevanceScore = _calculateRelevanceScore(
        document,
        contextualizedQuery,
        score,
      );

      // Determine match reason
      final matchReason = _determineMatchReason(document, contextualizedQuery);

      // Find matched keywords
      final matchedKeywords = _findMatchedKeywords(
        document,
        contextualizedQuery,
      );

      results.add(
        SearchResult(
          document: document,
          similarityScore: score,
          relevanceScore: relevanceScore,
          matchReason: matchReason,
          matchedKeywords: matchedKeywords,
        ),
      );
    }

    // Sort by relevance score (highest first)
    results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

    return results;
  }

  /// Calculate relevance score based on multiple factors
  double _calculateRelevanceScore(
    KnowledgeDocument document,
    ContextualizedQuery query,
    double similarityScore,
  ) {
    double relevanceScore = similarityScore;

    // Boost score based on confidence
    relevanceScore *= (0.5 + document.confidenceScore * 0.5);

    // Boost score for query type match
    if (query.healthContext != null) {
      final queryType = query.healthContext!.queryType;
      if (document.category.toLowerCase().contains(queryType.toLowerCase()) ||
          document.tags.any(
            (tag) => tag.toLowerCase().contains(queryType.toLowerCase()),
          )) {
        relevanceScore *= 1.2;
      }
    }

    // Boost score for recent content
    final age = DateTime.now().difference(document.createdAt).inDays;
    if (age < 30) {
      relevanceScore *= 1.1;
    }

    // Boost score for comprehensive content
    if (document.content.length > 500) {
      relevanceScore *= 1.05;
    }

    return relevanceScore;
  }

  /// Determine why this document matched
  String _determineMatchReason(
    KnowledgeDocument document,
    ContextualizedQuery query,
  ) {
    final reasons = <String>[];

    // Check for key term matches
    for (final term in query.keyTerms) {
      if (document.content.toLowerCase().contains(term.toLowerCase()) ||
          document.title.toLowerCase().contains(term.toLowerCase())) {
        reasons.add('Contains "$term"');
      }
    }

    // Check for category match
    if (query.healthContext != null) {
      final queryType = query.healthContext!.queryType;
      if (document.category.toLowerCase().contains(queryType.toLowerCase())) {
        reasons.add('Category match: ${document.category}');
      }
    }

    // Check for tag matches
    for (final concept in query.relatedConcepts) {
      if (document.tags.any(
        (tag) => tag.toLowerCase().contains(concept.toLowerCase()),
      )) {
        reasons.add('Related concept: $concept');
      }
    }

    return reasons.isEmpty ? 'Semantic similarity' : reasons.first;
  }

  /// Find matched keywords between document and query
  List<String> _findMatchedKeywords(
    KnowledgeDocument document,
    ContextualizedQuery query,
  ) {
    final matched = <String>[];
    final docText = '${document.title} ${document.content}'.toLowerCase();

    for (final term in query.keyTerms) {
      if (docText.contains(term.toLowerCase())) {
        matched.add(term);
      }
    }

    for (final concept in query.relatedConcepts) {
      if (docText.contains(concept.toLowerCase())) {
        matched.add(concept);
      }
    }

    return matched.take(5).toList();
  }

  /// Get relevant categories for query type
  List<String> _getRelevantCategories(String queryType) {
    switch (queryType.toLowerCase()) {
      case 'meal_analysis':
        return ['nutrition', 'recipes', 'meal_planning'];
      case 'fasting':
        return ['fasting', 'weight_loss', 'nutrition'];
      case 'workout':
        return ['fitness', 'weight_loss', 'wellness'];
      case 'advice':
        return ['nutrition', 'wellness', 'behavioral_health'];
      default:
        return [];
    }
  }

  /// Build LLM context from search results
  String _buildLLMContext(List<SearchResult> results, int maxLength) {
    final contextParts = <String>[];
    int currentLength = 0;

    for (final result in results) {
      final snippet =
          '''
Title: ${result.document.title}
Category: ${result.document.category}
Content: ${result.document.content}
Confidence: ${(result.document.confidenceScore * 100).toInt()}%
Relevance: ${(result.relevanceScore * 100).toInt()}%

''';

      if (currentLength + snippet.length > maxLength) {
        break;
      }

      contextParts.add(snippet);
      currentLength += snippet.length;
    }

    return contextParts.join('\n---\n\n');
  }

  /// Build system prompt for personalized responses with safety guidelines
  String _buildSystemPrompt(HealthQueryContext healthContext) {
    return '''
You are a knowledgeable health and nutrition AI assistant for SnapAMeal, a health tracking app.

User Profile:
- Goals: ${healthContext.currentGoals.join(", ")}
- Dietary Restrictions: ${healthContext.dietaryRestrictions.isEmpty ? 'None' : healthContext.dietaryRestrictions.join(", ")}
- Query Type: ${healthContext.queryType}

CRITICAL SAFETY GUIDELINES:
- NEVER provide medical advice, diagnoses, or treatment recommendations
- NEVER suggest specific medications, supplements, or medical procedures
- NEVER claim to replace healthcare professionals or medical consultations
- AVOID making definitive health claims or promises about outcomes
- DO NOT provide advice for serious medical conditions, eating disorders, or mental health issues
- ALWAYS include disclaimers when appropriate

Guidelines:
1. Provide evidence-based general wellness information using the provided knowledge base
2. Be encouraging and motivational while staying within safe boundaries
3. Personalize responses based on user goals and restrictions
4. Keep responses concise but comprehensive
5. Always prioritize safety and recommend consulting healthcare professionals for medical concerns
6. Use a friendly, supportive tone similar to a knowledgeable friend
7. Focus on general nutrition education, lifestyle tips, and wellness information
8. Include appropriate disclaimers about not replacing professional medical advice

REQUIRED DISCLAIMER: All responses must include or acknowledge that the information provided is for general wellness purposes only and is not a substitute for professional medical advice, diagnosis, or treatment.

If the knowledge base doesn't contain relevant information, acknowledge this and provide general guidance while recommending professional consultation.
''';
  }

  /// Build user prompt with context
  String _buildUserPrompt(
    String originalQuery,
    String context,
    HealthQueryContext healthContext,
  ) {
    return '''
User Question: $originalQuery

Relevant Knowledge Base Information:
$context

Please provide a personalized response based on the user's question and the relevant information from the knowledge base. Make sure to reference specific information from the knowledge base when applicable.
''';
  }

  /// Generate fallback response when no relevant documents found
  Future<String?> _generateFallbackResponse(
    String query,
    HealthQueryContext healthContext,
  ) async {
    final prompt =
        '''
The user asked: "$query"

User context: ${healthContext.queryType}, Goals: ${healthContext.currentGoals.join(", ")}

SAFETY GUIDELINES: Never provide medical advice, diagnoses, or treatment recommendations. Focus on general wellness information only.

I don't have specific information in my knowledge base to answer this question comprehensively. Please provide a helpful general response that:
1. Acknowledges the limitation
2. Provides general wellness guidance if possible (NOT medical advice)
3. Recommends consulting healthcare professionals for medical concerns
4. Stays encouraging and supportive
5. Includes a disclaimer that this is not medical advice

Keep the response under 200 words and include an appropriate disclaimer.
''';

    final response = await _openAIService.getChatCompletionWithMessages(
      messages: [
        {'role': 'user', 'content': prompt},
      ],
      maxTokens: 250,
      temperature: 0.7,
    );
    
    if (response != null) {
      return _addSafetyDisclaimer(response);
    } else {
      // Use fallback content if OpenAI fails
      return FallbackContent.getSafeGenericResponse();
    }
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return {
      'total_queries': _totalQueries,
      'successful_queries': _successfulQueries,
      'success_rate': _totalQueries > 0
          ? _successfulQueries / _totalQueries
          : 0.0,
      'average_response_time_ms': _averageResponseTime,
      'query_type_distribution': _queryTypeStats,
    };
  }

  /// Get knowledge base statistics
  Future<Map<String, dynamic>> getKnowledgeBaseStats() async {
    try {
      final response = await http.post(
        Uri.parse('${AIConfig.pineconeBaseUrl}/describe_index_stats'),
        headers: {
          'Api-Key': AIConfig.pineconeApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'filter': {}}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'total_vector_count': data['totalVectorCount'] ?? 0,
          'dimension': data['dimension'] ?? 0,
          'index_fullness': data['indexFullness'] ?? 0.0,
          'namespaces': data['namespaces'] ?? {},
        };
      }
    } catch (e) {
      Logger.d('Error getting knowledge base stats: $e');
    }

    return {
      'total_vector_count': 0,
      'dimension': 0,
      'index_fullness': 0.0,
      'namespaces': {},
    };
  }

  /// Search for recipe suggestions based on detected foods
  Future<List<SearchResult>> searchRecipeSuggestions({
    required List<String> detectedFoods,
    required HealthQueryContext healthContext,
    int maxResults = 5,
  }) async {
    try {
      // Build recipe-focused query
      final query =
          'healthy recipes using ${detectedFoods.join(", ")} ingredients';

      // Search with recipe-specific filters
      return await performSemanticSearch(
        query: query,
        healthContext: healthContext,
        maxResults: maxResults,
        categoryFilter: ['recipes', 'meal_planning', 'nutrition'],
        tagFilter: detectedFoods,
      );
    } catch (e) {
      Logger.d('Error searching recipe suggestions: $e');
      return [];
    }
  }

  /// Generate personalized recipe recommendations
  Future<String?> generateRecipeRecommendations({
    required List<String> detectedFoods,
    required HealthQueryContext healthContext,
    required List<SearchResult> recipeResults,
  }) async {
    try {
      // Build context from recipe search results
      final recipeContext = _buildLLMContext(recipeResults, 1500);

      // Create personalized prompt with safety guidelines
      final prompt =
          '''
Based on the detected foods: ${detectedFoods.join(", ")}

User Profile:
- Goals: ${healthContext.currentGoals.join(", ")}
- Dietary Restrictions: ${healthContext.dietaryRestrictions.isEmpty ? 'None' : healthContext.dietaryRestrictions.join(", ")}

Recipe Knowledge Base:
$recipeContext

SAFETY GUIDELINES: Provide general recipe suggestions only. Do not give medical advice or make health claims. Focus on general nutrition education.

Please provide 2-3 personalized recipe suggestions that:
1. Use the detected ingredients
2. Align with the user's health goals (general wellness, not medical)
3. Respect dietary restrictions
4. Include brief preparation tips
5. Mention general nutritional benefits (not medical claims)

Keep each suggestion concise (2-3 sentences) and motivational. Include a brief disclaimer that this is general nutrition information, not medical advice.
''';

      final response = await _openAIService.getChatCompletion(prompt);
      if (response != null) {
        return _addSafetyDisclaimer(response);
      } else {
        // Use fallback content if OpenAI fails
        final suggestions = FallbackContent.getRecipeSuggestions(healthContext.dietaryRestrictions);
        return suggestions.join('\n\n');
      }
    } catch (e) {
      Logger.d('Error generating recipe recommendations: $e');
      // Use fallback content on error
      final suggestions = FallbackContent.getRecipeSuggestions(healthContext.dietaryRestrictions);
      return suggestions.join('\n\n');
    }
  }

  /// Search for nutrition insights about detected foods
  Future<String?> generateNutritionInsights({
    required List<String> detectedFoods,
    required HealthQueryContext healthContext,
  }) async {
    try {
      // Search for nutrition information
      final nutritionQuery =
          'nutrition facts health benefits ${detectedFoods.join(" ")}';

      final nutritionResults = await performSemanticSearch(
        query: nutritionQuery,
        healthContext: healthContext,
        maxResults: 3,
        categoryFilter: ['nutrition', 'wellness'],
      );

      if (nutritionResults.isEmpty) {
        return null;
      }

      final nutritionContext = _buildLLMContext(nutritionResults, 1000);

      final prompt =
          '''
Based on these detected foods: ${detectedFoods.join(", ")}

User Goals: ${healthContext.currentGoals.join(", ")}

Nutrition Knowledge:
$nutritionContext

SAFETY GUIDELINES: Provide general nutrition education only. Do not give medical advice or make health claims. Focus on general wellness information.

Provide a brief, encouraging nutrition insight (2-3 sentences) about these foods that:
1. Highlights general nutritional benefits (not medical claims)
2. Connects to the user's wellness goals (not medical outcomes)
3. Offers practical lifestyle advice (not medical advice)
4. Maintains a positive, motivational tone
5. Includes a note that this is general nutrition information, not medical advice
''';

      final response = await _openAIService.getChatCompletion(prompt);
      if (response != null) {
        return _addSafetyDisclaimer(response);
      } else {
        // Use fallback content if OpenAI fails
        return FallbackContent.getNutritionInsight(detectedFoods);
      }
    } catch (e) {
      Logger.d('Error generating nutrition insights: $e');
      // Use fallback content on error
      return FallbackContent.getNutritionInsight(detectedFoods);
    }
  }

  /// Add safety disclaimer to generated content with validation
  String _addSafetyDisclaimer(String content) {
    if (content.trim().isEmpty) return content;
    
    // First validate and sanitize the content
    final validatedContent = ContentValidationService.validateAndSanitize(content);
    
    // If content was replaced with safe alternative, return it as-is
    if (validatedContent != content) {
      return validatedContent;
    }
    
    const disclaimer = "\n\n*This information is for general wellness purposes only and is not a substitute for professional medical advice, diagnosis, or treatment. Always consult with a healthcare professional for medical concerns.*";
    
    // Check if disclaimer already exists to avoid duplication
    if (content.toLowerCase().contains('not a substitute for professional medical advice') ||
        content.toLowerCase().contains('consult with a healthcare professional')) {
      return content;
    }
    
    return content + disclaimer;
  }

  /// Clear performance statistics
  void clearPerformanceStats() {
    _totalQueries = 0;
    _successfulQueries = 0;
    _averageResponseTime = 0.0;
    _queryTypeStats.clear();
  }

  /// Generate story summary for a time period using RAG
  Future<Map<String, dynamic>> generateStorySummary({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required List<Map<String, dynamic>> stories,
    Map<String, dynamic>? userProfile,
  }) async {
    try {
      if (stories.isEmpty) {
        return {
          'summary': 'No stories found for this time period.',
          'highlights': <String>[],
          'insights': <String>[],
          'mood_analysis': 'neutral',
          'engagement_summary': {},
        };
      }

      // Analyze story content and engagement
      final storyAnalysis = _analyzeStoryContent(stories);

      // Search for relevant health insights based on story content
      final searchResults = await performSemanticSearch(
        query: storyAnalysis['themes'].join(' '),
        maxResults: 5,
      );

      // Build context from search results
      final context = searchResults
          .map((result) => result.document.content)
          .take(5)
          .join('\n\n');

      // Generate comprehensive summary with safety guidelines
      final prompt =
          '''
Based on the following health knowledge and user's story activity from ${_formatDate(startDate)} to ${_formatDate(endDate)}:

HEALTH KNOWLEDGE:
$context

STORY ANALYSIS:
- Total Stories: ${stories.length}
- Content Themes: ${storyAnalysis['themes'].join(', ')}
- Average Engagement: ${storyAnalysis['avgEngagement']}
- Milestone Stories: ${storyAnalysis['milestoneCount']}
- Most Active Day: ${storyAnalysis['mostActiveDay']}
- Content Types: ${storyAnalysis['contentTypes']}

USER PROFILE: ${jsonEncode(userProfile ?? {})}

SAFETY GUIDELINES: Provide general wellness insights only. Do not give medical advice, diagnoses, or treatment recommendations. Focus on general lifestyle and wellness observations.

Generate a comprehensive story summary with:
1. Overall narrative of the time period (focusing on wellness journey, not medical outcomes)
2. Key highlights and achievements (lifestyle and wellness focused)
3. General wellness insights (not medical advice)
4. Mood and engagement analysis (general observations only)
5. General lifestyle recommendations for improvement (not medical advice)

Format as JSON with keys: summary, highlights, insights, mood_analysis, engagement_summary, recommendations.
All content should focus on general wellness and lifestyle, not medical advice.
''';

      final response = await _openAIService.getChatCompletion(prompt);

      try {
        final summaryData = jsonDecode(response ?? '{}');
        if (summaryData is! Map) {
          // Not a map, fallback.
          return _createFallbackStorySummary(stories, startDate, endDate, storyAnalysis);
        }
        final summary = _deepCastToStringDynamic(summaryData);

        return {
          'summary': summary['summary'] ?? 'Summary generated successfully.',
          'highlights': List<String>.from(summary['highlights'] as List? ?? []),
          'insights': List<String>.from(summary['insights'] as List? ?? []),
          'mood_analysis': summary['mood_analysis'] ?? 'neutral',
          'engagement_summary': summary['engagement_summary'] ?? {},
          'recommendations': List<String>.from(
            summary['recommendations'] as List? ?? [],
          ),
          'period': '${_formatDate(startDate)} - ${_formatDate(endDate)}',
          'story_count': stories.length,
          'generated_at': DateTime.now().toIso8601String(),
        };
      } catch (e) {
        // Fallback to structured summary
        return _createFallbackStorySummary(stories, startDate, endDate, storyAnalysis);
      }
    } catch (e) {
      developer.log('Error generating story summary: $e');
      return _createFallbackStorySummary(stories, startDate, endDate, {});
    }
  }

  /// Generate weekly story digest
  Future<Map<String, dynamic>> generateWeeklyDigest({
    required String userId,
    required DateTime weekStart,
    required List<Map<String, dynamic>> stories,
    Map<String, dynamic>? userProfile,
  }) async {
    final weekEnd = weekStart.add(const Duration(days: 7));

    final summary = await generateStorySummary(
      userId: userId,
      startDate: weekStart,
      endDate: weekEnd,
      stories: stories,
      userProfile: userProfile,
    );

    // Add weekly-specific insights
    final weeklyInsights = await _generateWeeklyInsights(stories, userProfile);
    final nextWeekGoals = await _generateNextWeekGoals(stories, userProfile);

    // Ensure proper type casting to prevent runtime type errors
    final result = <String, dynamic>{};
    
    // Deep cast the summary to ensure all nested maps are Map<String, dynamic>
    final castSummary = _deepCastToStringDynamic(summary);
    result.addAll(castSummary);
    
    result['digest_type'] = 'weekly';
    result['week_of'] = _formatDate(weekStart);
    result['weekly_insights'] = weeklyInsights;
    result['next_week_goals'] = nextWeekGoals;

    return result;
  }

  /// Generate monthly story digest
  Future<Map<String, dynamic>> generateMonthlyDigest({
    required String userId,
    required DateTime monthStart,
    required List<Map<String, dynamic>> stories,
    Map<String, dynamic>? userProfile,
  }) async {
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);

    final summary = await generateStorySummary(
      userId: userId,
      startDate: monthStart,
      endDate: monthEnd,
      stories: stories,
      userProfile: userProfile,
    );

    // Add monthly-specific insights
    final monthlyTrends = await _generateMonthlyTrends(stories, userProfile);

    // Ensure proper type casting to prevent runtime type errors
    final result = <String, dynamic>{};
    final castSummary = _deepCastToStringDynamic(summary);
    result.addAll(castSummary);
    result['digest_type'] = 'monthly';
    result['month_of'] = _formatDate(monthStart);
    result['monthly_trends'] = _deepCastToStringDynamic(monthlyTrends);
    result['growth_areas'] = await _generateGrowthAreas(stories, userProfile);
    result['achievement_badges'] = (_calculateAchievementBadges(stories))
        .map((b) => _deepCastToStringDynamic(b))
        .toList();

    return result;
  }

  /// Analyze story content and extract themes
  Map<String, dynamic> _analyzeStoryContent(
    List<Map<String, dynamic>> stories,
  ) {
    final themes = <String>[];
    final contentTypes = <String, int>{};
    var totalEngagement = 0;
    var milestoneCount = 0;
    final dailyActivity = <String, int>{};

    for (final story in stories) {
      // Extract themes from text content
      final text = story['text'] as String? ?? '';
      if (text.isNotEmpty) {
        themes.addAll(_extractThemes(text));
      }

      // Count content types
      final type = story['type'] as String? ?? 'unknown';
      contentTypes[type] = (contentTypes[type] ?? 0) + 1;

      // Calculate engagement
      final engagement = story['engagement'] as Map<String, dynamic>? ?? {};
      final storyEngagement =
          (engagement['views'] as int? ?? 0) +
          (engagement['likes'] as int? ?? 0) +
          (engagement['comments'] as int? ?? 0) +
          (engagement['shares'] as int? ?? 0);
      totalEngagement += storyEngagement;

      // Check for milestone stories
      final permanence = story['permanence'] as Map<String, dynamic>?;
      final tier = permanence?['tier'] as String?;
      if (tier == 'milestone' || tier == 'monthly' || tier == 'weekly') {
        milestoneCount++;
      }

      // Track daily activity
      final timestamp = story['timestamp'];
      if (timestamp != null) {
        final date = timestamp is DateTime
            ? timestamp
            : DateTime.parse(timestamp.toString());
        final dateKey = _formatDate(date);
        dailyActivity[dateKey] = (dailyActivity[dateKey] ?? 0) + 1;
      }
    }

    final mostActiveDay =
        dailyActivity.entries
            .fold<MapEntry<String, int>?>(
              null,
              (prev, curr) =>
                  prev == null || curr.value > prev.value ? curr : prev,
            )
            ?.key ??
        'N/A';

    return {
      'themes': themes.toSet().toList(),
      'contentTypes': contentTypes,
      'avgEngagement': stories.isNotEmpty
          ? totalEngagement / stories.length
          : 0,
      'milestoneCount': milestoneCount,
      'mostActiveDay': mostActiveDay,
      'dailyActivity': dailyActivity,
    };
  }

  /// Extract themes from text content
  List<String> _extractThemes(String text) {
    final themes = <String>[];
    final lowerText = text.toLowerCase();

    // Health and wellness themes
    if (lowerText.contains(
      RegExp(r'\b(workout|exercise|gym|fitness|training)\b'),
    )) {
      themes.add('fitness');
    }
    if (lowerText.contains(RegExp(r'\b(meal|food|eating|nutrition|diet)\b'))) {
      themes.add('nutrition');
    }
    if (lowerText.contains(RegExp(r'\b(fasting|fast|intermittent)\b'))) {
      themes.add('fasting');
    }
    if (lowerText.contains(RegExp(r'\b(meditation|mindful|stress|relax)\b'))) {
      themes.add('wellness');
    }
    if (lowerText.contains(RegExp(r'\b(sleep|rest|recovery)\b'))) {
      themes.add('recovery');
    }
    if (lowerText.contains(
      RegExp(r'\b(goal|achievement|progress|milestone)\b'),
    )) {
      themes.add('achievement');
    }

    return themes;
  }

  /// Generate weekly insights
  Future<List<String>> _generateWeeklyInsights(
    List<Map<String, dynamic>> stories,
    Map<String, dynamic>? userProfile,
  ) async {
    final insights = <String>[];

    // Analyze weekly patterns
    final weekdayActivity = <int, int>{};
    for (final story in stories) {
      final timestamp = story['timestamp'];
      if (timestamp != null) {
        final date = timestamp is DateTime
            ? timestamp
            : DateTime.parse(timestamp.toString());
        final weekday = date.weekday;
        weekdayActivity[weekday] = (weekdayActivity[weekday] ?? 0) + 1;
      }
    }

    if (weekdayActivity.isNotEmpty) {
      final mostActiveWeekday = weekdayActivity.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      insights.add('Most active on ${_getWeekdayName(mostActiveWeekday.key)}');
    }

    return insights;
  }

  /// Generate next week goals
  Future<List<String>> _generateNextWeekGoals(
    List<Map<String, dynamic>> stories,
    Map<String, dynamic>? userProfile,
  ) async {
    return [
      'Continue sharing your health journey',
      'Try a new type of content',
      'Engage more with community stories',
    ];
  }

  /// Generate monthly trends
  Future<Map<String, dynamic>> _generateMonthlyTrends(
    List<Map<String, dynamic>> stories,
    Map<String, dynamic>? userProfile,
  ) async {
    return {
      'content_growth': 'steady',
      'engagement_trend': 'increasing',
      'milestone_progress': 'on_track',
    };
  }

  /// Generate growth areas
  Future<List<String>> _generateGrowthAreas(
    List<Map<String, dynamic>> stories,
    Map<String, dynamic>? userProfile,
  ) async {
    return [
      'Diversify content types',
      'Increase engagement with others',
      'Share more milestone moments',
    ];
  }

  /// Calculate achievement badges
  List<Map<String, dynamic>> _calculateAchievementBadges(
    List<Map<String, dynamic>> stories,
  ) {
    final badges = <Map<String, dynamic>>[];

    if (stories.length >= 30) {
      badges.add({
        'name': 'Consistent Creator',
        'icon': 'star',
        'description': '30+ stories this month',
      });
    }

    final milestoneCount = stories.where((story) {
      final permanence = story['permanence'] as Map<String, dynamic>?;
      final tier = permanence?['tier'] as String?;
      return tier == 'milestone' || tier == 'monthly';
    }).length;

    if (milestoneCount >= 3) {
      badges.add({
        'name': 'Milestone Master',
        'icon': 'trophy',
        'description': '3+ milestone stories',
      });
    }

    return badges;
  }

  /// Create fallback story summary
  Map<String, dynamic> _createFallbackStorySummary(
    List<Map<String, dynamic>> stories,
    DateTime startDate,
    DateTime endDate,
    Map<String, dynamic> analysis,
  ) {
    return {
      'summary':
          'You shared ${stories.length} stories during this period, '
          'capturing various moments of your health and wellness journey.',
      'highlights': [
        '${stories.length} stories shared',
        if (analysis['milestoneCount'] != null &&
            analysis['milestoneCount'] > 0)
          '${analysis['milestoneCount']} milestone stories created',
        'Consistent engagement with your community',
      ],
      'insights': [
        'Keep sharing your journey to inspire others',
        'Your stories help track your progress over time',
        'Engagement shows your community values your content',
      ],
      'mood_analysis': 'positive',
      'engagement_summary': {
        'total_stories': stories.length,
        'period_days': endDate.difference(startDate).inDays,
      },
      'recommendations': [
        'Continue documenting your health journey',
        'Try different types of content',
        'Engage with others\' stories for motivation',
      ],
      'period': '${_formatDate(startDate)} - ${_formatDate(endDate)}',
      'story_count': stories.length,
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get weekday name
  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[weekday - 1];
  }

  Map<String, dynamic> _deepCastToStringDynamic(Map input) {
    dynamic castValue(dynamic value) {
      if (value is Map) {
        final result = <String, dynamic>{};
        value.forEach((key, val) {
          result[key.toString()] = castValue(val);
        });
        return result;
      } else if (value is List) {
        return value.map((e) => castValue(e)).toList();
      } else if (value is Timestamp) {
        return (value).toDate().toIso8601String();
      } else {
        return value;
      }
    }

    return castValue(input) as Map<String, dynamic>;
  }

  // NUTRITIONAL QUERY HELPER METHODS

  /// Get nutrition-specific categories for filtering
  List<String> _getNutritionCategories() {
    return [
      'vegetables',
      'fruits',
      'protein',
      'dairy',
      'grains',
      'carbohydrates',
      'fats',
      'nuts',
      'seafood',
      'beverages',
    ];
  }

  /// Build specialized nutrition context from search results
  String _buildNutritionContext(List<SearchResult> results) {
    final contextParts = <String>[];
    
    for (final result in results) {
      final doc = result.document;
      final metadata = doc.metadata;
      
      // Extract nutritional metadata if available
      final calories = metadata['calories_per_100g']?.toString() ?? 'N/A';
      final protein = metadata['protein_per_100g']?.toString() ?? 'N/A';
      final carbs = metadata['carbs_per_100g']?.toString() ?? 'N/A';
      final fat = metadata['fat_per_100g']?.toString() ?? 'N/A';
      
      final nutritionData = calories != 'N/A' 
          ? 'Nutrition per 100g: ${calories}cal, ${protein}g protein, ${carbs}g carbs, ${fat}g fat'
          : '';
      
      final snippet = '''
Food: ${doc.title.replaceAll('Nutritional Information: ', '')}
Category: ${doc.category}
${nutritionData}
Information: ${doc.content.length > 300 ? doc.content.substring(0, 300) + '...' : doc.content}
Relevance: ${(result.relevanceScore * 100).toInt()}%
''';
      
      contextParts.add(snippet);
    }
    
    return contextParts.join('\n---\n\n');
  }

  /// Build nutrition-specific system prompt
  String _buildNutritionSystemPrompt(List<String>? dietaryRestrictions) {
    final restrictions = dietaryRestrictions?.isNotEmpty == true 
        ? 'User dietary restrictions: ${dietaryRestrictions!.join(", ")}'
        : 'No specific dietary restrictions mentioned';
    
    return '''
You are a knowledgeable nutrition education assistant for SnapAMeal. Your role is to provide evidence-based nutritional information using the knowledge base.

$restrictions

CRITICAL SAFETY GUIDELINES:
- NEVER provide medical advice, diagnoses, or treatment recommendations
- NEVER suggest specific medications, supplements, or medical procedures
- NEVER claim to replace healthcare professionals or medical consultations
- AVOID making definitive health claims or promises about outcomes
- DO NOT provide advice for serious medical conditions, eating disorders, or mental health issues
- ALWAYS include disclaimers when appropriate

Your expertise:
1. Provide evidence-based nutritional facts from the knowledge base
2. Explain food composition, nutrients, and general nutritional benefits
3. Compare foods based on nutritional content
4. Suggest foods rich in specific nutrients
5. Offer general wellness and lifestyle information
6. Respect dietary restrictions and preferences

Guidelines:
- Use factual, educational tone
- Reference specific information from the knowledge base
- Provide practical, actionable information
- Be encouraging about healthy lifestyle choices
- Always prioritize safety and general wellness information
- Include appropriate disclaimers about not replacing professional advice

Format responses clearly with:
- Key nutritional facts
- Practical usage suggestions
- Relevant comparisons when helpful
- General wellness context
''';
  }

  /// Build nutrition-specific user prompt
  String _buildNutritionUserPrompt(String query, String context) {
    return '''
User Question: $query

Relevant Nutritional Knowledge:
$context

Please provide a comprehensive, educational response about the nutritional aspects of this query. Use the specific information from the knowledge base and present it in a clear, helpful way.
''';
  }

  /// Build comparison context for food comparisons
  String _buildComparisonContext(List<SearchResult> results, List<String> foodNames) {
    final foodData = <String, List<SearchResult>>{};
    
    // Group results by food
    for (final result in results) {
      for (final foodName in foodNames) {
        if (result.document.title.toLowerCase().contains(foodName.toLowerCase()) ||
            result.document.content.toLowerCase().contains(foodName.toLowerCase())) {
          foodData[foodName] ??= [];
          foodData[foodName]!.add(result);
          break;
        }
      }
    }
    
    final contextParts = <String>[];
    
    for (final foodName in foodNames) {
      final foodResults = foodData[foodName] ?? [];
      if (foodResults.isNotEmpty) {
        final bestResult = foodResults.first;
        final doc = bestResult.document;
        final metadata = doc.metadata;
        
        final calories = metadata['calories_per_100g']?.toString() ?? 'N/A';
        final protein = metadata['protein_per_100g']?.toString() ?? 'N/A';
        final carbs = metadata['carbs_per_100g']?.toString() ?? 'N/A';
        final fat = metadata['fat_per_100g']?.toString() ?? 'N/A';
        
        contextParts.add('''
$foodName:
- Calories per 100g: $calories
- Protein per 100g: ${protein}g
- Carbohydrates per 100g: ${carbs}g
- Fat per 100g: ${fat}g
- Category: ${doc.category}
- Details: ${doc.content.length > 200 ? doc.content.substring(0, 200) + '...' : doc.content}
''');
      } else {
        contextParts.add('$foodName: Limited nutritional data available');
      }
    }
    
    return contextParts.join('\n\n');
  }

  /// Build comparison system prompt
  String _buildComparisonSystemPrompt(List<String>? dietaryRestrictions) {
    return '''
You are a nutrition education assistant specializing in food comparisons. Provide factual, evidence-based comparisons using the nutritional knowledge base.

${dietaryRestrictions?.isNotEmpty == true ? 'User dietary restrictions: ${dietaryRestrictions!.join(", ")}' : ''}

SAFETY GUIDELINES: Provide educational nutritional comparisons only. Never give medical advice or make health claims.

Your task:
1. Compare foods based on nutritional content from the knowledge base
2. Highlight key differences in macronutrients, micronutrients, and calories
3. Provide context about when each food might be preferred
4. Consider dietary restrictions if mentioned
5. Present information in a clear, comparative format

Format:
- Direct nutritional comparisons with specific numbers
- Practical implications of the differences
- General usage suggestions for each food
- Educational context about the nutrients
''';
  }

  /// Build comparison user prompt
  String _buildComparisonUserPrompt(List<String> foodNames, String? comparisonAspect, String context) {
    final aspect = comparisonAspect != null ? ' focusing on $comparisonAspect' : '';
    
    return '''
Compare the nutritional content of: ${foodNames.join(" vs ")}$aspect

Nutritional Data:
$context

Please provide a detailed comparison highlighting the key nutritional differences and similarities between these foods.
''';
  }

  /// Build nutrient context for foods high in specific nutrients
  String _buildNutrientContext(List<SearchResult> results, String nutrient) {
    final contextParts = <String>[];
    
    for (final result in results) {
      final doc = result.document;
      final metadata = doc.metadata;
      
      // Extract relevant nutrient data
      final relevantInfo = _extractNutrientInfo(doc.content, nutrient);
      final nutritionSummary = _buildNutritionSummary(metadata);
      
      contextParts.add('''
${doc.title.replaceAll('Nutritional Information: ', '')}:
${nutritionSummary}
${nutrient.toUpperCase()} Content: $relevantInfo
Category: ${doc.category}
Benefits: ${doc.content.contains('Health Benefits:') ? doc.content.split('Health Benefits:')[1].split('Usage Tips:')[0].trim() : 'General nutritional benefits'}
''');
    }
    
    return contextParts.join('\n\n');
  }

  /// Extract nutrient-specific information from content
  String _extractNutrientInfo(String content, String nutrient) {
    final lines = content.split('\n');
    for (final line in lines) {
      if (line.toLowerCase().contains(nutrient.toLowerCase())) {
        return line.trim();
      }
    }
    return 'Contains $nutrient';
  }

  /// Build nutrition summary from metadata
  String _buildNutritionSummary(Map<String, dynamic> metadata) {
    final calories = metadata['calories_per_100g']?.toString();
    final protein = metadata['protein_per_100g']?.toString();
    final carbs = metadata['carbs_per_100g']?.toString();
    final fat = metadata['fat_per_100g']?.toString();
    
    if (calories != null || protein != null || carbs != null || fat != null) {
      return 'Per 100g: ${calories ?? '?'}cal, ${protein ?? '?'}g protein, ${carbs ?? '?'}g carbs, ${fat ?? '?'}g fat';
    }
    
    return 'Nutritional data available';
  }

  /// Build nutrient system prompt
  String _buildNutrientSystemPrompt(List<String>? dietaryRestrictions) {
    return '''
You are a nutrition education assistant helping users find foods rich in specific nutrients. Use the knowledge base to provide evidence-based recommendations.

${dietaryRestrictions?.isNotEmpty == true ? 'User dietary restrictions: ${dietaryRestrictions!.join(", ")}' : ''}

SAFETY GUIDELINES: Provide educational information about nutrient-rich foods only. Never give medical advice or make health claims.

Your task:
1. Identify foods that are excellent sources of the requested nutrient
2. Explain the nutritional benefits of the nutrient
3. Provide practical suggestions for incorporating these foods
4. Consider dietary restrictions if mentioned
5. Offer variety in food suggestions

Format:
- List of top food sources with specific nutrient content
- Brief explanation of the nutrient's role in general wellness
- Practical tips for including these foods in meals
- Variety suggestions across different food categories
''';
  }

  /// Build nutrient user prompt
  String _buildNutrientUserPrompt(String nutrient, String context) {
    return '''
Find foods that are excellent sources of: $nutrient

Available Food Information:
$context

Please provide a comprehensive list of foods high in $nutrient, with practical suggestions for incorporating them into meals.
''';
  }

  /// Filter search results by nutrient relevance
  List<SearchResult> _filterByNutrientRelevance(List<SearchResult> results, String nutrient) {
    // Score results based on nutrient relevance
    final scoredResults = results.map((result) {
      double nutrientScore = 0.0;
      final content = result.document.content.toLowerCase();
      final title = result.document.title.toLowerCase();
      final nutrientLower = nutrient.toLowerCase();
      
      // Higher score for nutrient mentions in title
      if (title.contains(nutrientLower)) {
        nutrientScore += 0.5;
      }
      
      // Score for nutrient mentions in content
      final nutrientMentions = RegExp(nutrientLower).allMatches(content).length;
      nutrientScore += nutrientMentions * 0.1;
      
      // Bonus for specific nutrient phrases
      if (content.contains('high in $nutrientLower') || 
          content.contains('rich in $nutrientLower') ||
          content.contains('excellent source of $nutrientLower') ||
          content.contains('good source of $nutrientLower')) {
        nutrientScore += 0.3;
      }
      
      return MapEntry(result, nutrientScore);
    }).toList();
    
    // Sort by combined relevance and nutrient score
    scoredResults.sort((a, b) {
      final scoreA = a.value + a.key.relevanceScore;
      final scoreB = b.value + b.key.relevanceScore;
      return scoreB.compareTo(scoreA);
    });
    
    return scoredResults.map((entry) => entry.key).toList();
  }

  /// Generate fallback response for nutritional queries
  Future<String?> _generateNutritionFallbackResponse(String query, List<String>? dietaryRestrictions) async {
    final restrictions = dietaryRestrictions?.isNotEmpty == true 
        ? ' considering your dietary restrictions (${dietaryRestrictions!.join(", ")})'
        : '';
    
    return '''
I don't have specific nutritional information in my knowledge base to fully answer your question about "$query"$restrictions.

For comprehensive nutritional information, I recommend:
• Consulting with a registered dietitian or nutritionist
• Using verified nutrition databases like USDA FoodData Central
• Speaking with your healthcare provider about specific dietary needs

*This information is for general wellness purposes only and is not a substitute for professional medical advice, diagnosis, or treatment.*
''';
  }

  /// Generate fallback response for food comparisons
  Future<String?> _generateComparisonFallbackResponse(List<String> foodNames, String? comparisonAspect) async {
    final aspect = comparisonAspect != null ? ' regarding $comparisonAspect' : '';
    
    return '''
I don't have sufficient nutritional data in my knowledge base to compare ${foodNames.join(" and ")}$aspect.

For accurate nutritional comparisons, I recommend:
• Checking verified nutrition databases like USDA FoodData Central
• Using nutrition tracking apps with comprehensive food databases
• Consulting with a registered dietitian for personalized comparisons

*This information is for general wellness purposes only and is not a substitute for professional medical advice, diagnosis, or treatment.*
''';
  }

  /// Generate fallback response for nutrient-rich food queries
  Future<String?> _generateNutrientFallbackResponse(String nutrient, List<String>? dietaryRestrictions) async {
    final restrictions = dietaryRestrictions?.isNotEmpty == true 
        ? ' that fit your dietary restrictions (${dietaryRestrictions!.join(", ")})'
        : '';
    
    return '''
I don't have sufficient information in my knowledge base about foods high in $nutrient$restrictions.

For finding foods rich in specific nutrients, I recommend:
• Consulting verified nutrition databases like USDA FoodData Central
• Speaking with a registered dietitian about nutrient-rich foods
• Using comprehensive nutrition tracking apps

*This information is for general wellness purposes only and is not a substitute for professional medical advice, diagnosis, or treatment.*
''';
  }

  /// Add nutrition-specific disclaimer
  String _addNutritionDisclaimer(String content) {
    if (content.trim().isEmpty) return content;
    
    const disclaimer = "\n\n*This nutritional information is for educational purposes only and is not a substitute for professional medical advice, diagnosis, or treatment. Always consult with a healthcare professional or registered dietitian for personalized nutrition advice.*";
    
    // Check if disclaimer already exists
    if (content.toLowerCase().contains('not a substitute for professional medical advice') ||
        content.toLowerCase().contains('consult with a healthcare professional')) {
      return content;
    }
    
    return content + disclaimer;
  }
}
