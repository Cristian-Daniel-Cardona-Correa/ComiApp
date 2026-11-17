import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Tipografía de comiAPP
/// Títulos: Baloo 2 / Fredoka (redondeada y gruesa)
/// Cuerpo y botones: Nunito / Poppins (legible y amigable)
class AppTypography {
  AppTypography._();

  // Títulos culinarios redondeados y gruesos
  static TextStyle displayLarge = GoogleFonts.baloo2(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
    height: 1.2,
  );

  static TextStyle displayMedium = GoogleFonts.baloo2(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    height: 1.25,
  );

  static TextStyle titleLarge = GoogleFonts.baloo2(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
  );

  static TextStyle titleMedium = GoogleFonts.baloo2(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  // Modo cocina: instrucciones grandes (>= 24sp)
  static TextStyle cookingInstruction = GoogleFonts.nunito(
    fontSize: 25,
    fontWeight: FontWeight.w700,
    color: AppColors.textDark,
    height: 1.35,
  );

  // Cuerpo de texto
  static TextStyle bodyLarge = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    height: 1.4,
  );

  static TextStyle bodyMedium = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textDark,
    height: 1.4,
  );

  static TextStyle bodySmall = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  // Botones prominentes
  static TextStyle button = GoogleFonts.baloo2(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  // Chips y etiquetas dietéticas
  static TextStyle badge = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );
}
