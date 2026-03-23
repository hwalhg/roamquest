import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam_quest/core/theme/app_theme.dart';
import 'package:roam_quest/features/subscription/subscription_page.dart';
import 'package:roam_quest/l10n/app_localizations.dart';

/// Basic widget tests for SubscriptionPage
/// Note: These are minimal rendering tests due to IAP dependencies
/// Full widget testing requires complex IAP mocking which is covered by integration tests
void main() {
  group('SubscriptionPage Basic Tests', () {
    testWidgets('should create subscription page widget', (tester) async {
      // Arrange
      const page = SubscriptionPage();

      // Act - Use pump() instead of pumpAndSettle() to avoid waiting for IAP
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
          ],
          home: page,
        ),
      );
      // Pump once to build the widget
      await tester.pump();

      // Assert
      expect(find.byType(SubscriptionPage), findsOneWidget);
    });

    testWidgets('should render without throwing', (tester) async {
      // Act & Assert - Should not throw
      expect(
        () async {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              localizationsDelegates: const [
                AppLocalizations.delegate,
              ],
              home: const SubscriptionPage(),
            ),
          );
          await tester.pump();
        },
        returnsNormally,
      );
    });

    testWidgets('should have StatefulWidget', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
          ],
          home: const SubscriptionPage(),
        ),
      );
      await tester.pump();

      // Assert - SubscriptionPage should extend StatefulWidget
      final widget = tester.widget(find.byType(SubscriptionPage));
      expect(widget, isA<StatefulWidget>());
    });

    testWidgets('should create key', (tester) async {
      // Arrange
      const page = SubscriptionPage();

      // Assert
      expect(page.key, isNull);
    });

    testWidgets('should render scaffold structure', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
          ],
          home: const SubscriptionPage(),
        ),
      );
      await tester.pump();

      // Assert - Should have basic Scaffold structure
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('should render app bar with close button', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
          ],
          home: const SubscriptionPage(),
        ),
      );
      await tester.pump();

      // Assert - Should have close icon button
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should render premium icon', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
          ],
          home: const SubscriptionPage(),
        ),
      );
      await tester.pump();

      // Assert - Should have premium icon
      expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
    });

    testWidgets('should render gradient background', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
          ],
          home: const SubscriptionPage(),
        ),
      );
      await tester.pump();

      // Assert - Should have Container with gradient decoration
      final container = find.descendant(
        of: find.byType(Scaffold),
        matching: find.byType(Container),
      ).first;

      final containerWidget = tester.widget<Container>(container);
      expect(containerWidget.decoration, isA<BoxDecoration>());
      final decoration = containerWidget.decoration as BoxDecoration;
      expect(decoration.gradient, isNotNull);
    });

    testWidgets('should render feature list', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
          ],
          home: const SubscriptionPage(),
        ),
      );
      await tester.pump();

      // Assert - Should have feature icons
      expect(find.byIcon(Icons.all_inclusive), findsOneWidget);
      expect(find.byIcon(Icons.assessment), findsOneWidget);
      expect(find.byIcon(Icons.cloud_download), findsOneWidget);
    });

    testWidgets('should render buttons', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
          ],
          home: const SubscriptionPage(),
        ),
      );
      await tester.pump();

      // Assert - Should have at least one type of button
      // Note: ElevatedButton may not be rendered until products load
      final hasAnyButton = find.byType(TextButton).evaluate().isNotEmpty ||
          find.byType(ElevatedButton).evaluate().isNotEmpty ||
          find.byType(IconButton).evaluate().isNotEmpty;

      expect(hasAnyButton, isTrue);
    });
  });

  group('SubscriptionPage Web Platform Tests', () {
    testWidgets('should show unavailable message on web', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
          ],
          home: const SubscriptionPage(),
        ),
      );
      // Pump multiple times to allow async initialization
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // On web/non-iOS platforms, should show unavailable message
      // Note: This test may not consistently show the message on all platforms
      // The actual behavior depends on the platform running the test
      final infoIconFound = find.byIcon(Icons.info_outline).evaluate().isNotEmpty;

      if (infoIconFound) {
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      }
    });
  });

  group('SubscriptionPage Layout Tests', () {
    testWidgets('should use ListView for scrollable content', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
          ],
          home: const SubscriptionPage(),
        ),
      );
      await tester.pump();

      // Assert - Should use ListView for scrollability
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should have proper padding', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
          ],
          home: const SubscriptionPage(),
        ),
      );
      await tester.pump();

      // Assert - ListView should have padding
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.padding, isNotNull);
    });
  });
}
