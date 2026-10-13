import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Colours for the themed (light / dark) surfaces: landing page and campus map.
///
/// Light = white is the main colour with red accents.
/// Dark  = red is the main colour with white accents.
class CampusPalette {
  CampusPalette._({
    required this.isDark,
    required this.backdrop,
    required this.glass,
    required this.glassStrong,
    required this.glassBorder,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.photoTint,
    required this.mapTiles,
  });

  final bool isDark;

  /// Page background gradient (top-left to bottom-right).
  final List<Color> backdrop;

  /// Standard glass panel gradient.
  final List<Color> glass;

  /// Denser glass for panels that sit on busy photos or maps.
  final List<Color> glassStrong;
  final Color glassBorder;
  final Color text;
  final Color textMuted;

  /// Main brand colour on this theme (buttons, pins, highlights).
  final Color accent;
  final Color onAccent;

  /// Colour washed over photos so text on top stays readable.
  final Color photoTint;

  /// Map tile style URL template.
  final String mapTiles;

  static final CampusPalette light = CampusPalette._(
    isDark: false,
    backdrop: const [Color(0xFFFFFFFF), Color(0xFFFFF3F3), Color(0xFFFFE2E2)],
    glass: [
      Colors.white.withValues(alpha: 0.78),
      Colors.white.withValues(alpha: 0.58),
      AppColors.tintBlush.withValues(alpha: 0.60),
    ],
    glassStrong: [
      Colors.white.withValues(alpha: 0.92),
      Colors.white.withValues(alpha: 0.82),
      AppColors.tintBlush.withValues(alpha: 0.80),
    ],
    glassBorder: AppColors.primary.withValues(alpha: 0.16),
    text: const Color(0xFF3D0A0A),
    textMuted: const Color(0xFF6E3434),
    accent: AppColors.primary,
    onAccent: Colors.white,
    photoTint: Colors.white,
    mapTiles: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
  );

  static final CampusPalette dark = CampusPalette._(
    isDark: true,
    backdrop: const [Color(0xFF3A0404), Color(0xFF8E1212), Color(0xFFC62828)],
    glass: [
      Colors.white.withValues(alpha: 0.26),
      const Color(0xFFFF8A80).withValues(alpha: 0.16),
      AppColors.primary.withValues(alpha: 0.32),
    ],
    glassStrong: [
      const Color(0xFF7A0F0F).withValues(alpha: 0.86),
      AppColors.primary.withValues(alpha: 0.80),
      const Color(0xFF5C0A0A).withValues(alpha: 0.88),
    ],
    glassBorder: Colors.white.withValues(alpha: 0.32),
    text: Colors.white,
    textMuted: const Color(0xE6FFFFFF),
    accent: Colors.white,
    onAccent: AppColors.primary,
    photoTint: AppColors.primaryDark,
    mapTiles: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
  );

  static CampusPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
