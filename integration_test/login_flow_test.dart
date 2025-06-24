import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:snapameal/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> login(
      WidgetTester tester, String email, String password) async {
    // Find the email and password fields.
    final emailField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == 'Email',
    );
    final passwordField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == 'Password',
    );
    final loginButton = find.widgetWithText(GestureDetector, 'Login');

    expect(emailField, findsOneWidget);
    expect(passwordField, findsOneWidget);
    expect(loginButton, findsOneWidget);

    // Enter credentials.
    await tester.enterText(emailField, email);
    await tester.enterText(passwordField, password);
    await tester.pumpAndSettle();

    // Tap the login button.
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    // Verify successful login by checking for the HomePage title.
    expect(find.text('SnapAMeal'), findsOneWidget);
  }

  Future<void> logout(WidgetTester tester) async {
    // Find and tap the logout button.
    final logoutButton = find.byIcon(Icons.logout);
    expect(logoutButton, findsOneWidget);
    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    // Verify successful logout by checking for the login page elements.
    expect(find.widgetWithText(GestureDetector, 'Login'), findsOneWidget);
  }

  testWidgets('Login and logout flow for two users',
      (WidgetTester tester) async {
    // Start the app.
    app.main();
    await tester.pumpAndSettle();

    // Get credentials from environment variables.
    final user1Email = dotenv.env['TEST_USER_1_EMAIL'];
    final user1Password = dotenv.env['TEST_USER_1_PASSWORD'];
    final user2Email = dotenv.env['TEST_USER_2_EMAIL'];
    final user2Password = dotenv.env['TEST_USER_2_PASSWORD'];

    expect(user1Email, isNotNull, reason: 'TEST_USER_1_EMAIL not found in .env');
    expect(user1Password, isNotNull, reason: 'TEST_USER_1_PASSWORD not found in .env');
    expect(user2Email, isNotNull, reason: 'TEST_USER_2_EMAIL not found in .env');
    expect(user2Password, isNotNull, reason: 'TEST_USER_2_PASSWORD not found in .env');

    // --- Test User 1 ---
    await login(tester, user1Email!, user1Password!);
    await logout(tester);

    // --- Test User 2 ---
    // After logging out, we might need to navigate back to the login page
    // if the app shows a register/login choice.
    final loginSwitch = find.widgetWithText(GestureDetector, "Login now");
    if (await tester.pumpAndSettle() > 0 && loginSwitch.evaluate().isNotEmpty) {
       await tester.tap(loginSwitch);
       await tester.pumpAndSettle();
    }
    await login(tester, user2Email!, user2Password!);
    await logout(tester);
  });
} 