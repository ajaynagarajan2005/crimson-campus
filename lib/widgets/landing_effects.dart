import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Global switch for continuous ambient animation (the bouncing scroll cue).
/// Tests turn it off so frames can settle.
class LandingMotion {
  LandingMotion._();

  static bool enabled = true;

  /// True when ambient motion should run in this context.
  static bool of(BuildContext context) =>
      enabled && !MediaQuery.of(context).disableAnimations;
}

/// Builds a 3D transform: perspective, then move, rotate and scale.
Matrix4 transform3d({
  double rotateX = 0,
  double rotateY = 0,
  double rotateZ = 0,
  double dx = 0,
  double dy = 0,
  double scale = 1,
  double perspective = 0.0012,
}) {
  return Matrix4.identity()
    ..setEntry(3, 2, perspective)
    ..multiply(Matrix4.translationValues(dx, dy, 0))
    ..multiply(Matrix4.rotationX(rotateX))
    ..multiply(Matrix4.rotationY(rotateY))
    ..multiply(Matrix4.rotationZ(rotateZ))
    ..multiply(Matrix4.diagonal3Values(scale, scale, 1));
}

/// Reports how far its child has scrolled into view (0 = just below the
/// screen, 1 = comfortably on screen) so the child can animate with scroll.
class ScrollReveal extends StatefulWidget {
  const ScrollReveal({
    super.key,
    required this.controller,
    required this.builder,
    required this.child,
    this.distance = 0.45,
  });

  final ScrollController controller;
  final Widget Function(BuildContext context, double progress, Widget child) builder;
  final Widget child;

  /// Fraction of the screen height over which the reveal plays.
  final double distance;

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal> {
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void didUpdateWidget(ScrollReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_update);
      widget.controller.addListener(_update);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final viewport = MediaQuery.sizeOf(context).height;
    final top = box.localToGlobal(Offset.zero).dy;
    final progress = ((viewport - top) / (viewport * widget.distance)).clamp(0.0, 1.0);
    if ((progress - _progress).abs() > 0.002) setState(() => _progress = progress);
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, Curves.easeOutCubic.transform(_progress), widget.child);
}

/// Card flips up in 3D and fades in as it scrolls into view.
class FlipInOnScroll extends StatelessWidget {
  const FlipInOnScroll({super.key, required this.controller, required this.child});

  final ScrollController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ScrollReveal(
      controller: controller,
      child: child,
      builder: (context, p, child) => Opacity(
        opacity: p,
        child: Transform(
          alignment: Alignment.bottomCenter,
          transform: transform3d(rotateX: (1 - p) * 1.1, dy: (1 - p) * 40, scale: 0.86 + 0.14 * p),
          child: child,
        ),
      ),
    );
  }
}

/// Tilts its child towards the mouse pointer (desktop / web) for a 3D feel.
class Tilt3D extends StatefulWidget {
  const Tilt3D({super.key, required this.child, this.maxTilt = 0.14});

  final Widget child;
  final double maxTilt;

  @override
  State<Tilt3D> createState() => _Tilt3DState();
}

class _Tilt3DState extends State<Tilt3D> {
  Offset _tilt = Offset.zero;

  void _onHover(PointerHoverEvent event) {
    final size = context.size;
    if (size == null || size.isEmpty) return;
    setState(() {
      _tilt = Offset(
        (event.localPosition.dx / size.width - 0.5) * 2,
        (event.localPosition.dy / size.height - 0.5) * 2,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: _onHover,
      onExit: (_) => setState(() => _tilt = Offset.zero),
      child: TweenAnimationBuilder<Offset>(
        tween: Tween<Offset>(end: _tilt),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: widget.child,
        builder: (context, tilt, child) => Transform(
          alignment: Alignment.center,
          transform: transform3d(
            rotateX: -tilt.dy * widget.maxTilt,
            rotateY: tilt.dx * widget.maxTilt,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// "Scroll to explore" hint with a gently bouncing chevron.
class ScrollCue extends StatefulWidget {
  const ScrollCue({super.key, this.onTap, this.color = Colors.white});

  final VoidCallback? onTap;
  final Color color;

  @override
  State<ScrollCue> createState() => _ScrollCueState();
}

class _ScrollCueState extends State<ScrollCue> with SingleTickerProviderStateMixin {
  late final AnimationController _bounce =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (LandingMotion.of(context)) {
      if (!_bounce.isAnimating) _bounce.repeat(reverse: true);
    } else {
      _bounce.stop();
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Scroll down to log in',
      excludeSemantics: true,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Scroll to explore', style: AppText.overline.copyWith(color: widget.color)),
              AnimatedBuilder(
                animation: _bounce,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, Curves.easeInOut.transform(_bounce.value) * 8),
                  child: child,
                ),
                child: Icon(Icons.keyboard_double_arrow_down_rounded, color: widget.color, size: 30),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Where a widget sits relative to the screen while the page scrolls.
class ViewMetrics {
  const ViewMetrics({required this.top, required this.height, required this.viewport});

  /// Distance from the top of the screen to the top of the widget.
  final double top;
  final double height;
  final double viewport;

  /// 0 when the widget's top enters at the bottom of the screen,
  /// 1 when its bottom leaves at the top.
  double get passThrough => ((viewport - top) / (viewport + height)).clamp(0.0, 1.0);
}

/// Rebuilds with fresh [ViewMetrics] on every scroll.
class ScrollMetricsBuilder extends StatefulWidget {
  const ScrollMetricsBuilder({super.key, required this.controller, required this.builder});

  final ScrollController controller;
  final Widget Function(BuildContext context, ViewMetrics metrics) builder;

  @override
  State<ScrollMetricsBuilder> createState() => _ScrollMetricsBuilderState();
}

class _ScrollMetricsBuilderState extends State<ScrollMetricsBuilder> {
  ViewMetrics? _metrics;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void didUpdateWidget(ScrollMetricsBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_update);
      widget.controller.addListener(_update);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  void _update() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final next = ViewMetrics(
      top: box.localToGlobal(Offset.zero).dy,
      height: box.size.height,
      viewport: MediaQuery.sizeOf(context).height,
    );
    final old = _metrics;
    if (old == null || (old.top - next.top).abs() > 0.5 || old.viewport != next.viewport || old.height != next.height) {
      setState(() => _metrics = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context).height;
    return widget.builder(
      context,
      _metrics ?? ViewMetrics(top: viewport, height: 0, viewport: viewport),
    );
  }
}
