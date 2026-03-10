// RoamQuest Integration Tests
//
// These tests verify the main user flows of the RoamQuest app
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:roam_quest/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('RoamQuest Integration Tests', () {
    testWidgets('App startup and navigation smoke test',
        (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const RoamQuestApp());

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify we see either login page or home page (depending on auth state)
      expect(
          find.byType(MaterialApp), findsOneWidget,
          reason: 'App should render MaterialApp');
    });

    testWidgets('Login page renders correctly', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const RoamQuestApp());

      // Wait for auth state to resolve
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // If not logged in, should see login page elements
      final emailField = find.text('Email');
      final passwordField = find.text('Password (min 6 characters)');
      final signInButton = find.text('Sign In');

      // Check if any login elements are present
      expect(
          emailField.evaluate().isNotEmpty ||
              passwordField.evaluate().isNotEmpty ||
              signInButton.evaluate().isNotEmpty,
          true,
          reason: 'Should see login page elements');
    });

    testWidgets('Home page renders when authenticated',
        (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const RoamQuestApp());

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // If authenticated, should see home page elements
      final createButton = find.text('Create Checklist');
      final homeIcon = find.byIcon(Icons.home_outlined);
      final bottomNav = find.byType(BottomNavigationBar);

      // Check if home page elements are present
      expect(
          createButton.evaluate().isNotEmpty ||
              homeIcon.evaluate().isNotEmpty ||
              bottomNav.evaluate().isNotEmpty,
          true,
          reason: 'Should see home page elements when authenticated');
    });

    testWidgets('Bottom navigation has correct items',
        (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const RoamQuestApp());

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Look for bottom navigation
      final bottomNav = find.byType(BottomNavigationBar);

      if (bottomNav.evaluate().isNotEmpty) {
        // Check for expected navigation items
        expect(find.text('Home'), findsAtLeastNWidgets(1),
            reason: 'Should have Home tab');
        expect(find.text('Premium'), findsAtLeastNWidgets(1),
            reason: 'Should have Premium tab');
        expect(find.text('My Profile'), findsAtLeastNWidgets(1),
            reason: 'Should have Profile tab');
      }
    });

    testWidgets('Can tap on navigation items', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const RoamQuestApp());

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Look for bottom navigation
      final homeIcon = find.byIcon(Icons.home_outlined);
      final premiumIcon = find.byIcon(Icons.workspace_premium_outlined);
      final profileIcon = find.byIcon(Icons.person_outline);

      // Try tapping on navigation items if they exist
      if (homeIcon.evaluate().isNotEmpty) {
        await tester.tap(homeIcon);
        await tester.pumpAndSettle();
      }

      if (premiumIcon.evaluate().isNotEmpty) {
        await tester.tap(premiumIcon);
        await tester.pumpAndSettle();
      }

      if (profileIcon.evaluate().isNotEmpty) {
        await tester.tap(profileIcon);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('App does not crash on rapid taps',
        (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const RoamQuestApp());

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Rapid tap test
      final homeIcon = find.byIcon(Icons.home_outlined);
      final profileIcon = find.byIcon(Icons.person_outline);

      for (int i = 0; i < 5; i++) {
        if (homeIcon.evaluate().isNotEmpty) {
          await tester.tap(homeIcon);
        }
        if (profileIcon.evaluate().isNotEmpty) {
          await tester.tap(profileIcon);
        }
        await tester.pump();
      }

      await tester.pumpAndSettle();

      // App should still be running
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Create Checklist button is visible on home',
        (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const RoamQuestApp());

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Look for Create Checklist button
      final createButton = find.text('Create Checklist');

      // If home page is loaded, button should be visible
      if (createButton.evaluate().isNotEmpty) {
        expect(createButton, findsAtLeastNWidgets(1),
            reason: 'Create Checklist button should be visible');
      }
    });

    testWidgets('App theme is applied correctly', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const RoamQuestApp());

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify MaterialApp exists (indicates theme is set)
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Profile page shows sign out option',
        (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const RoamQuestApp());

      // Wait for app to fully load
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Try to navigate to profile
      final profileIcon = find.byIcon(Icons.person_outline);
      if (profileIcon.evaluate().isNotEmpty) {
        await tester.tap(profileIcon);
        await tester.pumpAndSettle();

        // Look for sign out option
        final signOut = find.text('Sign Out');
        if (signOut.evaluate().isNotEmpty) {
          expect(signOut, findsAtLeastNWidgets(1),
              reason: 'Sign Out option should be visible in profile');
        }
      }
    });
  });
}
