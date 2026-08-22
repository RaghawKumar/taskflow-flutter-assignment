import 'package:flutter/material.dart';

/// TaskFlow's single source of truth for brand and semantic colors.
abstract final class AppColors {
  static const primary = Color(0xFF5267E8);
  static const accent = Color(0xFF27D3C2);
  static const navy = Color(0xFF11183F);
  static const lightBackground = Color(0xFFF7F9FF);
  static const darkBackground = Color(0xFF090E29);
  static const warning = Color(0xFFF59E0B);

  static ColorScheme scheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: dark ? const Color(0xFF91A0FF) : primary,
      onPrimary: dark ? navy : Colors.white,
      secondary: dark ? const Color(0xFF61E8DA) : accent,
      onSecondary: navy,
      tertiary: warning,
      surface: dark ? const Color(0xFF111735) : Colors.white,
    );
  }
}
