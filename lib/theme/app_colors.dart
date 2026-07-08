import 'package:flutter/material.dart';

// Light yellow + gold shine palette: a warm, pale golden-yellow base
// throughout the app (app bars, drawer, page background alike), with
// bright saturated gold as the primary accent and a deep amber for chrome
// that needs to host light text (drawer header, bottom nav).
class AppColors {
  AppColors._();

  static const background = Color(0xFFFFFBEF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF7EFD9);
  static const divider = Color(0xFFEEDFB8);

  static const ink = Color(0xFF1F1B13);
  static const inkMuted = Color(0xFF7A7263);
  static const inkFaint = Color(0xFFBEB6A2);

  // Gold — primary accent, bright and saturated for a premium branded feel.
  static const accent = Color(0xFFFFB300);
  static const accentDark = Color(0xFFC17F00);
  static const accentSurface = Color(0xFFFFECB3);

  // Light blue — secondary accent, used sparingly for the shine sweep highlight.
  static const secondary = Color(0xFF00B0FF);
  static const secondaryDark = Color(0xFF0086C6);
  static const secondarySurface = Color(0xFFD6F1FF);

  static const error = Color(0xFFB3261E);
  static const success = Color(0xFF3D6B4F);
}
