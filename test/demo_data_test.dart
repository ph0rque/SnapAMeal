import 'package:flutter_test/flutter_test.dart';
import 'package:snapameal/config/demo_personas.dart';

void main() {
  group('Demo Data Tests', () {
    test('Demo personas should be valid', () {
      final alice = DemoPersonas.getById('alice');
      final bob = DemoPersonas.getById('bob');
      final charlie = DemoPersonas.getById('charlie');

      expect(alice, isNotNull);
      expect(bob, isNotNull);
      expect(charlie, isNotNull);

          expect(alice!.email, 'alice.demo@example.com');
    expect(bob!.email, 'bob.demo@example.com');
    expect(charlie!.email, 'charlie.demo@example.com');

      // Test health profiles exist
      expect(alice.healthProfile['goals'], isNotNull);
      expect(bob.healthProfile['goals'], isNotNull);
      expect(charlie.healthProfile['goals'], isNotNull);

      // Test fasting types are set
      expect(alice.healthProfile['fastingType'], isNotNull);
      expect(bob.healthProfile['fastingType'], isNotNull);
      expect(charlie.healthProfile['fastingType'], isNotNull);
    });

    test('Demo personas should have unique IDs', () {
      final personas = DemoPersonas.all;
      final ids = personas.map((p) => p.id).toSet();
      
      expect(ids.length, equals(personas.length));
    });

    test('Demo personas should have valid email formats', () {
      final personas = DemoPersonas.all;
      
      for (final persona in personas) {
        expect(persona.email, contains('@'));
        expect(persona.email, contains('demo'));
        expect(persona.email, contains('example.com'));
      }
    });

    test('Demo personas should have required health profile fields', () {
      final personas = DemoPersonas.all;
      
      for (final persona in personas) {
        final profile = persona.healthProfile;
        
        expect(profile['age'], isNull); // age is not in healthProfile, it's a direct field
        expect(profile['gender'], isNotNull);
        expect(profile['height'], isNotNull);
        expect(profile['weight'], isNotNull);
        expect(profile['goals'], isNotNull);
        expect(profile['fastingType'], isNotNull);
        expect(profile['activityLevel'], isNotNull);
        
        // Test direct fields
        expect(persona.age, greaterThan(0));
        expect(persona.id, isNotEmpty);
        expect(persona.displayName, isNotEmpty);
      }
    });

    test('Demo personas should have different characteristics', () {
      final alice = DemoPersonas.alice;
      final bob = DemoPersonas.bob;
      final charlie = DemoPersonas.charlie;
      
      // Different fasting types
      expect(alice.healthProfile['fastingType'], equals('14:10'));
      expect(bob.healthProfile['fastingType'], equals('16:8'));
      expect(charlie.healthProfile['fastingType'], equals('5:2'));
      
      // Different ages
      expect(alice.age, isNot(equals(bob.age)));
      expect(bob.age, isNot(equals(charlie.age)));
      expect(alice.age, isNot(equals(charlie.age)));
      
      // Different goals
      expect(alice.healthProfile['goals'], contains('weight_loss'));
      expect(bob.healthProfile['goals'], contains('muscle_gain'));
      expect(charlie.healthProfile['goals'], contains('health'));
    });
  });
} 