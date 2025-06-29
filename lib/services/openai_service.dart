/// OpenAI API Integration Service for SnapAMeal Phase II
/// Handles GPT-4 chat completions and embedding generation with cost optimization
library;

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/ai_config.dart';
import '../utils/logger.dart';

/// Response model for OpenAI chat completions
class ChatCompletionResponse {
  final String content;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final String model;

  ChatCompletionResponse({
    required this.content,
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    required this.model,
  });

  factory ChatCompletionResponse.fromJson(Map<String, dynamic> json) {
    final choice = json['choices'][0];
    final usage = json['usage'];

    return ChatCompletionResponse(
      content: choice['message']['content'],
      promptTokens: usage['prompt_tokens'],
      completionTokens: usage['completion_tokens'],
      totalTokens: usage['total_tokens'],
      model: json['model'],
    );
  }
}

/// Response model for OpenAI embeddings
class EmbeddingResponse {
  final List<double> embedding;
  final int promptTokens;
  final int totalTokens;
  final String model;

  EmbeddingResponse({
    required this.embedding,
    required this.promptTokens,
    required this.totalTokens,
    required this.model,
  });

  factory EmbeddingResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'][0];
    final usage = json['usage'];

    return EmbeddingResponse(
      embedding: List<double>.from(data['embedding']),
      promptTokens: usage['prompt_tokens'],
      totalTokens: usage['total_tokens'],
      model: json['model'],
    );
  }
}

/// API usage statistics for monitoring and cost control
class APIUsageStats {
  final int chatCompletions;
  final int embeddings;
  final int totalTokensUsed;
  final int promptTokens;
  final int completionTokens;
  final double estimatedCost;
  final DateTime lastReset;
  final Map<String, int> modelUsage;
  final Map<String, double> dailyCosts;

  APIUsageStats({
    required this.chatCompletions,
    required this.embeddings,
    required this.totalTokensUsed,
    required this.promptTokens,
    required this.completionTokens,
    required this.estimatedCost,
    required this.lastReset,
    required this.modelUsage,
    required this.dailyCosts,
  });

  Map<String, dynamic> toJson() {
    return {
      'chat_completions': chatCompletions,
      'embeddings': embeddings,
      'total_tokens_used': totalTokensUsed,
      'prompt_tokens': promptTokens,
      'completion_tokens': completionTokens,
      'estimated_cost': estimatedCost,
      'last_reset': lastReset.toIso8601String(),
      'model_usage': modelUsage,
      'daily_costs': dailyCosts,
    };
  }

  factory APIUsageStats.fromJson(Map<String, dynamic> json) {
    return APIUsageStats(
      chatCompletions: json['chat_completions'] ?? 0,
      embeddings: json['embeddings'] ?? 0,
      totalTokensUsed: json['total_tokens_used'] ?? 0,
      promptTokens: json['prompt_tokens'] ?? 0,
      completionTokens: json['completion_tokens'] ?? 0,
      estimatedCost: json['estimated_cost']?.toDouble() ?? 0.0,
      lastReset: DateTime.parse(
        json['last_reset'] ?? DateTime.now().toIso8601String(),
      ),
      modelUsage: Map<String, int>.from(json['model_usage'] ?? {}),
      dailyCosts: Map<String, double>.from(json['daily_costs'] ?? {}),
    );
  }

  factory APIUsageStats.empty() {
    return APIUsageStats(
      chatCompletions: 0,
      embeddings: 0,
      totalTokensUsed: 0,
      promptTokens: 0,
      completionTokens: 0,
      estimatedCost: 0.0,
      lastReset: DateTime.now(),
      modelUsage: {},
      dailyCosts: {},
    );
  }
}

/// Cost optimization configuration and tracking
class CostOptimizer {
  // Cache for embeddings to reduce duplicate API calls
  final Map<String, List<double>> _embeddingCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Batch processing queues
  final List<String> _embeddingQueue = [];

