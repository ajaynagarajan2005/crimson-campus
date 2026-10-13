// PROTOTYPE: three layouts for the "About INTI University, Nilai" section on
// the landing page, switchable with ?variant=A|B|C and the floating bar.
// Pick one, fold it into landing_screen.dart properly, then delete this file.

import 'package:flutter/material.dart';

import '../data/campus_info.dart';
import '../theme/app_theme.dart';
import '../theme/campus_palette.dart';
import '../widgets/glass_container.dart';
import '../widgets/landing_effects.dart';

const Map<String, String> aboutVariantNames = {
  'A': 'Zoom reel',
  'B': 'Split story',
  'C': 'Pinned deck',
};

/// Renders the chosen variant.
class AboutIntiSection extends StatelessWidget {
  const AboutIntiSection({super.key, required this.variant, required this.scroll});

  final String variant;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      'B' => AboutVariantB(scroll: scroll),
      'C' => AboutVariantC(scroll: scroll),
      _ => AboutVariantA(scroll: scroll),
    };
  }
}

/// Shared heading (the variants differ in layout, not in what they say).
class _AboutHeading extends StatelessWidget {
  const _AboutHeading();

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      child: Column(
        children: [
          Text('ABOUT THE UNIVERSITY', style: AppText.overline.copyWith(color: palette.textMuted)),
          const SizedBox(height: 8),
          Text(
            'INTI International University, Nilai',
            textAlign: TextAlign.center,
            style: AppText.h1.copyWith(color: palette.text),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.place_rounded, size: 18, color: palette.isDark ? Colors.white : AppColors.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  intiAddress,
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(color: palette.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Glass caption used on top of photos.
class _Caption extends StatelessWidget {
  const _Caption({required this.slide, this.strong = false});

  final AboutSlide slide;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    return GlassContainer(
      colors: strong ? palette.glassStrong : palette.glass,
      borderColor: palette.glassBorder,
      blur: 18,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(slide.eyebrow.toUpperCase(), style: AppText.overline.copyWith(color: palette.textMuted)),
          const SizedBox(height: 4),
          Text(slide.title, style: AppText.h2.copyWith(color: palette.text)),
          const SizedBox(height: 6),
          Text(slide.body, style: AppText.body.copyWith(color: palette.text)),
        ],
      ),
    );
  }
}

/// Caption that shrinks to fit when the photo frame is short.
class _FitCaption extends StatelessWidget {
  const _FitCaption({required this.slide});

  final AboutSlide slide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.bottomCenter,
        child: SizedBox(width: box.maxWidth, child: _Caption(slide: slide)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// A · Zoom reel: full-width photos that zoom in as they pass through the
// screen, with a glass caption rising over the bottom of each.
// ---------------------------------------------------------------------------

class AboutVariantA extends StatelessWidget {
  const AboutVariantA({super.key, required this.scroll});

  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    final frameHeight = (MediaQuery.sizeOf(context).height * 0.62).clamp(340.0, 520.0);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            const _AboutHeading(),
            for (final slide in aboutSlides)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                child: ScrollMetricsBuilder(
                  controller: scroll,
                  builder: (context, m) {
                    final t = m.passThrough;
                    final zoom = 1.0 + 0.55 * t;
                    final caption = ((t - 0.12) / 0.3).clamp(0.0, 1.0);
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: SizedBox(
                        height: frameHeight,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Transform.scale(
                              scale: zoom,
                              child: Image.asset(slide.image, fit: BoxFit.cover),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    palette.photoTint.withValues(alpha: 0),
                                    palette.photoTint.withValues(alpha: palette.isDark ? 0.55 : 0.35),
                                  ],
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Opacity(
                                  opacity: caption,
                                  child: Transform.translate(
                                    offset: Offset(0, (1 - caption) * 50),
                                    child: _FitCaption(slide: slide),
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
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// B · Split story: fact tiles first, then alternating photo + glass text
// (stacked on phones, side by side on wide screens). Photos slowly zoom and
// pan as you scroll (Ken Burns).
// ---------------------------------------------------------------------------

class AboutVariantB extends StatelessWidget {
  const AboutVariantB({super.key, required this.scroll});

  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          children: [
            const _AboutHeading(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LayoutBuilder(
                builder: (context, box) {
                  final columns = box.maxWidth >= 640 ? 4 : 2;
                  final width = (box.maxWidth - 12 * (columns - 1)) / columns;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final (value, label) in intiFacts)
                        SizedBox(
                          width: width,
                          child: FlipInOnScroll(
                            controller: scroll,
                            child: GlassContainer(
                              colors: palette.glass,
                              borderColor: palette.glassBorder,
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                              child: Column(
                                children: [
                                  Text(
                                    value,
                                    style: TextStyle(
                                      color: palette.isDark ? Colors.white : AppColors.primary,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    style: AppText.caption.copyWith(color: palette.text),
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
            ),
            const SizedBox(height: 28),
            for (var i = 0; i < aboutSlides.length; i++)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 34),
                child: LayoutBuilder(
                  builder: (context, box) {
                    final wide = box.maxWidth >= 700;
                    final photo = _KenBurnsPhoto(
                      scroll: scroll,
                      image: aboutSlides[i].image,
                      height: wide ? 320 : 240,
                      panRight: i.isEven,
                    );
                    final text = FlipInOnScroll(controller: scroll, child: _Caption(slide: aboutSlides[i], strong: true));
                    if (wide) {
                      final children = [
                        Expanded(flex: 6, child: photo),
                        const SizedBox(width: 20),
                        Expanded(flex: 5, child: text),
                      ];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: i.isEven ? children : children.reversed.toList(),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        photo,
                        Transform.translate(
                          offset: Offset(i.isEven ? 14 : -14, -40),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: text,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KenBurnsPhoto extends StatelessWidget {
  const _KenBurnsPhoto({
    required this.scroll,
    required this.image,
    required this.height,
    required this.panRight,
  });

  final ScrollController scroll;
  final String image;
  final double height;
  final bool panRight;

  @override
  Widget build(BuildContext context) {
    return ScrollMetricsBuilder(
      controller: scroll,
      builder: (context, m) {
        final t = m.passThrough;
        return ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: SizedBox(
            height: height,
            child: Transform.translate(
              offset: Offset((panRight ? 1 : -1) * (t - 0.5) * 30, 0),
              child: Transform.scale(
                scale: 1.08 + 0.32 * t,
                child: Image.asset(image, fit: BoxFit.cover, width: double.infinity, height: height),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// C · Pinned deck: the section pins to the screen while you scroll; each
// photo zooms toward you and fades as the next one rises up in 3D.
// ---------------------------------------------------------------------------

class AboutVariantC extends StatelessWidget {
  const AboutVariantC({super.key, required this.scroll});

  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final count = aboutSlides.length;
    return Column(
      children: [
        const _AboutHeading(),
        ScrollMetricsBuilder(
          controller: scroll,
          builder: (context, m) {
            final viewport = m.viewport;
            final total = viewport * (count + 0.4);
            final travel = total - viewport;
            final pinned = (-m.top).clamp(0.0, travel);
            final position = (pinned / travel) * (count - 1);
            return SizedBox(
              height: total,
              child: Stack(
                children: [
                  Positioned(
                    top: pinned,
                    left: 0,
                    right: 0,
                    height: viewport,
                    child: _Deck(position: position, viewport: viewport),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Deck extends StatelessWidget {
  const _Deck({required this.position, required this.viewport});

  final double position;
  final double viewport;

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    // Paint arriving cards first, the leaving card last (on top).
    final order = List.generate(aboutSlides.length, (i) => i)
      ..sort((a, b) => (b - position).compareTo(a - position));

    return Stack(
      children: [
        for (final i in order)
          if ((i - position) > -1 && (i - position) < 1.2)
            Positioned.fill(child: _DeckCard(slide: aboutSlides[i], offset: i - position, viewport: viewport)),
        // Progress dots
        Positioned(
          right: 10,
          top: 0,
          bottom: 0,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < aboutSlides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    width: 8,
                    height: (position.round() == i) ? 26 : 8,
                    decoration: BoxDecoration(
                      color: palette.isDark ? Colors.white : AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DeckCard extends StatelessWidget {
  const _DeckCard({required this.slide, required this.offset, required this.viewport});

  final AboutSlide slide;

  /// <0 leaving (zooming toward you), 0 current, >0 arriving from below.
  final double offset;
  final double viewport;

  @override
  Widget build(BuildContext context) {
    final palette = CampusPalette.of(context);
    final leaving = offset < 0 ? -offset : 0.0;
    final arriving = offset > 0 ? offset : 0.0;
    return Opacity(
      opacity: (1 - leaving).clamp(0.0, 1.0),
      child: Transform(
        alignment: Alignment.center,
        transform: transform3d(
          scale: (1 + leaving * 0.45) * (1 - arriving * 0.08),
          dy: arriving * viewport * 0.85,
          rotateX: arriving * 0.45,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 76, 30, 96),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Transform.scale(
                  scale: 1.05 + 0.25 * leaving,
                  child: Image.asset(slide.image, fit: BoxFit.cover),
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
                  child: Padding(padding: const EdgeInsets.all(14), child: _FitCaption(slide: slide)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
