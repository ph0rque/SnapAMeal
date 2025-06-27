import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:snapameal/services/auth_service.dart';
import 'package:snapameal/config/demo_personas.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Demo Login Flow', () {
    final authService = AuthService();

    setUpAll(() async {
      await Firebase.initializeApp();
    });

    for (final persona in DemoPersonas.all) {
      testWidgets('Login as \\`${persona.id}\\` succeeds', (tester) async {
        final cred = await authService.signInWithDemoAccount(persona.id);
        expect(cred.user, isNotNull);
        expect(cred.user!.email, persona.email);
      });
    }
  });
} 