import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_themes.dart';

enum AppThemeType {
  aurennaDark,
  aurennaLight,
}

class ThemeProvider with ChangeNotifier {
  AppThemeType _currentTheme = AppThemeType.aurennaDark;
  static const String _themeKey = 'selected_theme';
  bool _disposed = false;

  AppThemeType get currentTheme => _currentTheme;

  AppThemeData get themeData {
    switch (_currentTheme) {
      case AppThemeType.aurennaDark:
        return AppThemes.aurennaDarkTheme;
      case AppThemeType.aurennaLight:
        return AppThemes.aurennaLightTheme;
    }
  }

  ThemeProvider() {
    // Delay the async loading to ensure widget tree is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) {
        _loadTheme();
      }
    });
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      try {
        super.notifyListeners();
      } catch (e) {
        // Silently handle disposal errors
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _loadTheme() async {
    if (_disposed) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      // Explicitly default to dark mode (index 0) for new users
      final themeIndex = prefs.getInt(_themeKey) ?? AppThemeType.aurennaDark.index;
      
      // Ensure the index is valid
      if (themeIndex >= 0 && themeIndex < AppThemeType.values.length) {
        _currentTheme = AppThemeType.values[themeIndex];
      } else {
        // Fallback to dark mode if invalid index
        _currentTheme = AppThemeType.aurennaDark;
        await prefs.setInt(_themeKey, AppThemeType.aurennaDark.index);
      }
      
      if (!_disposed) {
        notifyListeners();
      }
    } catch (e) {
      // If loading fails, use default theme
      _currentTheme = AppThemeType.aurennaDark;
    }
  }

  Future<void> setTheme(AppThemeType theme) async {
    if (_disposed) return;
    
    _currentTheme = theme;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, theme.index);
    } catch (e) {
      // If saving fails, at least the UI theme is updated
    }
    
    if (!_disposed) {
      notifyListeners();
    }
  }

  String getThemeName(AppThemeType theme) {
    switch (theme) {
      case AppThemeType.aurennaDark:
        return 'Dark Mode';
      case AppThemeType.aurennaLight:
        return 'Light Mode';
    }
  }

  String getThemeDescription(AppThemeType theme) {
    switch (theme) {
      case AppThemeType.aurennaDark:
        return 'Deep cosmic colors with mystical vibes';
      case AppThemeType.aurennaLight:
        return 'Bright and ethereal cosmic colors';
    }
  }

  bool get isDarkMode => _currentTheme == AppThemeType.aurennaDark;
  
  void toggleTheme() {
    final newTheme = _currentTheme == AppThemeType.aurennaDark 
        ? AppThemeType.aurennaLight 
        : AppThemeType.aurennaDark;
    setTheme(newTheme);
  }
}