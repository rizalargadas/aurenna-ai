// This is a basic Flutter widget test for Aurenna AI.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:aurenna_ai/providers/theme_provider.dart';
import 'package:aurenna_ai/config/app_themes.dart';

void main() {
  group('Aurenna AI Widget Tests', () {
    testWidgets('Theme provider initializes with default theme', (WidgetTester tester) async {
      // Create a test widget with theme provider
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => ThemeProvider(),
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Scaffold(
                  body: Center(
                    child: Text(
                      themeProvider.getThemeName(themeProvider.currentTheme),
                      key: const Key('theme_name'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Allow the widget to build
      await tester.pump();

      // Verify that theme provider starts with default theme
      expect(find.byKey(const Key('theme_name')), findsOneWidget);
      expect(find.text('Aurenna'), findsOneWidget);
    });

    testWidgets('Theme provider maintains Aurenna theme', (WidgetTester tester) async {
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => ThemeProvider(),
            child: Consumer<ThemeProvider>(
              builder: (context, provider, child) {
                return Scaffold(
                  body: Column(
                    children: [
                      Text(
                        provider.getThemeName(provider.currentTheme),
                        key: const Key('current_theme'),
                      ),
                      ElevatedButton(
                        key: const Key('keep_theme'),
                        onPressed: () => provider.setTheme(AppThemeType.aurenna),
                        child: const Text('Keep Theme'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Initially should show Aurenna theme
      await tester.pump();
      expect(find.text('Aurenna'), findsOneWidget);

      // Tap the keep theme button
      await tester.tap(find.byKey(const Key('keep_theme')));
      await tester.pump();

      // Should still show Aurenna theme
      expect(find.text('Aurenna'), findsOneWidget);
    });

    testWidgets('App theme data provides correct colors', (WidgetTester tester) async {
      const testTheme = AppThemes.aurennaTheme;
      
      expect(testTheme.primary, const Color(0xFF6366F1));
      expect(testTheme.background, const Color(0xFF0F0F23));
      expect(testTheme.headingFont, 'Outfit');
      expect(testTheme.bodyFont, 'Outfit');
      expect(testTheme.displayFont, 'Cinzel');
    });

    testWidgets('Aurenna theme has valid configuration', (WidgetTester tester) async {
      const themeType = AppThemeType.aurenna;
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => ThemeProvider(),
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                final themeName = themeProvider.getThemeName(themeType);
                final themeDescription = themeProvider.getThemeDescription(themeType);
                
                return Scaffold(
                  body: Column(
                    children: [
                      Text(themeName, key: Key('name_$themeType')),
                      Text(themeDescription, key: Key('desc_$themeType')),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify Aurenna theme has a name and description
      expect(find.byKey(Key('name_$themeType')), findsOneWidget);
      expect(find.byKey(Key('desc_$themeType')), findsOneWidget);
      expect(find.text('Aurenna'), findsOneWidget);
      expect(find.text('Deep cosmic colors with mystical vibes'), findsOneWidget);
    });
  });
}
