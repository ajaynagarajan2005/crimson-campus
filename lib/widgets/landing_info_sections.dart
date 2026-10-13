import 'package:flutter/material.dart';

import '../data/campus_info.dart';
import '../routes.dart';
import '../theme/app_theme.dart';
import '../theme/campus_palette.dart';
import 'common.dart';
import 'glass_container.dart';
import 'landing_effects.dart';

/// Landing-page sections about studying at INTI Nilai: courses, careers,
/// the international community and the campus itself. All follow the
/// light / dark palette and animate as they scroll in.

class _Heading extends StatelessWidget {
  const _Heading({required this.scroll, required this.eyebrow, required this.title, this.subtitle});

  final ScrollController scroll;
  final String eyebrow;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    return ScrollReveal(
      controller: scroll,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
        child: Column(
          children: [
            Text(eyebrow.toUpperCase(), style: AppText.overline.copyWith(color: palette.textMuted)),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: AppText.h1.copyWith(color: palette.text)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, textAlign: TextAlign.center, style: AppText.body.copyWith(color: palette.textMuted)),
            ],
          ],
        ),
      ),
      builder: (context, p, child) => Opacity(
        opacity: p,
        child: Transform.translate(offset: Offset(0, (1 - p) * 30), child: child),
      ),
    );
  }
}

Color _accentOn(CampusPalette palette) => palette.isDark ? Colors.white : AppColors.primary;

Widget _iconTile(CampusPalette palette, IconData icon, {double size = 44}) => IconBubble(
      icon: icon,
      size: size,
      background: palette.isDark ? Colors.white : AppColors.primary,
      iconColor: palette.isDark ? AppColors.primary : Colors.white,
    );

Widget _constrained(Widget child, {double maxWidth = 760}) => Center(
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
    );

// ---------------------------------------------------------------------------
// Courses: a sideways-scrolling row of faculty cards that slide in.
// ---------------------------------------------------------------------------

