import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_it/get_it.dart';
import 'package:snapameal/services/auth_service.dart';
import 'package:snapameal/config/demo_personas.dart';
import 'test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Demo Login Flow (integration)', () {
    setUpAll(() async {
      await Firebase.initializeApp();
      setupRealTestServiceLocator(); // Use real services for integration tests
    });

    tearDownAll(() {
      tearDownTestServiceLocator();
    });

    test('AuthService can be retrieved from DI', () {
      final authService = GetIt.instance<AuthService>();
      expect(authService, isNotNull);
      expect(authService, isA<AuthService>());
    });

    for (final persona in DemoPersonas.all) {
      test('Login as ${persona.id} succeeds', () async {
        final authService = GetIt.instance<AuthService>();
        final cred = await authService.signInWithDemoAccount(persona.id);
        expect(cred.user, isNotNull);
        expect(cred.user!.email, persona.email);
      }, skip: 'Requires Firebase configuration');
    }
  }, skip: 'Requires Firebase configuration');
} 