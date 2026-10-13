import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'glass_container.dart';

/// Announcement card: icon, title, message and a highlighted deadline strip.
class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.onTap,
    this.margin,
    this.unread = false,
  });

  final Announcement announcement;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: margin,
      onTap: onTap,
      semanticLabel: 'Announcement: ${announcement.title}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconBubble(icon: announcement.icon, size: 44),
                  if (unread)
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(announcement.title, style: AppText.title),
                    const SizedBox(height: 2),
                    Text(announcement.date, style: AppText.caption),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusBadge(label: announcement.badge, tone: announcement.tone),
            ],
          ),
          const SizedBox(height: 12),
          Text(announcement.message, style: AppText.body),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: Row(
              children: [
                const Icon(Icons.alarm_rounded, size: 18, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    announcement.deadline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Event card with date tile, details and a register / cancel toggle.
/// Tapping the card opens the event detail page.
class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, this.margin});

  final CampusEvent event;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return ValueListenableBuilder<Set<String>>(
      valueListenable: state.registeredEvents,
      builder: (context, registeredIds, _) {
        final registered = registeredIds.contains(event.id);
        return GlassContainer(
          margin: margin,
          semanticLabel: 'Event: ${event.title}',
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.eventDetail,
            arguments: event,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DateTile(day: event.day, month: event.month),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        StatusBadge(label: event.category, dense: true),
                        StatusBadge(
                          label: registered ? 'Registered' : 'Open',
                          tone: registered ? BadgeTone.success : BadgeTone.warning,
                          dense: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(event.title, style: AppText.title),
                    MetaLine(
                      icon: Icons.schedule_rounded,
                      text: '${event.weekday} · ${event.time}',
                    ),
                    MetaLine(icon: Icons.place_rounded, text: event.venue),
                    const SizedBox(height: 12),
                    PillButton(
                      label: registered ? 'Cancel' : 'Register',
                      icon: registered
                          ? Icons.close_rounded
                          : Icons.how_to_reg_rounded,
                      filled: !registered,
                      onPressed: () => toggleRegistration(context, event),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Shared register/cancel behaviour for event cards and the detail page.
Future<void> toggleRegistration(BuildContext context, CampusEvent event) async {
  await runCampusAction<bool>(
    context,
    () => AppState.instance.toggleEvent(event.id),
    success: (registered) => registered
        ? "You're registered for ${event.title}"
        : 'Registration cancelled for ${event.title}',
    icon: (registered) =>
        registered ? Icons.event_available_rounded : Icons.event_busy_rounded,
  );
}