  // Performance tracking
  int _cacheHits = 0;
  int _cacheMisses = 0;
  final double _totalSavings = 0.0;

  CostOptimizer();

  /// Check if embedding is cached and still valid
  List<double>? getCachedEmbedding(String text) {
    final key = _generateCacheKey(text);
    final timestamp = _cacheTimestamps[key];

    if (timestamp != null && _embeddingCache.containsKey(key)) {
      final age = DateTime.now().difference(timestamp);
      if (age.inHours < AIConfig.cacheExpirationHours) {
        _cacheHits++;
        return _embeddingCache[key];
      } else {
        // Cache expired, remove it
        _embeddingCache.remove(key);
        _cacheTimestamps.remove(key);
      }
    }

    _cacheMisses++;
    return null;
  }

  /// Cache an embedding result
  void cacheEmbedding(String text, List<double> embedding) {
    final key = _generateCacheKey(text);
    _embeddingCache[key] = embedding;
    _cacheTimestamps[key] = DateTime.now();

    // Clean old cache entries if cache is getting too large
    if (_embeddingCache.length > AIConfig.maxCacheSize) {
      _cleanCache();
    }
  }

  /// Add text to embedding batch queue
  void addToEmbeddingQueue(String text) {
    if (!_embeddingQueue.contains(text)) {
      _embeddingQueue.add(text);
    }
  }

  /// Process embedding queue in batch
  Future<Map<String, List<double>>> processBatchEmbeddings() async {
    if (_embeddingQueue.isEmpty) return {};

    final results = <String, List<double>>{};
    final uncachedTexts = <String>[];

    // Check cache first
    for (final text in _embeddingQueue) {
      final cached = getCachedEmbedding(text);
      if (cached != null) {
        results[text] = cached;
      } else {
        uncachedTexts.add(text);
      }
    }

    // Process uncached texts
    if (uncachedTexts.isNotEmpty) {
      // Process in smaller batches to avoid API limits
      const batchSize = 10;
      for (int i = 0; i < uncachedTexts.length; i += batchSize) {
        final batch = uncachedTexts.skip(i).take(batchSize).toList();
        // Note: OpenAI API doesn't support batch embeddings, so we process individually
        for (final _ in batch) {
          // This would be implemented in the main service
          // results[text] = await generateSingleEmbedding(text);
        }
      }
    }

    _embeddingQueue.clear();
    return results;
  }

  /// Generate cache key for text
  String _generateCacheKey(String text) {
    // Simple hash of the text for caching
    return text.hashCode.toString();
  }

  /// Clean expired cache entries
  void _cleanCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value).inHours >=
          AIConfig.cacheExpirationHours) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _embeddingCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    // If still too large, remove oldest entries
    if (_embeddingCache.length > AIConfig.maxCacheSize) {
      final sortedEntries = _cacheTimestamps.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      final toRemove = _embeddingCache.length - AIConfig.maxCacheSize + 10;
      for (int i = 0; i < toRemove && i < sortedEntries.length; i++) {
        final key = sortedEntries[i].key;
        _embeddingCache.remove(key);
        _cacheTimestamps.remove(key);
      }
    }
  }

  /// Get cache performance stats
  Map<String, dynamic> getCacheStats() {
    final totalRequests = _cacheHits + _cacheMisses;
    final hitRate = totalRequests > 0 ? _cacheHits / totalRequests : 0.0;

    return {
      'cache_hits': _cacheHits,
      'cache_misses': _cacheMisses,
      'hit_rate': hitRate,
      'cache_size': _embeddingCache.length,
      'total_savings': _totalSavings,
    };
  }

  /// Clear all caches
  void clearCache() {
    _embeddingCache.clear();
    _cacheTimestamps.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
  }
}

/// Enhanced OpenAI service with comprehensive monitoring and optimization
class OpenAIService {
  final CostOptimizer _optimizer = CostOptimizer();

