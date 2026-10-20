import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/campus_cards.dart';
import '../widgets/common.dart';
import '../widgets/glass_page.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return ValueListenableBuilder<Set<String>>(
      valueListenable: state.readAnnouncements,
      builder: (context, read, _) {
        final unread = announcements.where((a) => !read.contains(a.id)).length;
        return GlassPage(
          title: 'Announcements',
          actions: [
            if (unread > 0)
              TextButton.icon(
                onPressed: () => runCampusAction<void>(
                  context,
                  () => state.markAllRead(announcements.map((a) => a.id)),
                  success: (_) => 'All announcements marked as read',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: context.accentInk,
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.done_all_rounded),
                label: const Text('Mark all read'),
              ),
          ],
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.md),
              child: Text(
                unread == 0 ? 'You are all caught up.' : '$unread unread · tap a card to mark it read',
                style: AppText.body,
              ),
            ),
            for (final item in announcements)
              AnnouncementCard(
                announcement: item,
                unread: !read.contains(item.id),
                margin: const EdgeInsets.only(bottom: 12),
                onTap: () => runCampusAction<void>(
                  context,
                  () => state.markRead(item.id),
                ),
              ),
          ],
        );
      },
    );
  }
}
