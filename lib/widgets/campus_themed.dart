import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/campus_palette.dart';
import 'glass_container.dart';

/// Applies the chosen light or dark theme to [child] and rebuilds on change.
class CampusThemed extends StatelessWidget {
  const CampusThemed({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppState.instance.themeMode,
      builder: (context, mode, _) => AnimatedTheme(
        data: mode == ThemeMode.light ? AppTheme.light : AppTheme.theme,
        child: child,
      ),
    );
  }
}

/// Glass sun / moon button that flips between light and dark.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    final dark = palette.isDark;
    return Tooltip(
      message: dark ? 'Switch to light theme' : 'Switch to dark theme',
      child: GlassContainer(
        width: 44,
        height: 44,
        padding: EdgeInsets.zero,
        borderRadius: 22,
        alignment: Alignment.center,
        colors: palette.glassStrong,
        borderColor: palette.glassBorder,
        semanticLabel: dark ? 'Switch to light theme' : 'Switch to dark theme',
        onTap: AppState.instance.toggleTheme,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) => RotationTransition(
            turns: Tween<double>(begin: 0.6, end: 1).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Icon(
            dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            key: ValueKey(dark),
            color: palette.isDark ? Colors.white : AppColors.primary,
            size: 22,
          ),
        ),
      ),
    );
  }
}
