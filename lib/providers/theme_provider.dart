import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_themes.dart';

enum AppThemeType {
  aurenna,
}

class ThemeProvider with ChangeNotifier {
  AppThemeType _currentTheme = AppThemeType.aurenna;
  static const String _themeKey = 'selected_theme';
  bool _disposed = false;

  AppThemeType get currentTheme => _currentTheme;

  AppThemeData get themeData {
    return AppThemes.aurennaTheme;
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
      final themeIndex = prefs.getInt(_themeKey) ?? 0;
      
      // Ensure the index is valid
      if (themeIndex >= 0 && themeIndex < AppThemeType.values.length) {
        _currentTheme = AppThemeType.values[themeIndex];
      } else {
        _currentTheme = AppThemeType.aurenna;
      }
      
      if (!_disposed) {
        notifyListeners();
      }
    } catch (e) {
      // If loading fails, use default theme
      _currentTheme = AppThemeType.aurenna;
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
    return 'Aurenna';
  }

  String getThemeDescription(AppThemeType theme) {
    return 'Deep cosmic colors with mystical vibes';
  }
}