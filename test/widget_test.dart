// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:snapameal/main.dart';

void main() {
  testWidgets('SnapAMeal app smoke test', (WidgetTester tester) async {
    // Test a simple widget without Firebase dependencies
    await tester.pumpWidget(const MaterialApp(
      home: HelloWorldPage(),
    ));

    // Verify that the HelloWorld page loads properly
    expect(find.text('Hello Gauntlet world'), findsOneWidget);
    expect(find.text('flutter + firebase (coming soon)'), findsOneWidget);
  });
}
