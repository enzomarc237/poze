// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:poze/app.dart'; // Import the App widget

void main() {
  // Basic test to ensure the app builds without crashing
  testWidgets('App builds smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Use the actual root widget 'App' instead of 'MyApp'
    await tester.pumpWidget(const App()); 

    // Example: Verify that the HomeView is initially displayed
    // (You might need more specific finders based on your UI)
    expect(find.byType(MacosWindow), findsOneWidget); 
    // Add more specific checks if needed, e.g., finding the toolbar title
    // expect(find.text('Poze - Gestionnaire d\'Applications'), findsOneWidget);
  });
}
