import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color background = Color(0xFF0D0F14);
  static const Color surface = Color(0xFF141720);
  static const Color surfaceElevated = Color(0xFF1A1E2A);
  static const Color border = Color(0xFF252A38);
  static const Color borderLight = Color(0xFF2E3447);

  static const Color textPrimary = Color(0xFFE8ECF4);
  static const Color textSecondary = Color(0xFF6B7494);
  static const Color textMuted = Color(0xFF444C66);

  static const Color accentCyan = Color(0xFF00D4FF);
  static const Color accentGreen = Color(0xFF00FF88);
  static const Color accentBlue = Color(0xFF4D7CFE);
  static const Color accentPurple = Color(0xFF9B6DFF);
  static const Color accentOrange = Color(0xFFFF6B35);

  static const Color tagWork = Color(0xFF1E3A5F);
  static const Color tagWorkText = Color(0xFF4D9FFF);
  static const Color tagFinance = Color(0xFF1E3A2A);
  static const Color tagFinanceText = Color(0xFF4DFF9F);
  static const Color tagSocial = Color(0xFF3A1E3A);
  static const Color tagSocialText = Color(0xFFD44DFF);
  static const Color tagShopping = Color(0xFF3A2A1E);
  static const Color tagShoppingText = Color(0xFFFF9B4D);

  static const Color tag2FA = Color(0xFF2A1E3A);
  static const Color tag2FAText = Color(0xFF9B6DFF);

  static const Color strengthStrong = Color(0xFF00FF88);
  static const Color strengthGood = Color(0xFF4D7CFE);
  static const Color strengthWeak = Color(0xFFFF6B35);

  static const Color sidebarActive = Color(0xFF1A2744);
  static const Color sidebarHover = Color(0xFF161C2E);

  // Text styles
  static const TextStyle fontMono = TextStyle(fontFamily: 'monospace');

  static TextTheme get textTheme => const TextTheme(
        displayLarge: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textSecondary,
          fontSize: 13,
        ),
        bodySmall: TextStyle(
          color: textMuted,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          surface: surface,
          primary: accentCyan,
          secondary: accentGreen,
        ),
        textTheme: textTheme,
        fontFamily: 'SF Pro Display',
      );
}