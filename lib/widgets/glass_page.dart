import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Red gradient backdrop with soft glowing blobs. The blobs give the
/// frosted glass panels something to blur, which sells the glass effect.
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return Container(
      decoration: BoxDecoration(
        gradient: light
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFFFF3F3), Color(0xFFFFE2E2)],
              )
            : AppColors.background,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _GlowBlob(
              size: 280,
              color: AppColors.accent.withValues(alpha: light ? 0.28 : 0.55),
            ),
          ),
          Positioned(
            top: 280,
            left: -110,
            child: _GlowBlob(
              size: 260,
              color: light ? AppColors.primary.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: _GlowBlob(
              size: 300,
              color: const Color(0xFFFF4D4D).withValues(alpha: light ? 0.22 : 0.50),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

/// Standard page frame: Scaffold + gradient + SafeArea + scrollable column,
/// width-capped so it stays tidy on tablets and the web.
class GlassPage extends StatelessWidget {
  const GlassPage({
    super.key,
    required this.children,
    this.title,
    this.actions,
  });

  final String? title;
  final List<Widget> children;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: title == null
          ? null
          : AppBar(title: Text(title!), actions: actions),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
