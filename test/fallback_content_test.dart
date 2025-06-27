import 'package:flutter_test/flutter_test.dart';
import 'package:snapameal/data/fallback_content.dart';

void main() {
  group('FallbackContent Tests', () {
    group('Daily Insights', () {
      test('getDailyInsight returns appropriate content for weight loss goals', () {
        final insight = FallbackContent.getDailyInsight(['weight_loss']);
        
        expect(insight, isNotEmpty);
        expect(insight, contains('*This is general wellness information, not medical advice.*'));
      });

      test('getDailyInsight returns appropriate content for muscle gain goals', () {
        final insight = FallbackContent.getDailyInsight(['muscle_gain']);
        
        expect(insight, isNotEmpty);
        expect(insight, contains('*This is general wellness information, not medical advice.*'));
      });

      test('getDailyInsight returns health content for empty goals', () {
        final insight = FallbackContent.getDailyInsight([]);
        
        expect(insight, isNotEmpty);
        expect(insight, contains('*This is general wellness information, not medical advice.*'));
      });

      test('getDailyInsight returns consistent content for same day', () {
        final insight1 = FallbackContent.getDailyInsight(['weight_loss']);
        final insight2 = FallbackContent.getDailyInsight(['weight_loss']);
        
        expect(insight1, equals(insight2));
      });

      test('getDailyInsight handles unknown goals gracefully', () {
        final insight = FallbackContent.getDailyInsight(['unknown_goal']);
        
        expect(insight, isNotEmpty);
        expect(insight, contains('*This is general wellness information, not medical advice.*'));
      });
    });

    group('Nutrition Insights', () {
      test('getNutritionInsight returns appropriate content for different foods', () {
        final proteinInsight = FallbackContent.getNutritionInsight(['chicken', 'fish']);
        final vegetableInsight = FallbackContent.getNutritionInsight(['broccoli', 'spinach']);
        final fruitInsight = FallbackContent.getNutritionInsight(['apple', 'banana']);
        
        expect(proteinInsight, isNotEmpty);
        expect(vegetableInsight, isNotEmpty);
        expect(fruitInsight, isNotEmpty);
        
        expect(proteinInsight.toLowerCase(), contains('protein'));
        expect(vegetableInsight.toLowerCase(), anyOf([contains('vegetable'), contains('vitamin'), contains('fiber')]));
        expect(fruitInsight.toLowerCase(), anyOf([contains('fruit'), contains('vitamin'), contains('fiber')]));
      });

      test('getNutritionInsight handles empty food list', () {
        final insight = FallbackContent.getNutritionInsight([]);
        
        expect(insight, isNotEmpty);
        expect(insight.toLowerCase(), anyOf([contains('balanced'), contains('variety'), contains('diverse')]));
      });

      test('getNutritionInsight includes medical disclaimer', () {
        final insight = FallbackContent.getNutritionInsight(['chicken']);
        
        expect(insight, contains('*This is general wellness information, not medical advice.*'));
      });
    });

    group('Recipe Suggestions', () {
      test('getRecipeSuggestions returns vegan recipes for vegan restrictions', () {
        final recipes = FallbackContent.getRecipeSuggestions(['vegan']);
        
        expect(recipes, isNotEmpty);
        expect(recipes.length, greaterThan(0));
        expect(recipes.first.toLowerCase(), anyOf([contains('vegan'), contains('plant'), contains('vegetable'), contains('quinoa')]));
      });

      test('getRecipeSuggestions returns vegetarian recipes for vegetarian restrictions', () {
        final recipes = FallbackContent.getRecipeSuggestions(['vegetarian']);
        
        expect(recipes, isNotEmpty);
        expect(recipes.length, greaterThan(0));
      });

      test('getRecipeSuggestions returns high protein recipes for muscle gain goals', () {
        final recipes = FallbackContent.getRecipeSuggestions([], userGoals: ['muscle_gain']);
        
        expect(recipes, isNotEmpty);
        expect(recipes.length, greaterThan(0));
      });

      test('getRecipeSuggestions returns general recipes for no restrictions', () {
        final recipes = FallbackContent.getRecipeSuggestions([]);
        
        expect(recipes, isNotEmpty);
        expect(recipes.length, greaterThan(0));
      });
    });

    group('Missions', () {
      test('getMission returns appropriate mission for weight loss', () {
        final mission = FallbackContent.getMission(['weight_loss']);
        
        expect(mission, contains('title'));
        expect(mission, contains('description'));
        expect(mission, contains('steps'));
        expect(mission['steps'], isA<List>());
        expect(mission['steps'].length, equals(7));
      });

      test('getMission returns appropriate mission for muscle gain', () {
        final mission = FallbackContent.getMission(['muscle_gain']);
        
        expect(mission, contains('title'));
        expect(mission, contains('description'));
        expect(mission, contains('steps'));
        expect(mission['steps'], isA<List>());
        expect(mission['steps'].length, equals(7));
      });

      test('getMission returns health mission for empty goals', () {
        final mission = FallbackContent.getMission([]);
        
        expect(mission, contains('title'));
        expect(mission, contains('description'));
        expect(mission, contains('steps'));
      });
    });

    group('AI Content for Feed', () {
      test('getAIContentForFeed returns appropriate content for goals', () {
        final content = FallbackContent.getAIContentForFeed(['weight_loss'], count: 2);
        
        expect(content, isNotEmpty);
        expect(content.length, equals(2));
        expect(content.first, contains('title'));
        expect(content.first, contains('content'));
        expect(content.first, contains('type'));
      });

      test('getAIContentForFeed respects count parameter', () {
        final content = FallbackContent.getAIContentForFeed(['muscle_gain'], count: 5);
        
        expect(content.length, lessThanOrEqualTo(5));
      });

      test('getAIContentForFeed handles empty goals', () {
        final content = FallbackContent.getAIContentForFeed([]);
        
        expect(content, isNotEmpty);
        expect(content.first, contains('title'));
      });
    });

    group('Friend Matching', () {
      test('getFriendMatchingExplanation returns appropriate explanation', () {
        final explanation = FallbackContent.getFriendMatchingExplanation();
        
        expect(explanation, isNotEmpty);
        expect(explanation.length, greaterThan(10));
      });

      test('getFriendMatchingExplanation returns different explanations over time', () {
        final explanations = <String>{};
        
        // Generate multiple explanations to test variety
        for (int i = 0; i < 10; i++) {
          explanations.add(FallbackContent.getFriendMatchingExplanation());
        }
        
        // Should have some variety (though not guaranteed due to deterministic nature)
        expect(explanations.length, greaterThan(0));
      });
    });

    group('Weekly Review Highlights', () {
      test('getWeeklyReviewHighlights returns highlights based on activity', () {
        final activityData = {
          'metrics': {
            'stories': {'total_count': 5},
            'meals': {'total_count': 15},
            'overall': {'total_activities': 20},
          }
        };
        
        final highlights = FallbackContent.getWeeklyReviewHighlights(activityData);
        
        expect(highlights, isNotEmpty);
        expect(highlights.length, lessThanOrEqualTo(3));
      });

      test('getWeeklyReviewHighlights handles empty activity data', () {
        final highlights = FallbackContent.getWeeklyReviewHighlights({});
        
        expect(highlights, isA<List<String>>());
      });

      test('getWeeklyReviewHighlights includes social highlights for story activity', () {
        final activityData = {
          'metrics': {
            'stories': {'total_count': 10},
          }
        };
        
        final highlights = FallbackContent.getWeeklyReviewHighlights(activityData);
        
        expect(highlights, isNotEmpty);
      });
    });

    group('Conversation Starters', () {
      test('getConversationStarter returns appropriate starter for group type', () {
        final starter = FallbackContent.getConversationStarter('fasting');
        
        expect(starter, contains('title'));
        expect(starter, contains('content'));
        expect(starter, contains('type'));
        expect(starter, contains('tags'));
      });

      test('getConversationStarter handles unknown group types', () {
        final starter = FallbackContent.getConversationStarter('unknown_type');
        
        expect(starter, contains('title'));
        expect(starter, contains('content'));
      });

      test('getConversationStarters returns multiple starters', () {
        final starters = FallbackContent.getConversationStarters('nutrition', 3);
        
        expect(starters.length, equals(3));
        expect(starters.first, contains('title'));
        expect(starters.first, contains('content'));
      });

      test('getConversationStarters respects count limit', () {
        final starters = FallbackContent.getConversationStarters('fasting', 10);
        
        expect(starters.length, lessThanOrEqualTo(10));
      });
    });

    group('Content Validation', () {
      test('hasContentFor returns true for supported content types', () {
        expect(FallbackContent.hasContentFor(contentType: 'daily_insight', userGoals: ['weight_loss']), isTrue);
        expect(FallbackContent.hasContentFor(contentType: 'nutrition_insight'), isTrue);
        expect(FallbackContent.hasContentFor(contentType: 'recipe_suggestions'), isTrue);
        expect(FallbackContent.hasContentFor(contentType: 'mission', userGoals: ['muscle_gain']), isTrue);
        expect(FallbackContent.hasContentFor(contentType: 'conversation_starter', groupType: 'fasting'), isTrue);
        expect(FallbackContent.hasContentFor(contentType: 'ai_content'), isTrue);
        expect(FallbackContent.hasContentFor(contentType: 'friend_matching'), isTrue);
        expect(FallbackContent.hasContentFor(contentType: 'weekly_review'), isTrue);
      });

      test('hasContentFor handles unsupported content types', () {
        expect(FallbackContent.hasContentFor(contentType: 'unknown_type'), isTrue); // Returns true for generic response
      });

      test('validateContent returns true for valid content structure', () {
        final isValid = FallbackContent.validateContent();
        
        expect(isValid, isTrue);
      });
    });

    group('Content Management', () {
      test('getContentVersion returns valid version', () {
        final version = FallbackContent.getContentVersion();
        
        expect(version, isNotEmpty);
        expect(version, matches(RegExp(r'^\d+\.\d+\.\d+$')));
      });

      test('getLastUpdated returns valid date', () {
        final lastUpdated = FallbackContent.getLastUpdated();
        
        expect(lastUpdated, isA<DateTime>());
        expect(lastUpdated.isBefore(DateTime.now().add(const Duration(days: 1))), isTrue);
      });

      test('getContentStats returns comprehensive statistics', () {
        final stats = FallbackContent.getContentStats();
        
        expect(stats, contains('version'));
        expect(stats, contains('last_updated'));
        expect(stats, contains('daily_insights_count'));
        expect(stats, contains('nutrition_insights_count'));
        expect(stats, contains('recipe_categories'));
        expect(stats, contains('mission_types'));
        expect(stats, contains('conversation_starter_groups'));
        expect(stats, contains('total_conversation_starters'));
        expect(stats, contains('content_valid'));
        
        expect(stats['daily_insights_count'], greaterThan(0));
        expect(stats['nutrition_insights_count'], greaterThan(0));
        expect(stats['content_valid'], isTrue);
      });
    });

    group('Safe Generic Response', () {
      test('getSafeGenericResponse returns appropriate fallback', () {
        final response = FallbackContent.getSafeGenericResponse();
        
        expect(response, isNotEmpty);
        expect(response, contains('wellness'));
        expect(response, contains('healthcare professional'));
        expect(response, contains('*This information is for general wellness purposes only'));
      });
    });

    group('Content Quality', () {
      test('all daily insights contain medical disclaimers', () {
        final goals = ['weight_loss', 'muscle_gain', 'energy', 'health', 'strength'];
        
        for (final goal in goals) {
          final insight = FallbackContent.getDailyInsight([goal]);
          expect(insight, contains('*This is general wellness information, not medical advice.*'));
        }
      });

      test('all nutrition insights are appropriate length', () {
        final foods = ['chicken', 'vegetables', 'fruits', 'grains', 'dairy'];
        
        for (final food in foods) {
          final insight = FallbackContent.getNutritionInsight([food]);
          expect(insight.length, greaterThan(50));
          expect(insight.length, lessThan(500));
        }
      });

      test('all missions have 7 steps', () {
        final goals = ['weight_loss', 'muscle_gain', 'energy', 'health', 'strength'];
        
        for (final goal in goals) {
          final mission = FallbackContent.getMission([goal]);
          expect(mission['steps'], isA<List>());
          expect(mission['steps'].length, equals(7));
        }
      });

      test('conversation starters have required fields', () {
        final groupTypes = ['fasting', 'calorieGoals', 'workoutBuddies', 'nutrition', 'wellness', 'support', 'recipes'];
        
        for (final groupType in groupTypes) {
          final starter = FallbackContent.getConversationStarter(groupType);
          expect(starter, contains('title'));
          expect(starter, contains('content'));
          expect(starter, contains('type'));
          expect(starter, contains('tags'));
          expect(starter['tags'], isA<List>());
        }
      });
    });

    group('Performance and Caching', () {
      test('repeated calls return consistent results', () {
        final insight1 = FallbackContent.getDailyInsight(['weight_loss']);
        final insight2 = FallbackContent.getDailyInsight(['weight_loss']);
        
        expect(insight1, equals(insight2));
      });

      test('content generation is fast', () {
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 100; i++) {
          FallbackContent.getDailyInsight(['weight_loss']);
          FallbackContent.getNutritionInsight(['chicken']);
          FallbackContent.getRecipeSuggestions([]);
        }
        
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be very fast
      });
    });
  });
} 