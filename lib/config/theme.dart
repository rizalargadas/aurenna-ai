import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_themes.dart';

class AurennaTheme {
  // Primary Colors - Dark Mystical Theme
  static const Color voidBlack = Color(0xFF0A0B0D); // Primary background
  static const Color silverMist = Color(0xFFC8D0E0); // Primary text
  static const Color electricViolet = Color(
    0xFF6366F1,
  ); // CTAs and interactions

  // Secondary Colors
  static const Color mysticBlue = Color(0xFF1E2A4A); // Cards and surfaces
  static const Color etherealIndigo = Color(0xFF2D4263); // Accents and borders
  static const Color cosmicPurple = Color(0xFF4A3B5C); // Special elements

  // Accent Colors
  static const Color amberGlow = Color(0xFFF59E0B); // Warnings and highlights
  static const Color crystalBlue = Color(0xFF60A5FA); // Information
  static const Color stardustPurple = Color(0xFF8B5CF6); // Special features

  // Additional UI Colors
  static const Color textPrimary = silverMist;
  static const Color textSecondary = Color(
    0xFF8B95A9,
  ); // Slightly dimmed silver
  static const Color errorColor = Color(
    0xFFEF4444,
  ); // Keeping a standard error red
  static const Color successColor = Color(0xFF10B981); // Success green

