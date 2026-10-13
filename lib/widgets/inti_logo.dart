import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The INTI logo (transparent PNG) on a light frosted panel. The logo's red
/// and black artwork needs a light surface to stay visible on the red theme.
class IntiLogo extends StatelessWidget {
  const IntiLogo({super.key, this.height = 44, this.padding});

  /// Height of the logo artwork itself.
  final double height;
  final EdgeInsetsGeometry? padding;

  static const String asset = 'assets/images/inti_logo.png';

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height * 0.45);
    return Semantics(
      image: true,
      label: 'INTI logo',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: padding ??
                  EdgeInsets.symmetric(horizontal: height * 0.45, vertical: height * 0.28),
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.96),
                    AppColors.tintSnow.withValues(alpha: 0.86),
                  ],
                ),
                border: Border.all(color: Colors.white, width: 1.4),
              ),
              child: Image.asset(
                asset,
                height: height,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
