import 'package:flutter/material.dart';

/// Colour system: one primary, one accent and two supporting tints,
/// all tuned so white text stays readable on top of them.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFC62828); // crimson
  static const Color primaryDark = Color(0xFF4A0505); // deep maroon
  static const Color accent = Color(0xFFFF6B6B); // coral red
  static const Color tintSnow = Color(0xFFFFF5F5); // supporting tint 1
  static const Color tintBlush = Color(0xFFFFE3E3); // supporting tint 2

  static const Color success = Color(0xFF7CF2B0);
  static const Color warning = Color(0xFFFFD27A);
  static const Color muted = Color(0xD9FFFFFF); // white at 85%

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4A0505), Color(0xFF9E1414), Color(0xFFC62828)],
  );
}

/// Spacing scale used everywhere (4-point grid).
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Corner radii for the card system.
class AppRadius {
  AppRadius._();

  static const double card = 24;
  static const double tile = 18;
  static const double chip = 12;
  static const double pill = 999;
}

/// Tone of a [StatusBadge].
enum BadgeTone { success, warning, danger, info, light }

class AppText {
  AppText._();

  static const TextStyle display = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    height: 1.1,
    letterSpacing: -0.5,
  );
  static const TextStyle h1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    height: 1.2,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.25,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  static const TextStyle title = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.3,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.muted,
    height: 1.45,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12.5,
    color: AppColors.muted,
    height: 1.35,
  );
  static const TextStyle overline = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    color: AppColors.muted,
    letterSpacing: 1.2,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get theme {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: Colors.white,
      onPrimary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.primaryDark,
      onSurface: Colors.white,
    );

    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.tile),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.30)),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.primaryDark,
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        // Built from the text theme so the title uses the app font.
        titleTextStyle: base.textTheme.titleLarge!.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        contentTextStyle: const TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        actionTextColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.12),
        hintStyle: const TextStyle(color: AppColors.muted),
        labelStyle: const TextStyle(color: AppColors.muted),
        floatingLabelStyle: const TextStyle(color: Colors.white),
        prefixIconColor: Colors.white,
        suffixIconColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: Colors.white, width: 1.6),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.white,
        selectionColor: Color(0x55FFFFFF),
        selectionHandleColor: Colors.white,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : Colors.white.withValues(alpha: 0.20),
        ),
        trackOutlineColor: WidgetStatePropertyAll(
          Colors.white.withValues(alpha: 0.5),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.18),
        thickness: 1,
        space: AppSpacing.lg,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.tintSnow,
        titleTextStyle: TextStyle(
          color: AppColors.primaryDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(color: Color(0xFF3B1414), fontSize: 14),
      ),
    );
  }

  /// Light theme: white is the main colour, red the accent.
  static ThemeData get light {
    const ink = Color(0xFF3D0A0A);
    const inkMuted = Color(0xFF6E3434);
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      surface: Colors.white,
      onSurface: ink,
      error: const Color(0xFFB3261E),
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.tile),
      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
    );
    return base.copyWith(
      scaffoldBackgroundColor: Colors.white,
      textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: base.textTheme.titleLarge!.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.tile)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.75),
        hintStyle: const TextStyle(color: inkMuted),
        labelStyle: const TextStyle(color: inkMuted),
        floatingLabelStyle: const TextStyle(color: AppColors.primary),
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withValues(alpha: 0.25),
        selectionHandleColor: AppColors.primary,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.primary.withValues(alpha: 0.14),
        thickness: 1,
        space: AppSpacing.lg,
      ),
    );
  }
}
