import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class AppColors {
  static const bg = Color(0xFF0F1113); // fundo base
  static const surface = Color(0xFF16191C); // cards
  static const surfaceRaised = Color(0xFF1C2024); // cards em destaque
  static const border = Color(0xFF262B30); // bordas
  static const borderAccent = Color(0xFF1D3D5C); // borda de destaque

  static const textPrimary = Color(0xFFECEDEE);
  static const textSecondary = Color(0xFF9AA1A8);
  static const textMuted = Color(0xFF6B737B);

  static const accent = Color(0xFF4DA3FF); // azul neon tech
  static const accentHover = Color(0xFF7CC5FF);
  static const accentSoft = Color(0xFF15263A);
  static const onAccent = Color(0xFF08121F);

  static const income = Color(0xFF5FD4A0); // verde, entradas
  static const expense = Color(0xFFE0785F); // coral, saídas
}

/// Raios de canto usados no app.
class AppRadius {
  static const card = 12.0;
  static const field = 10.0;
  static const chip = 20.0;
}

/// Espessuras de borda.
class AppBorders {
  static const normal = 0.5;
  static const selected = 1.0;
}

/// Estilos de texto reutilizáveis.
class AppText {
  static TextStyle serif({
    double size = 32,
    Color color = AppColors.textPrimary,
    FontWeight weight = FontWeight.w600,
  }) {
    return GoogleFonts.fraunces(
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: 1.05,
      letterSpacing: -0.5,
    );
  }

  /// Valores monetários, com algarismos de largura fixa.
  static TextStyle money({
    double size = 16,
    Color color = AppColors.textPrimary,
    FontWeight weight = FontWeight.w500,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      color: color,
      fontWeight: weight,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}

class AppTheme {
  static ThemeData build() {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      dividerColor: AppColors.border,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        primary: AppColors.accent,
        onPrimary: AppColors.onAccent,
        secondary: AppColors.accentSoft,
        onSecondary: AppColors.textPrimary,
        error: AppColors.expense,
        onError: AppColors.onAccent,
        outline: AppColors.border,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
    );
  }
}