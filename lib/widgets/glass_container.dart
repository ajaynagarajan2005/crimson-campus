import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The core glassmorphism surface: a blurred, translucent white panel with a
/// soft border and shadow. Every card in the app is built on this Container.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.alignment,
    this.constraints,
    this.borderRadius = AppRadius.card,
    this.blur = 16,
    this.tint = 0.14,
    this.onTap,
    this.semanticLabel,
    this.colors,
    this.borderColor,
  });

  /// White-to-red "mixed" glass used on the landing page.
  static final List<Color> mixed = [
    Colors.white.withValues(alpha: 0.34),
    const Color(0xFFFF8A80).withValues(alpha: 0.20),
    AppColors.primary.withValues(alpha: 0.30),
  ];

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final AlignmentGeometry? alignment;
  final BoxConstraints? constraints;
  final double borderRadius;
  final double blur;

  /// White opacity of the glass (0 = clear, 1 = solid white).
  final double tint;
  final VoidCallback? onTap;
  final String? semanticLabel;

  /// Custom glass gradient; defaults to translucent white based on [tint].
  final List<Color>? colors;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    final light = Theme.of(context).brightness == Brightness.light;
    Widget surface = Container(
      width: width,
      height: height,
      padding: padding,
      alignment: alignment,
      constraints: constraints,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors ??
              (light
                  // Light theme: frosted white glass with a blush of red.
                  ? [
                      Colors.white.withValues(alpha: 0.82),
                      Colors.white.withValues(alpha: 0.62),
                      AppColors.tintBlush.withValues(alpha: 0.55),
                    ]
                  : [
                      Colors.white.withValues(alpha: tint + 0.08),
                      Colors.white.withValues(alpha: tint * 0.45),
                    ]),
        ),
        border: Border.all(
          color: borderColor ??
              (light ? AppColors.primary.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.30)),
          width: 1.2,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      surface = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: (light ? AppColors.primary : Colors.white).withValues(alpha: 0.14),
          highlightColor: (light ? AppColors.primary : Colors.white).withValues(alpha: 0.06),
          child: surface,
        ),
      );
    }

    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: surface,
          ),
        ),
      ),
    );
  }
}
