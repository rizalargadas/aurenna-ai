import 'package:flutter/material.dart';

class AppThemeData {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent1;
  final Color accent2;
  final Color accent3;
  final Color success;
  final Color warning;
  final Color error;
  
  // Gradients
  final LinearGradient primaryGradient;
  final LinearGradient secondaryGradient;
  final LinearGradient backgroundGradient;
  
  // Shadows
  final BoxShadow primaryShadow;
  final BoxShadow secondaryShadow;
  
  // Typography
  final String headingFont;
  final String bodyFont;
  final String displayFont;

  const AppThemeData({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent1,
    required this.accent2,
    required this.accent3,
    required this.success,
    required this.warning,
    required this.error,
    required this.primaryGradient,
    required this.secondaryGradient,
    required this.backgroundGradient,
    required this.primaryShadow,
    required this.secondaryShadow,
    required this.headingFont,
    required this.bodyFont,
    required this.displayFont,
  });
}

class AppThemes {
  // Aurenna Dark Theme (Dark Cosmic)
  static const AppThemeData aurennaDarkTheme = AppThemeData(
    primary: Color(0xFF6366F1), // Electric Violet
    secondary: Color(0xFF3B82F6), // Crystal Blue
    background: Color(0xFF0F0F23), // Void Black
    surface: Color(0xFF1E1B4B), // Mystic Blue
    textPrimary: Color(0xFFF1F5F9), // Silver Mist
    textSecondary: Color(0xFF94A3B8), // Text Secondary
    accent1: Color(0xFFF59E0B), // Amber Glow
    accent2: Color(0xFF8B5CF6), // Cosmic Purple
    accent3: Color(0xFF312E81), // Ethereal Indigo
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    ),
    secondaryGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
    ),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0F0F23), Color(0xFF1E1B4B)],
    ),
    
    primaryShadow: BoxShadow(
      color: Color(0x4D6366F1),
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
    secondaryShadow: BoxShadow(
      color: Color(0x4D3B82F6),
      blurRadius: 15,
      offset: Offset(0, 5),
    ),
    
    // Mystical fonts
    headingFont: 'Outfit', // Modern yet mystical
    bodyFont: 'Outfit',    // Clean readability
    displayFont: 'Cinzel', // Elegant and magical
  );

  // Aurenna Light Theme (Light Cosmic)
  static const AppThemeData aurennaLightTheme = AppThemeData(
    primary: Color(0xFF4F46E5), // Deeper Indigo for better contrast on light
    secondary: Color(0xFF1E40AF), // Deeper Blue
    background: Color(0xFFF8FAFC), // Light gray-white
    surface: Color(0xFFFFFFFF), // Pure white
    textPrimary: Color(0xFF0A0B0D), // Void black
    textSecondary: Color(0xFF0A0B0D), // Void black
    accent1: Color(0xFFF59E0B), // Amber Glow (same)
    accent2: Color(0xFF7C3AED), // Deep purple
    accent3: Color(0xFFE2E8F0), // Light gray borders
    success: Color(0xFF059669), // Darker success green
    warning: Color(0xFFF59E0B), // Same warning amber
    error: Color(0xFFDC2626), // Darker error red
    
    primaryGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    ),
    secondaryGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1E40AF), Color(0xFF1E3A8A)],
    ),
    backgroundGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
    ),
    
    primaryShadow: BoxShadow(
      color: Color(0x334F46E5),
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
    secondaryShadow: BoxShadow(
      color: Color(0x331E40AF),
      blurRadius: 15,
      offset: Offset(0, 5),
    ),
    
    // Same mystical fonts
    headingFont: 'Outfit',
    bodyFont: 'Outfit',
    displayFont: 'Cinzel',
  );
}