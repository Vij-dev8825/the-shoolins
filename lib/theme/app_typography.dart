import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

// A boutique-fashion pairing: Playfair Display (a high-contrast editorial
// serif) for the brand wordmark, hero copy and headlines, and Poppins (a
// clean geometric sans) for everything functional — body copy, labels,
// prices, buttons.
class AppTypography {
  AppTypography._();

  static TextStyle get wordmark => GoogleFonts.playfairDisplay(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 3,
    color: AppColors.ink,
  );

  static TextStyle get display => GoogleFonts.playfairDisplay(
    fontSize: 34,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.15,
    color: AppColors.ink,
  );

  static TextStyle get headline => GoogleFonts.playfairDisplay(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.ink,
  );

  static TextStyle get title => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  static TextStyle get body => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.ink,
  );

  static TextStyle get bodyMuted => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.inkMuted,
  );

  static TextStyle get label => GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
    color: AppColors.inkMuted,
  );

  static TextStyle get price => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.accentDark,
  );

  static TextTheme get textTheme => TextTheme(
    displayMedium: display,
    headlineSmall: headline,
    titleMedium: title,
    bodyMedium: body,
    bodySmall: bodyMuted,
    labelLarge: label,
  );
}
