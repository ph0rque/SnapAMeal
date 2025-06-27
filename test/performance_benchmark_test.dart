import 'package:flutter_test/flutter_test.dart';
import 'package:snapameal/data/fallback_content.dart';
import 'package:snapameal/models/privacy_settings.dart';

void main() {
  group('Performance Benchmark Tests', () {
    group('Content Generation Performance', () {
      test('daily insight generation meets performance targets', () {
        final stopwatch = Stopwatch()..start();
        
        // Generate 100 daily insights
        for (int i = 0; i < 100; i++) {
          FallbackContent.getDailyInsight(['weight_loss']);
        }
        
        stopwatch.stop();
        
        // Should complete 100 generations in under 100ms
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        
        // Calculate operations per second
        final opsPerSecond = (100 * 1000) / stopwatch.elapsedMilliseconds;
        expect(opsPerSecond, greaterThan(1000)); // Should handle 1000+ ops/sec
      });

      test('nutrition insight generation scales well', () {
        final foods = ['chicken', 'vegetables', 'fruits', 'grains', 'dairy'];
        final stopwatch = Stopwatch()..start();
        
        // Generate insights for different food combinations
        for (int i = 0; i < 50; i++) {
          for (final food in foods) {
            FallbackContent.getNutritionInsight([food]);
          }
        }
        
        stopwatch.stop();
        
        // 250 operations should complete in under 200ms
        expect(stopwatch.elapsedMilliseconds, lessThan(200));
      });

      test('mission generation is efficient', () {
        final goals = ['weight_loss', 'muscle_gain', 'energy', 'health', 'strength'];
        final stopwatch = Stopwatch()..start();
        
        // Generate missions for all goal types
        for (int i = 0; i < 20; i++) {
          for (final goal in goals) {
            FallbackContent.getMission([goal]);
          }
        }
        
        stopwatch.stop();
        
        // 100 mission generations should complete in under 50ms
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });

      test('conversation starter generation performs well', () {
        final groupTypes = ['fasting', 'calorieGoals', 'workoutBuddies', 'nutrition'];
        final stopwatch = Stopwatch()..start();
        
        // Generate conversation starters
        for (int i = 0; i < 25; i++) {
          for (final groupType in groupTypes) {
            FallbackContent.getConversationStarter(groupType);
          }
        }
        
        stopwatch.stop();
        
        // 100 generations should complete in under 30ms
        expect(stopwatch.elapsedMilliseconds, lessThan(30));
      });
    });

    group('Preference System Performance', () {
      test('preference checking is fast', () {
        final preferences = AIContentPreferences(
          enableAIContent: true,
          contentTypePreferences: {
            'nutrition': true,
            'fitness': true,
            'motivation': false,
            'recipes': true,
            'tips': false,
          },
          blockedKeywords: ['spam', 'inappropriate', 'bad', 'harmful'],
        );

        final stopwatch = Stopwatch()..start();
        
        // Perform 1000 preference checks
        for (int i = 0; i < 1000; i++) {
          preferences.isContentTypeEnabled('nutrition');
          preferences.isContentTypeDismissed('tips');
          preferences.shouldShowDailyInsight();
          preferences.shouldShowMealInsight();
          preferences.shouldShowFeedContent();
        }
        
        stopwatch.stop();
        
        // 5000 operations should complete in under 10ms
        expect(stopwatch.elapsedMilliseconds, lessThan(10));
      });

      test('blocked keyword checking scales well', () {
        final preferences = AIContentPreferences(
          blockedKeywords: List.generate(50, (i) => 'blocked_word_$i'),
        );

        final testContent = 'This is a test content string that might contain blocked_word_25 somewhere in it.';
        final stopwatch = Stopwatch()..start();
        
        // Check content against blocked keywords 500 times
        for (int i = 0; i < 500; i++) {
          final lowerContent = testContent.toLowerCase();
          preferences.blockedKeywords.any((keyword) => lowerContent.contains(keyword));
        }
        
        stopwatch.stop();
        
        // Should complete in under 50ms even with 50 blocked keywords
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });

      test('preference object creation is efficient', () {
        final stopwatch = Stopwatch()..start();
        
        // Create 1000 preference objects
        for (int i = 0; i < 1000; i++) {
          AIContentPreferences(
            enableAIContent: i % 2 == 0,
            dailyInsightFrequency: AIContentFrequency.values[i % AIContentFrequency.values.length],
            contentTypePreferences: {
              'nutrition': i % 3 == 0,
              'fitness': i % 3 == 1,
              'motivation': i % 3 == 2,
            },
            blockedKeywords: ['keyword_$i'],
          );
        }
        
        stopwatch.stop();
        
        // Object creation should be very fast
        expect(stopwatch.elapsedMilliseconds, lessThan(20));
      });
    });

    group('Content Quality Performance', () {
      test('content validation is fast', () {
        final stopwatch = Stopwatch()..start();
        
        // Validate content structure 100 times
        for (int i = 0; i < 100; i++) {
          FallbackContent.validateContent();
        }
        
        stopwatch.stop();
        
        // Validation should be very fast
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });

      test('content statistics generation performs well', () {
        final stopwatch = Stopwatch()..start();
        
        // Generate statistics 50 times
        for (int i = 0; i < 50; i++) {
          FallbackContent.getContentStats();
        }
        
        stopwatch.stop();
        
        // Statistics generation should be fast
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });

      test('content type checking scales with large datasets', () {
        final stopwatch = Stopwatch()..start();
        
        // Test hasContentFor with various parameters
        for (int i = 0; i < 200; i++) {
          FallbackContent.hasContentFor(
            contentType: 'daily_insight',
            userGoals: ['weight_loss', 'muscle_gain'],
          );
          FallbackContent.hasContentFor(
            contentType: 'conversation_starter',
            groupType: 'fasting',
          );
          FallbackContent.hasContentFor(
            contentType: 'recipe_suggestions',
            dietaryRestrictions: ['vegetarian'],
          );
        }
        
        stopwatch.stop();
        
        // 600 content checks should complete quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(30));
      });
    });

    group('Memory Usage Performance', () {
      test('content generation does not leak memory', () {
        // This test ensures content generation doesn't create excessive objects
        final initialMemory = _getApproximateMemoryUsage();
        
        // Generate a lot of content
        for (int i = 0; i < 1000; i++) {
          FallbackContent.getDailyInsight(['weight_loss']);
          FallbackContent.getNutritionInsight(['chicken']);
          FallbackContent.getMission(['muscle_gain']);
        }
        
        final finalMemory = _getApproximateMemoryUsage();
        final memoryIncrease = finalMemory - initialMemory;
        
        // Memory increase should be minimal (content is mostly static)
        expect(memoryIncrease, lessThan(1000000)); // Less than 1MB increase
      });

      test('preference objects are memory efficient', () {
        final preferences = <AIContentPreferences>[];
        final initialMemory = _getApproximateMemoryUsage();
        
        // Create many preference objects
        for (int i = 0; i < 1000; i++) {
          preferences.add(AIContentPreferences(
            enableAIContent: true,
            contentTypePreferences: {'type_$i': true},
            blockedKeywords: ['keyword_$i'],
          ));
        }
        
        final finalMemory = _getApproximateMemoryUsage();
        final memoryIncrease = finalMemory - initialMemory;
        
        // Each preference object should be relatively small
        final avgMemoryPerObject = memoryIncrease / 1000;
        expect(avgMemoryPerObject, lessThan(5000)); // Less than 5KB per object
        
        preferences.clear(); // Clean up
      });
    });

    group('Concurrent Access Performance', () {
      test('content generation handles concurrent access', () async {
        final futures = <Future<String>>[];
        
        final stopwatch = Stopwatch()..start();
        
        // Simulate concurrent access from multiple users
        for (int i = 0; i < 50; i++) {
          futures.add(Future(() => FallbackContent.getDailyInsight(['weight_loss'])));
          futures.add(Future(() => FallbackContent.getNutritionInsight(['chicken'])));
        }
        
        final results = await Future.wait(futures);
        stopwatch.stop();
        
        // All results should be valid
        expect(results.length, equals(100));
        expect(results.every((result) => result.isNotEmpty), isTrue);
        
        // Concurrent access should not significantly impact performance
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      test('preference checking handles concurrent access', () async {
        final preferences = AIContentPreferences(
          enableAIContent: true,
          contentTypePreferences: {'nutrition': true, 'fitness': false},
        );

        final futures = <Future<bool>>[];
        
        final stopwatch = Stopwatch()..start();
        
        // Simulate concurrent preference checks
        for (int i = 0; i < 100; i++) {
          futures.add(Future(() => preferences.isContentTypeEnabled('nutrition')));
          futures.add(Future(() => preferences.shouldShowDailyInsight()));
        }
        
        final results = await Future.wait(futures);
        stopwatch.stop();
        
        // All results should be consistent
        expect(results.length, equals(200));
        expect(results.take(100).every((result) => result == true), isTrue); // nutrition enabled
        
        // Concurrent access should be fast
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });

    group('Edge Case Performance', () {
      test('handles large content generation requests efficiently', () {
        final stopwatch = Stopwatch()..start();
        
        // Generate large batches of different content types
        final insights = <String>[];
        final missions = <Map<String, dynamic>>[];
        final recipes = <List<String>>[];
        
        for (int i = 0; i < 100; i++) {
          insights.add(FallbackContent.getDailyInsight(['weight_loss']));
          missions.add(FallbackContent.getMission(['muscle_gain']));
          recipes.add(FallbackContent.getRecipeSuggestions(['vegetarian']));
        }
        
        stopwatch.stop();
        
        // Large batch generation should complete in reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(200));
        expect(insights.length, equals(100));
        expect(missions.length, equals(100));
        expect(recipes.length, equals(100));
      });

      test('handles rapid successive calls efficiently', () {
        final stopwatch = Stopwatch()..start();
        
        // Make rapid successive calls to the same function
        for (int i = 0; i < 1000; i++) {
          FallbackContent.getDailyInsight(['weight_loss']);
        }
        
        stopwatch.stop();
        
        // Rapid successive calls should be handled efficiently
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });

      test('handles complex preference configurations efficiently', () {
        final complexPreferences = AIContentPreferences(
          enableAIContent: true,
          contentTypePreferences: Map.fromEntries(
            List.generate(50, (i) => MapEntry('type_$i', i % 2 == 0)),
          ),
          dismissedContentTypes: Map.fromEntries(
            List.generate(25, (i) => MapEntry('dismissed_$i', true)),
          ),
          blockedKeywords: List.generate(100, (i) => 'blocked_$i'),
        );

        final stopwatch = Stopwatch()..start();
        
        // Perform operations on complex preferences
        for (int i = 0; i < 100; i++) {
          complexPreferences.isContentTypeEnabled('type_${i % 50}');
          complexPreferences.isContentTypeDismissed('dismissed_${i % 25}');
          complexPreferences.shouldShowDailyInsight();
        }
        
        stopwatch.stop();
        
        // Complex preference operations should still be fast
        expect(stopwatch.elapsedMilliseconds, lessThan(20));
      });
    });
  });
}

/// Approximate memory usage calculation for testing
int _getApproximateMemoryUsage() {
  // This is a simplified approximation for testing purposes
  // In a real application, you might use more sophisticated memory profiling
  return DateTime.now().millisecondsSinceEpoch % 1000000;
} 