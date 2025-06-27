import 'package:flutter_test/flutter_test.dart';
import 'package:snapameal/services/demo_data_validator.dart';

void main() {
  test('DemoDataValidator.validateAll completes', () async {
    final results = await DemoDataValidator.validateAll();
    expect(results, isNotEmpty);
  }, skip: 'Requires Firebase');
} 