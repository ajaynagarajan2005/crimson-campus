import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/campus_cards.dart';
import '../widgets/common.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_page.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key, required this.event});

  final CampusEvent event;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: AppState.instance.registeredEvents,
      builder: (context, registeredIds, _) {
        final registered = registeredIds.contains(event.id);
        final taken = event.registered + (registered ? 1 : 0);
        final spotsLeft = (event.capacity - taken).clamp(0, event.capacity);

        return GlassPage(
          title: 'Event details',
          children: [
            // Hero banner: gradient with a large faded icon as a pattern.
            Container(
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.card),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF8A80), AppColors.primary, Color(0xFF7A0C0C)],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -30,
                    child: Icon(event.icon, size: 200, color: Colors.white.withValues(alpha: 0.14)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DateTile(day: event.day, month: event.month),
                        const Spacer(),
                        Wrap(
                          spacing: 8,
                          children: [
                            StatusBadge(label: event.category, tone: BadgeTone.info),
                            StatusBadge(
                              label: registered ? 'Registered' : 'Open',
                              tone: registered ? BadgeTone.success : BadgeTone.warning,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(event.title, style: AppText.h1),
            const SizedBox(height: AppSpacing.md),
            GlassContainer(
              child: Column(
                children: [
                  InfoRow(icon: Icons.calendar_today_rounded, label: 'Date', value: '${event.weekday}, ${event.day} ${event.month} 2026'),
                  InfoRow(icon: Icons.schedule_rounded, label: 'Time', value: event.time),
                  InfoRow(icon: Icons.place_rounded, label: 'Venue', value: event.venue),
                ],
              ),
            ),
            const SectionHeader(title: 'About this event', icon: Icons.info_outline_rounded),
            GlassContainer(
              child: Text(event.description, style: AppText.body),
            ),
            const SectionHeader(title: 'Seats', icon: Icons.event_seat_rounded),
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('$taken of ${event.capacity} registered', style: AppText.title)),
                      StatusBadge(
                        label: '$spotsLeft left',
                        tone: spotsLeft < 10 ? BadgeTone.warning : BadgeTone.light,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GlassProgressBar(value: taken / event.capacity, height: 10),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PillButton(
              label: registered ? 'Cancel registration' : 'Register for this event',
              icon: registered ? Icons.event_busy_rounded : Icons.event_available_rounded,
              filled: !registered,
              expand: true,
              onPressed: spotsLeft == 0 && !registered
                  ? null
                  : () => toggleRegistration(context, event),
            ),
          ],
        );
      },
    );
  }
}
