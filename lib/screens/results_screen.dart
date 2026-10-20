import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_page.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final student = AppState.instance.student.value;
    if (student == null) return const SizedBox.shrink();
    final latestGpa = gpaHistory.last;
    final deansList = (student.cgpa ?? 0) >= 3.5;
    return GlassPage(
      title: 'Results',
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(20),
          tint: 0.18,
          child: Row(
            children: [
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.selectedBg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      student.cgpaLabel,
                      style: TextStyle(
                        color: context.selectedFg,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'CGPA',
                      style: TextStyle(
                        color: context.selectedFg,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusBadge(
                      label: deansList ? "Dean's list" : 'Keep going',
                      tone: deansList ? BadgeTone.success : BadgeTone.light,
                    ),
                    const SizedBox(height: 8),
                    Text('Last semester GPA: ${latestGpa.toStringAsFixed(2)}', style: AppText.title),
                    Text(
                      '${student.creditsEarned} credits earned · '
                      'semester ${student.semester} of ${student.totalSemesters}',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'GPA by semester', icon: Icons.bar_chart_rounded),
        GlassContainer(
          height: 210,
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 20, AppSpacing.md, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < gpaHistory.length; i++)
                Expanded(
                  child: _GpaBar(
                    label: 'Sem ${i + 1}',
                    gpa: gpaHistory[i],
                    highlight: i == gpaHistory.length - 1,
                  ),
                ),
            ],
          ),
        ),
        const SectionHeader(title: 'Last semester grades', icon: Icons.grading_rounded),
        for (final result in latestResults) _ResultTile(result: result),
      ],
    );
  }
}

class _GpaBar extends StatelessWidget {
  const _GpaBar({required this.label, required this.gpa, required this.highlight});

  final String label;
  final double gpa;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    // Bars are scaled from 3.0 so the differences between semesters are visible.
    final height = 30 + 90 * ((gpa - 3.0) / 1.0).clamp(0.0, 1.0);
    return Semantics(
      label: '$label GPA ${gpa.toStringAsFixed(2)}',
      excludeSemantics: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            gpa.toStringAsFixed(2),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Container(
            width: 38,
            height: height,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12), bottom: Radius.circular(4)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: highlight
                    ? (context.isLight ? const [AppColors.primary, AppColors.accent] : const [Colors.white, AppColors.tintBlush])
                    : [context.accentInk.withValues(alpha: 0.45), context.accentInk.withValues(alpha: 0.15)],
              ),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: AppText.caption, maxLines: 1),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result});

  final CourseResult result;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.selectedBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              result.grade,
              style: TextStyle(
                color: context.selectedFg,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.title, style: AppText.title),
                Text('${result.code} · ${result.credits} credits', style: AppText.caption),
              ],
            ),
          ),
          Text(
            result.points.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
