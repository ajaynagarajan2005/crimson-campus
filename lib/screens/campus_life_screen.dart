import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/campus_cards.dart';
import '../widgets/common.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_page.dart';

/// Student life tab: events and campus updates behind a segmented toggle.
class CampusLifeScreen extends StatefulWidget {
  const CampusLifeScreen({super.key});

  @override
  State<CampusLifeScreen> createState() => _CampusLifeScreenState();
}

class _CampusLifeScreenState extends State<CampusLifeScreen> {
  bool _showEvents = true;

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return GlassPage(
      title: 'Campus life',
      children: [
        GlassContainer(
          semanticLabel: 'Browse clubs and societies',
          onTap: () => Navigator.pushNamed(context, AppRoutes.clubs),
          child: Row(
            children: [
              const IconBubble(icon: Icons.groups_rounded, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: ValueListenableBuilder<Set<String>>(
                  valueListenable: state.joinedClubs,
                  builder: (context, joined, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Clubs & societies', style: AppText.title),
                      Text(
                        '${clubs.length} active clubs · you are in ${joined.length}',
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SegmentedToggle(
          showEvents: _showEvents,
          onChanged: (value) => setState(() => _showEvents = value),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_showEvents) ...[
          for (final event in campusEvents)
            EventCard(event: event, margin: const EdgeInsets.only(bottom: 12)),
        ] else
          ValueListenableBuilder<Set<String>>(
            valueListenable: state.readAnnouncements,
            builder: (context, read, _) => Column(
              children: [
                for (final item in announcements)
                  AnnouncementCard(
                    announcement: item,
                    unread: !read.contains(item.id),
                    margin: const EdgeInsets.only(bottom: 12),
                    onTap: () => runCampusAction<void>(
                      context,
                      () => state.markRead(item.id),
                      success: (_) => 'Marked "${item.title}" as read',
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _SegmentedToggle extends StatelessWidget {
  const _SegmentedToggle({required this.showEvents, required this.onChanged});

  final bool showEvents;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(5),
      borderRadius: AppRadius.pill,
      child: Row(
        children: [
          _Segment(
            label: 'Events',
            icon: Icons.event_rounded,
            selected: showEvents,
            onTap: () => onChanged(true),
          ),
          _Segment(
            label: 'Updates',
            icon: Icons.campaign_rounded,
            selected: !showEvents,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : Colors.white;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
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
