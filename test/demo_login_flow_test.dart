import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:snapameal/services/auth_service.dart';
import 'package:snapameal/config/demo_personas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Demo Login Flow (unit)', () {
    setUpAll(() async {
      await Firebase.initializeApp();
    });

    for (final persona in DemoPersonas.all) {
      test('Login as ${persona.id} succeeds', () async {
        final authService = AuthService();
        final cred = await authService.signInWithDemoAccount(persona.id);
        expect(cred.user, isNotNull);
        expect(cred.user!.email, persona.email);
      }, skip: 'Requires Firebase configuration');
    }
  }, skip: 'Requires Firebase configuration');
} 