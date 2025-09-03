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
  TestWidgetsFlutterBinding.ensureInitialized();
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

      // Verify that theme provider starts with default theme (dark mode)
      expect(find.byKey(const Key('theme_name')), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
    });

    testWidgets('Theme provider methods return correct values', (WidgetTester tester) async {
      final themeProvider = ThemeProvider();
      
      // Test theme names
      expect(themeProvider.getThemeName(AppThemeType.aurennaDark), 'Dark Mode');
      expect(themeProvider.getThemeName(AppThemeType.aurennaLight), 'Light Mode');
      
      // Test theme descriptions
      expect(themeProvider.getThemeDescription(AppThemeType.aurennaDark), 'Deep cosmic colors with mystical vibes');
      expect(themeProvider.getThemeDescription(AppThemeType.aurennaLight), 'Bright and ethereal cosmic colors');
      
      // Test isDarkMode getter
      expect(themeProvider.isDarkMode, true); // Should default to dark mode
    });

    testWidgets('App theme data provides correct colors', (WidgetTester tester) async {
      const testTheme = AppThemes.aurennaDarkTheme;
      
      expect(testTheme.primary, const Color(0xFF6366F1));
      expect(testTheme.background, const Color(0xFF0F0F23));
      expect(testTheme.headingFont, 'Outfit');
      expect(testTheme.bodyFont, 'Outfit');
      expect(testTheme.displayFont, 'Cinzel');
    });

    testWidgets('Dark mode theme has valid configuration', (WidgetTester tester) async {
      const themeType = AppThemeType.aurennaDark;
      
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

      // Verify Dark Mode theme has a name and description
      expect(find.byKey(Key('name_$themeType')), findsOneWidget);
      expect(find.byKey(Key('desc_$themeType')), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.text('Deep cosmic colors with mystical vibes'), findsOneWidget);
    });

    testWidgets('Light mode theme has valid configuration', (WidgetTester tester) async {
      const themeType = AppThemeType.aurennaLight;
      
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

      // Verify Light Mode theme has a name and description
      expect(find.byKey(Key('name_$themeType')), findsOneWidget);
      expect(find.byKey(Key('desc_$themeType')), findsOneWidget);
      expect(find.text('Light Mode'), findsOneWidget);
      expect(find.text('Bright and ethereal cosmic colors'), findsOneWidget);
    });

    testWidgets('Light theme data provides correct colors', (WidgetTester tester) async {
      const lightTheme = AppThemes.aurennaLightTheme;
      
      expect(lightTheme.primary, const Color(0xFF4F46E5));
      expect(lightTheme.background, const Color(0xFFF8FAFC));
      expect(lightTheme.textPrimary, const Color(0xFF0A0B0D)); // void black
      expect(lightTheme.headingFont, 'Outfit');
      expect(lightTheme.bodyFont, 'Outfit');
      expect(lightTheme.displayFont, 'Cinzel');
    });
  });
}