  // Gradients
  static const LinearGradient cosmicGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [electricViolet, stardustPurple],
  );

  static const LinearGradient mysticalGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [mysticBlue, etherealIndigo],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [voidBlack, mysticBlue],
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: electricViolet,
    scaffoldBackgroundColor: voidBlack,

    colorScheme: const ColorScheme.dark(
      primary: electricViolet,
      secondary: stardustPurple,
      background: voidBlack,
      surface: mysticBlue,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: silverMist,
      onSurface: silverMist,
      error: errorColor,
    ),

    textTheme: TextTheme(
      // Using Outfit font as specified in brand guide
      displayLarge: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: silverMist,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: silverMist,
      ),
      displaySmall: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: silverMist,
      ),

      titleLarge: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: silverMist,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: silverMist,
      ),
      titleSmall: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: silverMist,
      ),

      bodyLarge: GoogleFonts.outfit(
        fontSize: 16,
        color: silverMist,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.outfit(
        fontSize: 14,
        color: textSecondary,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.outfit(
        fontSize: 12,
        color: textSecondary,
        height: 1.4,
      ),

      labelLarge: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: silverMist,
      ),
      labelMedium: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: silverMist,
      ),
      labelSmall: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
    ),

    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: electricViolet,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        textStyle: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: silverMist,
        side: BorderSide(color: etherealIndigo, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: electricViolet,
        textStyle: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: mysticBlue.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: etherealIndigo, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: etherealIndigo.withOpacity(0.5),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: electricViolet, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      labelStyle: GoogleFonts.outfit(color: textSecondary, fontSize: 14),
      hintStyle: GoogleFonts.outfit(
        color: textSecondary.withOpacity(0.6),
        fontSize: 14,
      ),
      errorStyle: GoogleFonts.outfit(color: errorColor, fontSize: 12),
    ),

    // Card theme
    cardTheme: CardThemeData(
      color: mysticBlue,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: etherealIndigo.withOpacity(0.3), width: 1),
      ),
    ),

    // App bar theme
    appBarTheme: AppBarTheme(
      backgroundColor: voidBlack,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: silverMist,
      ),
      iconTheme: const IconThemeData(color: silverMist),
    ),
  );

  // Custom decorations for mystical elements
  static BoxDecoration mysticalGradientBox = BoxDecoration(
    gradient: mysticalGradient,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: etherealIndigo.withOpacity(0.3), width: 1),
  );

  static BoxDecoration cosmicGradientBox = BoxDecoration(
    gradient: cosmicGradient,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: electricViolet.withOpacity(0.3),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration cardDecoration = BoxDecoration(
    color: mysticBlue,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: etherealIndigo.withOpacity(0.3), width: 1),
    boxShadow: [
      BoxShadow(
        color: voidBlack.withOpacity(0.5),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Glow effect for special elements
  static BoxShadow cosmicGlow = BoxShadow(
    color: electricViolet.withOpacity(0.4),
    blurRadius: 20,
    spreadRadius: 2,
  );

  // Theme adapter methods to work with new theme system
  static ThemeData buildTheme(AppThemeData themeData) {
    return ThemeData(
      brightness: _getBrightness(themeData),
      primaryColor: themeData.primary,
      scaffoldBackgroundColor: themeData.background,

      colorScheme: ColorScheme.fromSeed(
        seedColor: themeData.primary,
        brightness: _getBrightness(themeData),
        primary: themeData.primary,
        secondary: themeData.secondary,
        background: themeData.background,
        surface: themeData.surface,
        onPrimary: _getContrastColor(themeData.primary),
        onSecondary: _getContrastColor(themeData.secondary),
        onBackground: themeData.textPrimary,
        onSurface: themeData.textPrimary,
        error: themeData.error,
      ),

      textTheme: _buildTextTheme(themeData),
      elevatedButtonTheme: _buildElevatedButtonTheme(themeData),
      outlinedButtonTheme: _buildOutlinedButtonTheme(themeData),
      textButtonTheme: _buildTextButtonTheme(themeData),
      inputDecorationTheme: _buildInputDecorationTheme(themeData),
      cardTheme: _buildCardTheme(themeData),
      appBarTheme: _buildAppBarTheme(themeData),
    );
  }

  static Brightness _getBrightness(AppThemeData themeData) {
    // Check if background is light or dark
    final luminance = themeData.background.computeLuminance();
    return luminance > 0.5 ? Brightness.light : Brightness.dark;
  }

  static Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  static TextTheme _buildTextTheme(AppThemeData themeData) {
    return TextTheme(
      // Display styles use displayFont for maximum impact
      displayLarge: _getGoogleFont(themeData.displayFont)(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: themeData.textPrimary,
        letterSpacing: -0.5,
      ),
      displayMedium: _getGoogleFont(themeData.displayFont)(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: themeData.textPrimary,
      ),
      displaySmall: _getGoogleFont(themeData.displayFont)(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: themeData.textPrimary,
      ),
      
      // Title styles use headingFont for hierarchy
      titleLarge: _getGoogleFont(themeData.headingFont)(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: themeData.textPrimary,
      ),
      titleMedium: _getGoogleFont(themeData.headingFont)(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: themeData.textPrimary,
      ),
      titleSmall: _getGoogleFont(themeData.headingFont)(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: themeData.textPrimary,
      ),
      
      // Body styles use bodyFont for readability
      bodyLarge: _getGoogleFont(themeData.bodyFont)(
        fontSize: 16,
        color: themeData.textPrimary,
        height: 1.5,
      ),
      bodyMedium: _getGoogleFont(themeData.bodyFont)(
        fontSize: 14,
        color: themeData.textSecondary,
        height: 1.5,
      ),
      bodySmall: _getGoogleFont(themeData.bodyFont)(
        fontSize: 12,
        color: themeData.textSecondary,
        height: 1.4,
      ),
      
      // Label styles use headingFont for buttons/labels
      labelLarge: _getGoogleFont(themeData.headingFont)(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: themeData.textPrimary,
      ),
      labelMedium: _getGoogleFont(themeData.headingFont)(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: themeData.textPrimary,
      ),
      labelSmall: _getGoogleFont(themeData.headingFont)(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: themeData.textSecondary,
      ),
    );
  }

  // Helper method to get Google Font function by name
  static TextStyle Function({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) _getGoogleFont(String fontName) {
    try {
      switch (fontName.toLowerCase()) {
        case 'outfit':
          return GoogleFonts.outfit;
        case 'poppins':
          return GoogleFonts.poppins;
        case 'inter':
          return GoogleFonts.inter;
        case 'merriweather':
          return GoogleFonts.merriweather;
        case 'lato':
          return GoogleFonts.lato;
        case 'cinzel':
          return GoogleFonts.cinzel;
        case 'playfair display':
          return GoogleFonts.playfairDisplay;
        case 'cormorant garamond':
          return GoogleFonts.cormorantGaramond;
        case 'crimson text':
          return GoogleFonts.crimsonText;
        default:
          // Fallback to Outfit if font not found
          return GoogleFonts.outfit;
      }
    } catch (e) {
      // If GoogleFonts fails, return a safe fallback
      return ({
        double? fontSize,
        FontWeight? fontWeight,
        Color? color,
        double? letterSpacing,
        double? height,
      }) => TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(AppThemeData themeData) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: themeData.primary,
        foregroundColor: _getContrastColor(themeData.primary),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        textStyle: _getGoogleFont(themeData.headingFont)(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(AppThemeData themeData) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: themeData.textPrimary,
        side: BorderSide(color: themeData.accent3, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: _getGoogleFont(themeData.headingFont)(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme(AppThemeData themeData) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: themeData.primary,
        textStyle: _getGoogleFont(themeData.headingFont)(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(AppThemeData themeData) {
    return InputDecorationTheme(
      filled: true,
      fillColor: themeData.surface.withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: themeData.accent3, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: themeData.accent3.withOpacity(0.5),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: themeData.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: themeData.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: themeData.error, width: 2),
      ),
      labelStyle: _getGoogleFont(themeData.bodyFont)(color: themeData.textSecondary, fontSize: 14),
      hintStyle: _getGoogleFont(themeData.bodyFont)(
        color: themeData.textSecondary.withOpacity(0.6),
        fontSize: 14,
      ),
      errorStyle: _getGoogleFont(themeData.bodyFont)(color: themeData.error, fontSize: 12),
    );
  }

  static CardThemeData _buildCardTheme(AppThemeData themeData) {
    return CardThemeData(
      color: themeData.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: themeData.accent3.withOpacity(0.3), width: 1),
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme(AppThemeData themeData) {
    return AppBarTheme(
      backgroundColor: themeData.background,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: _getGoogleFont(themeData.headingFont)(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: themeData.textPrimary,
      ),
      iconTheme: IconThemeData(color: themeData.textPrimary),
    );
  }
}