class CoursesSection extends StatelessWidget {
  const CoursesSection({super.key, required this.scroll});

  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    return Column(
      children: [
        _Heading(
          scroll: scroll,
          eyebrow: 'Study at INTI',
          title: 'Courses and faculties',
          subtitle: 'Five faculties at the Nilai campus, from business and computing to engineering and health.',
        ),
        ScrollReveal(
          controller: scroll,
          child: SizedBox(
            height: 270,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: intiFaculties.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, i) => _FacultyCard(faculty: intiFaculties[i], index: i),
            ),
          ),
          builder: (context, p, child) => Opacity(
            opacity: p,
            child: Transform.translate(offset: Offset((1 - p) * 120, 0), child: child),
          ),
        ),
        const SizedBox(height: 16),
        _constrained(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FlipInOnScroll(
              controller: scroll,
              child: GlassContainer(
                colors: palette.glass,
                borderColor: palette.glassBorder,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _iconTile(palette, Icons.workspace_premium_rounded, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Postgraduate study', style: AppText.title.copyWith(color: palette.text)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final programme in intiPostgraduate)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: _accentOn(palette).withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(color: _accentOn(palette).withValues(alpha: 0.35)),
                            ),
                            child: Text(
                              programme,
                              style: TextStyle(color: palette.text, fontWeight: FontWeight.w600, fontSize: 12.5),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Programme list from INTI’s 2026–27 factsheets. See newinti.edu.my for the full, current catalogue.',
                      style: AppText.caption.copyWith(color: palette.textMuted, fontSize: 11.5),
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

class _FacultyCard extends StatelessWidget {
  const _FacultyCard({required this.faculty, required this.index});

  final Faculty faculty;
  final int index;

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    return Tilt3D(
      child: GlassContainer(
        width: 240,
        colors: index.isEven ? palette.glass : palette.glassStrong,
        borderColor: palette.glassBorder,
        borderRadius: 28,
        padding: const EdgeInsets.all(18),
        alignment: Alignment.topLeft,
        // Shrinks the content rather than overflowing when text wraps a lot.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 202,
            child: _facultyContent(palette),
          ),
        ),
      ),
    );
  }

  Widget _facultyContent(CampusPalette palette) {
    return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _iconTile(palette, faculty.icon, size: 46),
                const Spacer(),
                Text(
                  '0${index + 1}',
                  style: TextStyle(
                    color: _accentOn(palette).withValues(alpha: 0.35),
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              faculty.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.title.copyWith(color: palette.text),
            ),
            const SizedBox(height: 10),
            for (final programme in faculty.programmes.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, size: 6, color: _accentOn(palette)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        programme,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption.copyWith(color: palette.text),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
  }
}

// ---------------------------------------------------------------------------
// Careers: a big stat that zooms in, then the career services list.
// ---------------------------------------------------------------------------

class CareersSection extends StatelessWidget {
  const CareersSection({super.key, required this.scroll});

  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    final (value, label, source) = intiEmployability;
    return _constrained(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Heading(
              scroll: scroll,
              eyebrow: 'Careers',
              title: 'Ready for work',
              subtitle: 'INTI’s Career Services Centre supports students from first year to first job.',
            ),
            ScrollReveal(
              controller: scroll,
              child: GlassContainer(
                colors: palette.glassStrong,
                borderColor: palette.glassBorder,
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: _accentOn(palette),
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: AppText.title.copyWith(color: palette.text)),
                          const SizedBox(height: 4),
                          Text(source, style: AppText.caption.copyWith(color: palette.textMuted, fontSize: 11.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              builder: (context, p, child) => Opacity(
                opacity: p,
                child: Transform(
                  alignment: Alignment.center,
                  transform: transform3d(scale: 0.7 + 0.3 * p, rotateX: (1 - p) * 0.6),
                  child: child,
                ),
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, box) {
                final columns = box.maxWidth >= 560 ? 2 : 1;
                final width = (box.maxWidth - 12 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final (icon, title, body) in intiCareerServices)
                      SizedBox(
                        width: width,
                        child: FlipInOnScroll(
                          controller: scroll,
                          child: GlassContainer(
                            colors: palette.glass,
                            borderColor: palette.glassBorder,
                            child: Row(
                              children: [
                                _iconTile(palette, icon, size: 42),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(title, style: AppText.title.copyWith(color: palette.text)),
                                      Text(body, style: AppText.caption.copyWith(color: palette.text)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// International: a photo that zooms in as you scroll, with a glass stat.
// ---------------------------------------------------------------------------

class InternationalSection extends StatelessWidget {
  const InternationalSection({super.key, required this.scroll});

  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    final (value, label, source) = intiInternational;
    return _constrained(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Heading(
              scroll: scroll,
              eyebrow: 'International community',
              title: 'Study with the world',
              subtitle: 'Malaysian and international students learn side by side, with exchange students joining each intake.',
            ),
            ScrollMetricsBuilder(
              controller: scroll,
              builder: (context, m) {
                final t = m.passThrough;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: SizedBox(
                    height: 380,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Transform.scale(
                          scale: 1.0 + 0.5 * t,
                          child: Image.asset('assets/images/inti_atrium.jpg', fit: BoxFit.cover),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                palette.photoTint.withValues(alpha: 0),
                                palette.photoTint.withValues(alpha: palette.isDark ? 0.6 : 0.4),
                              ],
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: LayoutBuilder(
                              builder: (context, box) => FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.bottomCenter,
                                child: SizedBox(
                                  width: box.maxWidth,
                                  child: GlassContainer(
                                    colors: palette.glassStrong,
                                    borderColor: palette.glassBorder,
                                    child: Row(
                                      children: [
                                        Text(
                                          value,
                                          style: TextStyle(
                                            color: _accentOn(palette),
                                            fontSize: 44,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(label, style: AppText.title.copyWith(color: palette.text)),
                                              Text(
                                                source,
                                                style: AppText.caption.copyWith(
                                                  color: palette.textMuted,
                                                  fontSize: 11.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Campus details: tiles that flip in, plus a link to the live map.
// ---------------------------------------------------------------------------

class CampusDetailsSection extends StatelessWidget {
  const CampusDetailsSection({super.key, required this.scroll});

  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    return _constrained(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Heading(
              scroll: scroll,
              eyebrow: 'On campus',
              title: 'Around the Nilai campus',
              subtitle: intiAddress,
            ),
            LayoutBuilder(
              builder: (context, box) {
                final columns = box.maxWidth >= 560 ? 3 : 2;
                final width = (box.maxWidth - 12 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final (icon, title, body) in intiCampusHighlights)
                      SizedBox(
                        width: width,
                        child: FlipInOnScroll(
                          controller: scroll,
                          child: GlassContainer(
                            constraints: const BoxConstraints(minHeight: 150),
                            colors: palette.glass,
                            borderColor: palette.glassBorder,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _iconTile(palette, icon, size: 40),
                                const SizedBox(height: 12),
                                Text(title, style: AppText.title.copyWith(color: palette.text)),
                                const SizedBox(height: 2),
                                Text(body, style: AppText.caption.copyWith(color: palette.text)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            PillButton(
              label: 'Open the live campus map',
              icon: Icons.near_me_rounded,
              expand: true,
              onPressed: () => Navigator.pushNamed(context, AppRoutes.campusMap),
            ),
          ],
        ),
      ),
    );
  }
}
