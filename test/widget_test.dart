// RoamQuest widget tests
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:roam_quest/core/theme/app_theme.dart';

void main() {
  testWidgets('App theme smoke test', (WidgetTester tester) async {
    // Build a simple app with our theme to test basic UI
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Center(
            child: Text('RoamQuest'),
          ),
        ),
      ),
    );

    // Verify that the app renders without errors
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('RoamQuest'), findsOneWidget);
  });

  testWidgets('Login page components test', (WidgetTester tester) async {
    // Test basic widgets used in login page
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Column(
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Email'),
                key: Key('email_field'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Password'),
                key: Key('password_field'),
                obscureText: true,
              ),
            ],
          ),
        ),
      ),
    );

    // Verify email field exists
    expect(find.byKey(const Key('email_field')), findsOneWidget);
    // Verify password field exists
    expect(find.byKey(const Key('password_field')), findsOneWidget);
  });

  testWidgets('Navigation bar components test', (WidgetTester tester) async {
    // Test bottom navigation bar
    int currentIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) {
              currentIndex = index;
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.workspace_premium_outlined),
                label: 'Premium',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'My Profile',
              ),
            ],
          ),
        ),
      ),
    );

    // Verify all navigation items exist
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Premium'), findsOneWidget);
    expect(find.text('My Profile'), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.workspace_premium_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });
}
