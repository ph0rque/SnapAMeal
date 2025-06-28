import 'package:flutter_test/flutter_test.dart';
import 'package:snapameal/services/demo_data_validator.dart';

void main() {
  group('DemoDataValidator Tests', () {
    test('DemoDataValidator.validateAll completes', () async {
      // validateAll is a static method, so we call it directly
      final results = await DemoDataValidator.validateAll();
      expect(results, isNotEmpty);
    }, skip: 'Requires Firebase');

    test('DemoDataValidator is a static utility class', () {
      // Since DemoDataValidator uses static methods, we test that the class exists
      // and has the expected static method
      expect(DemoDataValidator.validateAll, isA<Function>());
    });
  });
} 