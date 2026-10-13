import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_page.dart';

/// Weekly timetable with a day selector. Opens on today (or Monday at weekends).
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final int _today = DateTime.now().weekday;
  late int _selectedDay = _today <= 5 ? _today : 1;

  @override
  Widget build(BuildContext context) {
    final sessions = classesFor(_selectedDay);
    return GlassPage(
      title: 'Timetable',
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(6),
          borderRadius: AppRadius.tile + 4,
          child: Row(
            children: [
              for (var day = 1; day <= 5; day++)
                Expanded(
                  child: _DayChip(
                    label: weekdayShort[day],
                    selected: day == _selectedDay,
                    isToday: day == _today,
                    onTap: () => setState(() => _selectedDay = day),
                  ),
                ),
            ],
          ),
        ),
        SectionHeader(
          title: '${weekdayNames[_selectedDay]} · ${sessions.length} '
              '${sessions.length == 1 ? 'class' : 'classes'}',
          icon: Icons.view_agenda_rounded,
        ),
        if (sessions.isEmpty)
          const GlassContainer(
            child: Text('No classes scheduled.', style: AppText.body),
          ),
        for (final session in sessions)
          _ClassTile(
            session: session,
            onTap: () => showCampusSnack(
              context,
              'Reminder set for ${session.code} at ${formatTime(session.start)}',
              icon: Icons.notifications_active_rounded,
            ),
          ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : Colors.white;
    return Semantics(
      selected: selected,
      button: true,
      label: isToday ? '$label, today' : label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.tile),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.tile),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isToday ? color : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassTile extends StatelessWidget {
  const _ClassTile({required this.session, required this.onTap});

  final ClassSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      semanticLabel: '${session.title} at ${formatTime(session.start)}',
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatTime(session.start),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(formatTime(session.end), style: AppText.caption),
              ],
            ),
          ),
          Container(
            width: 4,
            height: 58,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: session.isLab ? AppColors.warning : Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  children: [
                    StatusBadge(label: session.code, tone: BadgeTone.info, dense: true),
                    StatusBadge(
                      label: session.isLab ? 'Lab' : 'Lecture',
                      tone: session.isLab ? BadgeTone.warning : BadgeTone.light,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(session.title, style: AppText.title),
                MetaLine(icon: Icons.place_rounded, text: session.room),
                MetaLine(icon: Icons.person_rounded, text: session.lecturer),
              ],
            ),
          ),
          const Icon(Icons.notifications_none_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}
