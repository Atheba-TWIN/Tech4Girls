// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tech4girls/main.dart';

void main() {
  testWidgets('App launches to main navigation when onboarding done', (
    WidgetTester tester,
  ) async {
    // Build our app with onboarding already completed.
    await tester.pumpWidget(const MyApp(onboardingDone: true));

    // Expect to see bottom navigation bar items.
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });
}