  // Usage tracking
  APIUsageStats _currentStats = APIUsageStats.empty();

  // Rate limiting
  final List<DateTime> _chatRequestTimes = [];
  final List<DateTime> _embeddingRequestTimes = [];

  // Budget controls
  bool _budgetExceeded = false;
  String? _budgetExceededMessage;

  OpenAIService();

  /// Initialize the service and load cached stats
  Future<void> initialize() async {
    await _loadUsageStats();
    await _checkBudgetStatus();
  }

  /// Simple chat completion with a single prompt
  Future<String?> getChatCompletion(String prompt) async {
    return await getChatCompletionWithMessages(
      messages: [
        {'role': 'user', 'content': prompt},
      ],
    );
  }

  /// Generate chat completion with monitoring and optimization
  Future<String?> getChatCompletionWithMessages({
    required List<Map<String, String>> messages,
    String model = 'gpt-4',
    int maxTokens = 500,
    double temperature = 0.7,
    bool useOptimization = true,
  }) async {
    // Check if API key is configured
    if (AIConfig.openaiApiKey.isEmpty) {
      Logger.d(
        'OpenAI API key not configured. Please add OPENAI_API_KEY to your .env file.',
      );
      return null;
    }

    // Check budget and rate limits
    if (!await _checkBudgetAndLimits('chat')) {
      return null;
    }

    // Apply cost optimization
    if (useOptimization) {
      model = _optimizeModelSelection(model, messages);
      maxTokens = _optimizeTokenLimit(maxTokens, messages);
    }

    try {
      final startTime = DateTime.now();

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${AIConfig.openaiApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': model,
          'messages': messages,
          'max_tokens': maxTokens,
          'temperature': temperature,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        final usage = data['usage'];

        // Track usage and costs
        await _trackChatUsage(
          model: model,
          promptTokens: usage['prompt_tokens'],
          completionTokens: usage['completion_tokens'],
          responseTime: DateTime.now().difference(startTime),
        );

        return content;
      } else if (response.statusCode == 429) {
        // Rate limit exceeded
        Logger.d('OpenAI rate limit exceeded. Waiting before retry...');
        await Future.delayed(
          Duration(seconds: AIConfig.rateLimitBackoffSeconds),
        );
        return await getChatCompletionWithMessages(
          messages: messages,
          model: model,
          maxTokens: maxTokens,
          temperature: temperature,
          useOptimization: false, // Don't re-optimize on retry
        );
      } else {
        throw Exception(
          'OpenAI API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      Logger.d('Error getting chat completion: $e');
      return null;
    }
  }

  /// Generate embedding with caching and optimization
  Future<List<double>?> generateEmbedding(
    String text, {
    String model = 'text-embedding-ada-002',
    bool useCache = true,
  }) async {
    // Check if API key is configured
    if (AIConfig.openaiApiKey.isEmpty) {
      Logger.d(
        'OpenAI API key not configured. Please add OPENAI_API_KEY to your .env file.',
      );
      return null;
    }

    // Check cache first
    if (useCache) {
      final cached = _optimizer.getCachedEmbedding(text);
      if (cached != null) {
        return cached;
      }
    }

    // Check budget and rate limits
    if (!await _checkBudgetAndLimits('embedding')) {
      return null;
    }

    try {
      final startTime = DateTime.now();

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/embeddings'),
        headers: {
          'Authorization': 'Bearer ${AIConfig.openaiApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'model': model, 'input': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final embedding = List<double>.from(data['data'][0]['embedding']);
        final usage = data['usage'];

        // Cache the result
        if (useCache) {
          _optimizer.cacheEmbedding(text, embedding);
        }

        // Track usage and costs
        await _trackEmbeddingUsage(
          model: model,
          tokens: usage['total_tokens'],
          responseTime: DateTime.now().difference(startTime),
        );

        return embedding;
      } else if (response.statusCode == 429) {
        // Rate limit exceeded
        Logger.d('OpenAI rate limit exceeded. Waiting before retry...');
        await Future.delayed(
          Duration(seconds: AIConfig.rateLimitBackoffSeconds),
        );
        return await generateEmbedding(text, model: model, useCache: useCache);
      } else {
        throw Exception(
          'OpenAI API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      Logger.d('Error generating embedding: $e');
      return null;
    }
  }

  /// Generate multiple embeddings efficiently
  Future<List<List<double>?>> generateBatchEmbeddings(
    List<String> texts, {
    String model = 'text-embedding-ada-002',
    bool useCache = true,
  }) async {
    final results = <List<double>?>[];

    // Process in smaller batches to respect rate limits
    const batchSize = 5;
    for (int i = 0; i < texts.length; i += batchSize) {
      final batch = texts.skip(i).take(batchSize).toList();

      for (final text in batch) {
        final embedding = await generateEmbedding(
          text,
          model: model,
          useCache: useCache,
        );
        results.add(embedding);

        // Small delay between requests to avoid rate limiting
        if (i + batch.indexOf(text) < texts.length - 1) {
          await Future.delayed(Duration(milliseconds: 100));
        }
      }
    }

    return results;
  }

  /// Check budget constraints and rate limits
  Future<bool> _checkBudgetAndLimits(String requestType) async {
    // Check daily budget
    if (_budgetExceeded) {
      Logger.d('Daily budget exceeded: $_budgetExceededMessage');
      return false;
    }

    // Check request limits
    await _cleanOldRequestTimes();

    if (requestType == 'chat') {
      if (_chatRequestTimes.length >= AIConfig.maxDailyChatRequests) {
        Logger.d('Daily chat request limit exceeded');
        return false;
      }
      _chatRequestTimes.add(DateTime.now());
    } else if (requestType == 'embedding') {
      if (_embeddingRequestTimes.length >= AIConfig.maxDailyEmbeddingRequests) {
        Logger.d('Daily embedding request limit exceeded');
        return false;
      }
      _embeddingRequestTimes.add(DateTime.now());
    }

    return true;
  }

  /// Clean old request timestamps (older than 24 hours)
  Future<void> _cleanOldRequestTimes() async {
    final cutoff = DateTime.now().subtract(Duration(hours: 24));

    _chatRequestTimes.removeWhere((time) => time.isBefore(cutoff));
    _embeddingRequestTimes.removeWhere((time) => time.isBefore(cutoff));
  }

  /// Optimize model selection based on request complexity
  String _optimizeModelSelection(
    String requestedModel,
    List<Map<String, String>> messages,
  ) {
    // Calculate rough complexity score
    final totalLength = messages
        .map((msg) => msg['content']?.length ?? 0)
        .reduce((a, b) => a + b);

    // Use cheaper models for simpler requests
    if (totalLength < 500 && requestedModel == 'gpt-4') {
      return 'gpt-3.5-turbo'; // Much cheaper alternative
    }

    return requestedModel;
  }

  /// Optimize token limits based on context
  int _optimizeTokenLimit(
    int requestedTokens,
    List<Map<String, String>> messages,
  ) {
    // Calculate context length
    final contextLength = messages
        .map(
          (msg) => (msg['content']?.length ?? 0) ~/ 4,
        ) // Rough token estimate
        .reduce((a, b) => a + b);

    // Reduce max tokens if context is already large
    if (contextLength > 2000) {
      return min(requestedTokens, 300);
    }

    return requestedTokens;
  }

  /// Track chat completion usage
  Future<void> _trackChatUsage({
    required String model,
    required int promptTokens,
    required int completionTokens,
    required Duration responseTime,
  }) async {
    final cost = _calculateChatCost(model, promptTokens, completionTokens);

    _currentStats = APIUsageStats(
      chatCompletions: _currentStats.chatCompletions + 1,
      embeddings: _currentStats.embeddings,
      totalTokensUsed:
          _currentStats.totalTokensUsed + promptTokens + completionTokens,
      promptTokens: _currentStats.promptTokens + promptTokens,
      completionTokens: _currentStats.completionTokens + completionTokens,
      estimatedCost: _currentStats.estimatedCost + cost,
      lastReset: _currentStats.lastReset,
      modelUsage: {
        ..._currentStats.modelUsage,
        model: (_currentStats.modelUsage[model] ?? 0) + 1,
      },
      dailyCosts: _updateDailyCosts(_currentStats.dailyCosts, cost),
    );

    await _saveUsageStats();
    await _checkBudgetStatus();
  }

  /// Track embedding usage
  Future<void> _trackEmbeddingUsage({
    required String model,
    required int tokens,
    required Duration responseTime,
  }) async {
    final cost = _calculateEmbeddingCost(model, tokens);

    _currentStats = APIUsageStats(
      chatCompletions: _currentStats.chatCompletions,
      embeddings: _currentStats.embeddings + 1,
      totalTokensUsed: _currentStats.totalTokensUsed + tokens,
      promptTokens: _currentStats.promptTokens + tokens,
      completionTokens: _currentStats.completionTokens,
      estimatedCost: _currentStats.estimatedCost + cost,
      lastReset: _currentStats.lastReset,
      modelUsage: {
        ..._currentStats.modelUsage,
        model: (_currentStats.modelUsage[model] ?? 0) + 1,
      },
      dailyCosts: _updateDailyCosts(_currentStats.dailyCosts, cost),
    );

    await _saveUsageStats();
    await _checkBudgetStatus();
  }

  /// Calculate cost for chat completion
  double _calculateChatCost(
    String model,
    int promptTokens,
    int completionTokens,
  ) {
    // OpenAI pricing (as of 2024) - update these values based on current pricing
    final pricing = {
      'gpt-4': {
        'prompt': 0.00003,
        'completion': 0.00006,
      }, // $30/$60 per 1M tokens
      'gpt-4o': {
        'prompt': 0.000005,
        'completion': 0.000015,
      }, // $5/$15 per 1M tokens
      'gpt-3.5-turbo': {
        'prompt': 0.0000015,
        'completion': 0.000002,
      }, // $1.5/$2 per 1M tokens
    };

    final modelPricing = pricing[model] ?? pricing['gpt-3.5-turbo']!;
    final promptCost = promptTokens * modelPricing['prompt']!;
    final completionCost = completionTokens * modelPricing['completion']!;

    return promptCost + completionCost;
  }

  /// Calculate cost for embeddings
  double _calculateEmbeddingCost(String model, int tokens) {
    // OpenAI pricing for embeddings
    final pricing = {
      'text-embedding-ada-002': 0.0000001, // $0.1 per 1M tokens
      'text-embedding-3-small': 0.00000002, // $0.02 per 1M tokens
      'text-embedding-3-large': 0.00000013, // $0.13 per 1M tokens
    };

    final pricePerToken = pricing[model] ?? pricing['text-embedding-ada-002']!;
    return tokens * pricePerToken;
  }

  /// Update daily costs tracking
  Map<String, double> _updateDailyCosts(
    Map<String, double> currentCosts,
    double additionalCost,
  ) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final updatedCosts = Map<String, double>.from(currentCosts);
    updatedCosts[today] = (updatedCosts[today] ?? 0.0) + additionalCost;
    return updatedCosts;
  }

  /// Check rate limits for API calls
  Future<bool> _checkRateLimit(String requestType) async {
    await _cleanOldRequestTimes();

    if (requestType == 'chat') {
      if (_chatRequestTimes.length >= AIConfig.maxDailyChatRequests) {
        return false;
      }
      _chatRequestTimes.add(DateTime.now());
    }

    return true;
  }

  /// Record chat usage for tracking
  Future<void> _recordChatUsage(
    String model,
    int promptTokens,
    int completionTokens,
  ) async {
    final cost = _calculateChatCost(model, promptTokens, completionTokens);

    _currentStats = APIUsageStats(
      chatCompletions: _currentStats.chatCompletions + 1,
      embeddings: _currentStats.embeddings,
      totalTokensUsed:
          _currentStats.totalTokensUsed + promptTokens + completionTokens,
      promptTokens: _currentStats.promptTokens + promptTokens,
      completionTokens: _currentStats.completionTokens + completionTokens,
      estimatedCost: _currentStats.estimatedCost + cost,
      lastReset: _currentStats.lastReset,
      modelUsage: {
        ..._currentStats.modelUsage,
        model: (_currentStats.modelUsage[model] ?? 0) + 1,
      },
      dailyCosts: _updateDailyCosts(_currentStats.dailyCosts, cost),
    );

    await _saveUsageStats();
    await _checkBudgetStatus();
  }

  /// Check if budget has been exceeded
  Future<void> _checkBudgetStatus() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayCost = _currentStats.dailyCosts[today] ?? 0.0;

    if (todayCost >= AIConfig.maxDailyBudget) {
      _budgetExceeded = true;
      _budgetExceededMessage =
          'Daily budget of \$${AIConfig.maxDailyBudget.toStringAsFixed(2)} exceeded. Current: \$${todayCost.toStringAsFixed(4)}';
    }
  }

  /// Load usage stats from persistent storage
  Future<void> _loadUsageStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString('openai_usage_stats');
    if (statsJson != null) {
      try {
        final statsData = jsonDecode(statsJson);
        _currentStats = APIUsageStats.fromJson(statsData);

        // Reset stats if it's a new day
        final lastReset = _currentStats.lastReset;
        final now = DateTime.now();
        if (now.difference(lastReset).inDays >= 1) {
          await resetDailyStats();
        }
      } catch (e) {
        Logger.d('Error loading usage stats: $e');
        _currentStats = APIUsageStats.empty();
      }
    }
  }

  /// Save usage stats to persistent storage
  Future<void> _saveUsageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = jsonEncode(_currentStats.toJson());
      await prefs.setString('openai_usage_stats', statsJson);
    } catch (e) {
      Logger.d('Error saving usage stats: $e');
    }
  }

  /// Reset daily statistics
  Future<void> resetDailyStats() async {
    _currentStats = APIUsageStats.empty();
    _budgetExceeded = false;
    _budgetExceededMessage = null;
    _chatRequestTimes.clear();
    _embeddingRequestTimes.clear();
    await _saveUsageStats();
  }

  /// Get current usage statistics
  APIUsageStats getUsageStats() => _currentStats;

  /// Get detailed usage report
  Map<String, dynamic> getDetailedUsageReport() {
    final cacheStats = _optimizer.getCacheStats();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayCost = _currentStats.dailyCosts[today] ?? 0.0;

    return {
      'current_stats': _currentStats.toJson(),
      'cache_performance': cacheStats,
      'budget_status': {
        'daily_budget': AIConfig.maxDailyBudget,
        'today_cost': todayCost,
        'budget_exceeded': _budgetExceeded,
        'remaining_budget': max(0, AIConfig.maxDailyBudget - todayCost),
        'budget_utilization': todayCost / AIConfig.maxDailyBudget,
      },
      'rate_limits': {
        'chat_requests_today': _chatRequestTimes.length,
        'embedding_requests_today': _embeddingRequestTimes.length,
        'max_chat_requests': AIConfig.maxDailyChatRequests,
        'max_embedding_requests': AIConfig.maxDailyEmbeddingRequests,
      },
      'optimization_insights': _getOptimizationInsights(),
    };
  }

  /// Get optimization insights and recommendations
  Map<String, dynamic> _getOptimizationInsights() {
    final insights = <String, dynamic>{
      'recommendations': <String>[],
      'potential_savings': 0.0,
    };

    final cacheStats = _optimizer.getCacheStats();
    final hitRate = cacheStats['hit_rate'] as double;

    if (hitRate < 0.5) {
      insights['recommendations'].add(
        'Consider increasing cache size or retention period for better cost efficiency',
      );
    }

    // Analyze model usage patterns
    final gpt4Usage = _currentStats.modelUsage['gpt-4'] ?? 0;
    final gpt35Usage = _currentStats.modelUsage['gpt-3.5-turbo'] ?? 0;
    final totalUsage = gpt4Usage + gpt35Usage;

    if (totalUsage > 0 && gpt4Usage / totalUsage > 0.8) {
      insights['recommendations'].add(
        'Consider using GPT-3.5-turbo for simpler queries to reduce costs',
      );
      insights['potential_savings'] =
          _currentStats.estimatedCost * 0.3; // Rough estimate
    }

    return insights;
  }

  /// Clear all caches and reset optimization data
  Future<void> clearCache() async {
    _optimizer.clearCache();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('openai_usage_stats');
  }

  /// Get budget and usage warnings
  List<String> getBudgetWarnings() {
    final warnings = <String>[];
    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayCost = _currentStats.dailyCosts[today] ?? 0.0;

    if (todayCost >= AIConfig.maxDailyBudget * 0.8) {
      warnings.add(
        'Approaching daily budget limit (${((todayCost / AIConfig.maxDailyBudget) * 100).toInt()}% used)',
      );
    }

    if (_chatRequestTimes.length >= AIConfig.maxDailyChatRequests * 0.8) {
      warnings.add(
        'Approaching daily chat request limit (${_chatRequestTimes.length}/${AIConfig.maxDailyChatRequests})',
      );
    }

    if (_embeddingRequestTimes.length >=
        AIConfig.maxDailyEmbeddingRequests * 0.8) {
      warnings.add(
        'Approaching daily embedding request limit (${_embeddingRequestTimes.length}/${AIConfig.maxDailyEmbeddingRequests})',
      );
    }

    return warnings;
  }

  /// Analyze image with OpenAI Vision API
  Future<String?> analyzeImageWithPrompt(
    String base64Image,
    String prompt,
  ) async {
    if (_budgetExceeded) {
      throw Exception(_budgetExceededMessage ?? 'Budget exceeded');
    }

    if (!await _checkRateLimit('chat')) {
      throw Exception(
        'Chat request rate limit exceeded. Please try again later.',
      );
    }

    try {
      developer.log('Sending image analysis request to OpenAI Vision API');

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${AIConfig.openaiApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': base64Image,
                    'detail': 'high',
                  },
                },
              ],
            },
          ],
          'max_tokens': 1000,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final chatResponse = ChatCompletionResponse.fromJson(responseData);

        await _recordChatUsage(
          'gpt-4o',
          chatResponse.promptTokens,
          chatResponse.completionTokens,
        );

        developer.log('OpenAI Vision analysis completed successfully');
        return chatResponse.content;
      } else {
        final errorData = jsonDecode(response.body);
        developer.log(
          'OpenAI Vision API error: ${response.statusCode} - ${errorData['error']['message']}',
        );
        throw Exception(
          'OpenAI Vision API error: ${errorData['error']['message']}',
        );
      }
    } catch (e) {
      developer.log('Error in OpenAI Vision analysis: $e');
      rethrow;
    }
  }

  /// Export usage data for analysis
  Map<String, dynamic> exportUsageData() {
    return {
      'export_timestamp': DateTime.now().toIso8601String(),
      'usage_stats': _currentStats.toJson(),
      'cache_stats': _optimizer.getCacheStats(),
      'detailed_report': getDetailedUsageReport(),
    };
  }
}
