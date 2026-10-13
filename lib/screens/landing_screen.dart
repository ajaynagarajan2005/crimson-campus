import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/student.dart';
import '../prototype/about_inti_variants.dart';
import '../prototype/prototype_switcher.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/campus_palette.dart';
import '../widgets/campus_themed.dart';
import '../widgets/common.dart';
import '../widgets/glass_container.dart';
import '../widgets/inti_logo.dart';
import '../widgets/landing_effects.dart';
import '../widgets/landing_info_sections.dart';
import '../widgets/login_form.dart';

const String campusPhoto = 'assets/images/inti_campus.jpg';

/// Scroll-driven landing page: the campus photo zooms in as you scroll,
/// glass panels flip in with 3D motion, the About INTI story plays out, and
/// the login form waits at the end. Follows the light / dark theme.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) => const CampusThemed(child: _Landing());
}

class _Landing extends StatefulWidget {
  const _Landing();

  @override
  State<_Landing> createState() => _LandingState();
}

class _LandingState extends State<_Landing> {
  final _scroll = ScrollController();
  final _loginKey = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToLogin() {
    final target = _loginKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeInOutCubic,
      alignment: 0.15,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    return ValueListenableBuilder<Student?>(
      valueListenable: AppState.instance.student,
      builder: (context, student, _) => Scaffold(
        backgroundColor: palette.backdrop.first,
        body: LayoutBuilder(
          builder: (context, box) {
            final heroHeight = box.maxHeight < 600 ? 600.0 : box.maxHeight;
            return Stack(
              children: [
                Positioned.fill(
                  child: _ZoomingCampus(scroll: _scroll, viewportHeight: box.maxHeight, palette: palette),
                ),
                Positioned.fill(
                  child: SingleChildScrollView(
                    controller: _scroll,
                    child: Column(
                      children: [
                        _Hero(height: heroHeight, scroll: _scroll, student: student, onLogin: _scrollToLogin),
                        ValueListenableBuilder<String>(
                          valueListenable: aboutVariant,
                          builder: (context, variant, _) => AboutIntiSection(variant: variant, scroll: _scroll),
                        ),
                        _CampusMapCta(scroll: _scroll),
                        CoursesSection(scroll: _scroll),
                        CareersSection(scroll: _scroll),
                        InternationalSection(scroll: _scroll),
                        CampusDetailsSection(scroll: _scroll),
                        _FeaturesSection(scroll: _scroll),
                        _PreviewSection(scroll: _scroll, width: box.maxWidth),
                        KeyedSubtree(
                          key: _loginKey,
                          child: _LoginSection(scroll: _scroll, student: student),
                        ),
                        const _Footer(),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _TopBar(scroll: _scroll, student: student, onLogin: _scrollToLogin),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 14,
                  child: SafeArea(
                    top: false,
                    child: Center(
                      child: PrototypeSwitcher(variants: aboutVariantNames, current: aboutVariant),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Text colour helpers for the current palette.
extension on CampusPalette {
  TextStyle tint(TextStyle style) => style.copyWith(color: text);
  TextStyle mute(TextStyle style) => style.copyWith(color: textMuted);
  Color get iconColor => isDark ? Colors.white : AppColors.primary;
  List<Shadow>? get shadow =>
      isDark ? const [Shadow(color: Color(0x66000000), blurRadius: 14, offset: Offset(0, 3))] : null;
}

// ---------------------------------------------------------------------------
// Background: the campus photo zooms in and fades into the theme colour.
// ---------------------------------------------------------------------------

class _ZoomingCampus extends StatelessWidget {
  const _ZoomingCampus({required this.scroll, required this.viewportHeight, required this.palette});

  final ScrollController scroll;
  final double viewportHeight;
  final CampusPalette palette;

  @override
  Widget build(BuildContext context) {
    final photo = Image.asset(
      campusPhoto,
      fit: BoxFit.cover,
      alignment: const Alignment(0, -0.25),
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );

    return AnimatedBuilder(
      animation: scroll,
      child: photo,
      builder: (context, photo) {
        final offset = scroll.hasClients ? scroll.offset : 0.0;
        final t = (offset / viewportHeight).clamp(0.0, 3.0);
        final hero = t.clamp(0.0, 1.0);
        final blur = 7.0 * hero;

        Widget image = Transform.scale(scale: 1.0 + 0.42 * t, alignment: const Alignment(0, -0.2), child: photo);
        if (blur > 0.2) {
          image = ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur, tileMode: TileMode.clamp),
            child: image,
          );
        }

        // Dark: crimson wash. Light: white wash with a hint of red.
        final wash = palette.isDark
            ? [
                AppColors.primaryDark.withValues(alpha: 0.12 + 0.60 * hero),
                AppColors.primary.withValues(alpha: 0.10 + 0.58 * hero),
                AppColors.primaryDark.withValues(alpha: 0.70 + 0.20 * hero),
              ]
            : [
                Colors.white.withValues(alpha: 0.05 + 0.80 * hero),
                Colors.white.withValues(alpha: 0.10 + 0.80 * hero),
                const Color(0xFFFFF1F1).withValues(alpha: 0.80 + 0.15 * hero),
              ];

        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(child: image),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: wash,
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
            // Mixed sheen: white on dark, a soft red glow on light.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: palette.isDark ? Alignment.topLeft : Alignment.bottomRight,
                  end: const Alignment(0.1, 0.1),
                  colors: [
                    (palette.isDark ? Colors.white : AppColors.accent)
                        .withValues(alpha: palette.isDark ? 0.20 * (1 - hero) : 0.10 + 0.12 * hero),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar: transparent over the photo, frosted once you scroll.
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar({required this.scroll, required this.student, required this.onLogin});

  final ScrollController scroll;
  final Student? student;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    return AnimatedBuilder(
      animation: scroll,
      builder: (context, _) {
        final offset = scroll.hasClients ? scroll.offset : 0.0;
        final frost = (offset / 140).clamp(0.0, 1.0);
        return ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 14 * frost, sigmaY: 14 * frost),
            child: Container(
              decoration: BoxDecoration(
                color: (palette.isDark ? AppColors.primaryDark : Colors.white)
                    .withValues(alpha: (palette.isDark ? 0.35 : 0.6) * frost),
                border: Border(bottom: BorderSide(color: palette.glassBorder.withValues(alpha: 0.5 * frost))),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                  child: Row(
                    children: [
                      const IntiLogo(height: 24),
                      const Spacer(),
                      const ThemeToggleButton(),
                      const SizedBox(width: 8),
                      if (student == null)
                        _TopBarButton(label: 'Log in', icon: Icons.login_rounded, onTap: onLogin)
                      else
                        _TopBarButton(
                          label: 'Dashboard',
                          icon: Icons.dashboard_rounded,
                          onTap: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TopBarButton extends StatelessWidget {
  const _TopBarButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    final fg = palette.isDark ? Colors.white : AppColors.primary;
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: fg,
        backgroundColor: palette.isDark ? Colors.white.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.85),
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: StadiumBorder(side: BorderSide(color: fg.withValues(alpha: 0.55))),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero: glass welcome card that zooms toward you and fades as you scroll.
// ---------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  const _Hero({required this.height, required this.scroll, required this.student, required this.onLogin});

  final double height;
  final ScrollController scroll;
  final Student? student;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    final card = Tilt3D(child: _HeroCard(student: student, onLogin: onLogin));
    return SizedBox(
      height: height,
      child: AnimatedBuilder(
        animation: scroll,
        child: card,
        builder: (context, card) {
          final offset = scroll.hasClients ? scroll.offset : 0.0;
          final p = (offset / height).clamp(0.0, 1.0);
          return Stack(
            children: [
              _FloatingChip(
                alignment: const Alignment(-0.88, -0.74),
                icon: Icons.calendar_month_rounded,
                label: 'Next class · 9:00 AM',
                offset: offset,
                depth: 0.9,
                tilt: -0.10,
              ),
              _FloatingChip(
                alignment: const Alignment(0.90, -0.56),
                icon: Icons.map_rounded,
                label: 'Live campus map',
                offset: offset,
                depth: 1.4,
                tilt: 0.12,
              ),
              _FloatingChip(
                alignment: const Alignment(-0.80, 0.66),
                icon: Icons.star_rounded,
                label: 'CGPA tracker',
                offset: offset,
                depth: 0.6,
                tilt: -0.06,
              ),
              Center(
                child: Opacity(
                  opacity: (1 - p * 2.2).clamp(0.0, 1.0),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: transform3d(rotateX: p * 0.55, dy: -p * 90, scale: 1 + p * 0.35),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 72, 20, 96),
                      // Scales the card down on very short screens instead of clipping it.
                      child: LayoutBuilder(
                        builder: (context, space) => FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(width: space.maxWidth < 520 ? space.maxWidth : 520, child: card),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 70),
                    child: Opacity(
                      opacity: (1 - p * 3).clamp(0.0, 1.0),
                      child: ScrollCue(onTap: onLogin, color: palette.isDark ? Colors.white : AppColors.primary),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.student, required this.onLogin});

  final Student? student;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    return GlassContainer(
      colors: palette.glass,
      borderColor: palette.glassBorder,
      blur: 22,
      borderRadius: 32,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StatusBadge(label: universityName, tone: BadgeTone.info),
          const SizedBox(height: 16),
          Text(
            'WELCOME TO',
            style: TextStyle(
              color: palette.text,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              fontSize: 12.5,
              shadows: palette.shadow,
            ),
          ),
          const SizedBox(height: 6),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: palette.isDark
                  ? const [Colors.white, AppColors.tintBlush, Colors.white]
                  : const [AppColors.primaryDark, AppColors.primary, Color(0xFFE53935)],
            ).createShader(bounds),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                appName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.05,
                  shadows: palette.shadow,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Classes, results, services and student life — '
            'your whole campus in one calm, clear place.',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.text, fontSize: 15.5, height: 1.5, shadows: palette.shadow),
          ),
          const SizedBox(height: 22),
          if (student == null)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                PillButton(label: 'Log in', icon: Icons.login_rounded, onPressed: onLogin),
                PillButton(
                  label: 'Create account',
                  icon: Icons.person_add_alt_1_rounded,
                  filled: false,
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                ),
              ],
            )
          else
            PillButton(
              label: 'Continue as ${student!.firstName}',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false),
            ),
        ],
      ),
    );
  }
}

class _FloatingChip extends StatelessWidget {
  const _FloatingChip({
    required this.alignment,
    required this.icon,
    required this.label,
    required this.offset,
    required this.depth,
    required this.tilt,
  });

  final Alignment alignment;
  final IconData icon;
  final String label;
  final double offset;
  final double depth;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Transform(
          alignment: Alignment.center,
          transform: transform3d(dy: -offset * depth * 0.45, rotateZ: tilt, rotateY: tilt * 2.5, scale: 0.9 + depth * 0.1),
          child: ExcludeSemantics(
            child: GlassContainer(
              colors: palette.glass,
              borderColor: palette.glassBorder,
              borderRadius: AppRadius.pill,
              padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconBubble(
                    icon: icon,
                    size: 28,
                    background: palette.isDark ? Colors.white : AppColors.primary,
                    iconColor: palette.isDark ? AppColors.primary : Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: palette.text, fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Campus map call-to-action
// ---------------------------------------------------------------------------

class _CampusMapCta extends StatelessWidget {
  const _CampusMapCta({required this.scroll});

  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: FlipInOnScroll(
            controller: scroll,
            child: Tilt3D(
              child: GlassContainer(
                colors: palette.glassStrong,
                borderColor: palette.glassBorder,
                semanticLabel: 'Open the live campus map',
                onTap: () => Navigator.pushNamed(context, AppRoutes.campusMap),
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    IconBubble(
                      icon: Icons.map_rounded,
                      size: 52,
                      background: palette.isDark ? Colors.white : AppColors.primary,
                      iconColor: palette.isDark ? AppColors.primary : Colors.white,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Find your way around', style: palette.tint(AppText.title)),
                          const SizedBox(height: 2),
                          Text(
                            'Live campus map with your location and walking directions to every building.',
                            style: palette.mute(AppText.caption),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, color: palette.iconColor),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section scaffolding
// ---------------------------------------------------------------------------

class _Section extends StatelessWidget {
  const _Section({required this.scroll, required this.eyebrow, required this.title, required this.children});

  final ScrollController scroll;
  final String eyebrow;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ScrollReveal(
                controller: scroll,
                child: Column(
                  children: [
                    Text(eyebrow.toUpperCase(), style: palette.mute(AppText.overline), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(title, style: palette.tint(AppText.h1), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                  ],
                ),
                builder: (context, p, child) => Opacity(
                  opacity: p,
                  child: Transform.translate(offset: Offset(0, (1 - p) * 30), child: child),
                ),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Features: cards that flip up in 3D as they arrive.
// ---------------------------------------------------------------------------

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection({required this.scroll});

  final ScrollController scroll;

  static const _features = [
    (Icons.insights_rounded, 'Academic snapshot', 'CGPA, credits and attendance the moment you open the app.'),
    (Icons.apps_rounded, 'Eight campus services', 'Timetable, results, fees, library, shuttle, clubs and more.'),
    (Icons.celebration_rounded, 'Student life', 'Register for events and join clubs in a single tap.'),
    (Icons.verified_user_rounded, 'Your own account', 'Everything you do is saved securely to your profile.'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    return _Section(
      scroll: scroll,
      eyebrow: 'Why Crimson Campus',
      title: 'Your campus, one tap away',
      children: [
        for (final (icon, title, body) in _features)
          FlipInOnScroll(
            controller: scroll,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Tilt3D(
                child: GlassContainer(
                  colors: palette.glass,
                  borderColor: palette.glassBorder,
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      _Icon3D(icon: icon),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: palette.tint(AppText.title)),
                            const SizedBox(height: 2),
                            Text(body, style: palette.tint(AppText.caption)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Icon on a layered "3D" tile: a dark base offset under a light face.
class _Icon3D extends StatelessWidget {
  const _Icon3D({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    return SizedBox(
      width: 56,
      height: 58,
      child: Stack(
        children: [
          Positioned(
            left: 4,
            top: 6,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: palette.isDark ? AppColors.primaryDark : const Color(0xFF8E1212),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette.isDark
                    ? const [Colors.white, AppColors.tintBlush]
                    : const [Color(0xFFE53935), AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Icon(icon, color: palette.isDark ? AppColors.primary : Colors.white, size: 26),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preview: a fanned 3D stack of app "screens" that opens as you scroll.
// ---------------------------------------------------------------------------

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({required this.scroll, required this.width});

  final ScrollController scroll;
  final double width;

  @override
  Widget build(BuildContext context) {
    final spread = (width * 0.31).clamp(80.0, 160.0);
    return _Section(
      scroll: scroll,
      eyebrow: 'A look inside',
      title: 'Built around your day',
      children: [
        ScrollReveal(
          controller: scroll,
          distance: 0.6,
          child: const SizedBox.shrink(),
          builder: (context, p, _) => SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Transform(
                  alignment: Alignment.center,
                  transform: transform3d(dx: -spread * p, dy: 12, rotateY: 0.6 * p, rotateZ: -0.05 * p, scale: 0.86),
                  child: const _MiniScreen(
                    icon: Icons.calendar_month_rounded,
                    eyebrow: 'Next class',
                    value: '9:00 AM',
                    caption: 'CS301 Data Structures\nBlock C-204',
                  ),
                ),
                Transform(
                  alignment: Alignment.center,
                  transform: transform3d(dx: spread * p, dy: 12, rotateY: -0.6 * p, rotateZ: 0.05 * p, scale: 0.86),
                  child: const _MiniScreen(
                    icon: Icons.map_rounded,
                    eyebrow: 'Campus map',
                    value: '3 min',
                    caption: 'Walk to Block A\nhead north-east',
                  ),
                ),
                Transform(
                  alignment: Alignment.center,
                  transform: transform3d(rotateX: (1 - p) * 0.5, dy: (1 - p) * 30, scale: 0.92 + 0.08 * p),
                  child: const _MiniScreen(
                    icon: Icons.star_rounded,
                    eyebrow: 'Academic snapshot',
                    value: 'CGPA',
                    caption: 'Credits, attendance\nand semester progress',
                    highlight: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        ScrollReveal(
          controller: scroll,
          child: const Row(
            children: [
              Expanded(child: _Stat(value: '8', label: 'Services')),
              SizedBox(width: 12),
              Expanded(child: _Stat(value: '24/7', label: 'Helpdesk')),
              SizedBox(width: 12),
              Expanded(child: _Stat(value: 'Live', label: 'Campus map')),
            ],
          ),
          builder: (context, p, child) => Opacity(
            opacity: p,
            child: Transform.scale(scale: 0.8 + 0.2 * p, child: child),
          ),
        ),
      ],
    );
  }
}

class _MiniScreen extends StatelessWidget {
  const _MiniScreen({
    required this.icon,
    required this.eyebrow,
    required this.value,
    required this.caption,
    this.highlight = false,
  });

  final IconData icon;
  final String eyebrow;
  final String value;
  final String caption;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    return GlassContainer(
      width: 190,
      colors: highlight ? palette.glassStrong : palette.glass,
      borderColor: palette.glassBorder,
      borderRadius: 28,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBubble(
            icon: icon,
            size: 44,
            background: palette.isDark ? Colors.white : AppColors.primary,
            iconColor: palette.isDark ? AppColors.primary : Colors.white,
          ),
          const SizedBox(height: 36),
          Text(
            eyebrow.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: palette.mute(AppText.overline).copyWith(fontSize: 10.5),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: palette.isDark ? Colors.white : AppColors.primary,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(caption, maxLines: 2, overflow: TextOverflow.ellipsis, style: palette.tint(AppText.caption)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    return GlassContainer(
      colors: palette.glass,
      borderColor: palette.glassBorder,
      padding: const EdgeInsets.symmetric(vertical: 16),
      borderRadius: AppRadius.tile,
      child: Column(
        children: [
          Text(
            value,
            style: AppText.h2.copyWith(color: palette.isDark ? Colors.white : AppColors.primary),
          ),
          Text(label, style: palette.tint(AppText.caption), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Login: the glass card zooms in as it reaches the middle of the screen.
// ---------------------------------------------------------------------------

class _LoginSection extends StatelessWidget {
  const _LoginSection({required this.scroll, required this.student});

  final ScrollController scroll;
  final Student? student;

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    final linkColor = palette.isDark ? Colors.white : AppColors.primary;
    final card = GlassContainer(
      colors: palette.glassStrong,
      borderColor: palette.glassBorder,
      blur: 22,
      borderRadius: 32,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: IntiLogo(height: 44)),
          const SizedBox(height: 18),
          Text(
            student == null ? 'Log in to your campus' : 'Welcome back, ${student!.firstName}',
            style: palette.tint(AppText.h2),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            student == null
                ? 'Use your student email or ID and password.'
                : 'You are already logged in on this device.',
            style: palette.tint(AppText.body),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (student == null) ...[
            const LoginForm(),
            const SizedBox(height: 6),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('New to Crimson Campus?', style: palette.tint(AppText.body)),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                  style: TextButton.styleFrom(foregroundColor: linkColor, minimumSize: const Size(48, 48)),
                  child: const Text(
                    'Create an account',
                    style: TextStyle(fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ] else ...[
            PillButton(
              label: 'Continue as ${student!.firstName}',
              icon: Icons.arrow_forward_rounded,
              expand: true,
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false),
            ),
            TextButton(
              onPressed: () => AppState.instance.logout(),
              style: TextButton.styleFrom(foregroundColor: linkColor, minimumSize: const Size(48, 48)),
              child: const Text('Not you? Log out'),
            ),
          ],
        ],
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
          child: ScrollReveal(
            controller: scroll,
            distance: 0.7,
            child: card,
            builder: (context, p, child) => Opacity(
              opacity: 0.25 + 0.75 * p,
              child: Transform(
                alignment: Alignment.center,
                transform: transform3d(scale: 0.78 + 0.22 * p, rotateX: (1 - p) * 0.4),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
        child: Column(
          children: [
            Text(
              '$appName · a student app for $universityName',
              textAlign: TextAlign.center,
              style: palette.mute(AppText.caption),
            ),
            const SizedBox(height: 6),
            Text(
              'Facts: Wikipedia, INTI factsheets and “Why INTI” page, QS TopUniversities. '
              'Map data © OpenStreetMap contributors.',
              textAlign: TextAlign.center,
              style: palette.mute(AppText.caption).copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
