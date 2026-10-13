import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_page.dart';

class ClubsScreen extends StatelessWidget {
  const ClubsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return ValueListenableBuilder<Set<String>>(
      valueListenable: state.joinedClubs,
      builder: (context, joined, _) => GlassPage(
        title: 'Clubs & societies',
        children: [
          GlassContainer(
            tint: 0.18,
            child: Row(
              children: [
                const IconBubble(icon: Icons.groups_rounded, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "You're a member of ${joined.length} "
                        '${joined.length == 1 ? 'club' : 'clubs'}',
                        style: AppText.title,
                      ),
                      const Text(
                        'Club fair: Fri, 16 Oct 2026 · Central Lawn',
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Explore clubs', icon: Icons.explore_rounded),
          for (final club in clubs)
            GlassContainer(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconBubble(icon: club.icon, size: 46),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          children: [
                            StatusBadge(label: club.category, dense: true),
                            if (joined.contains(club.id))
                              const StatusBadge(label: 'Member', tone: BadgeTone.success, dense: true),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(club.name, style: AppText.title),
                        Text(club.description, style: AppText.caption),
                        MetaLine(
                          icon: Icons.schedule_rounded,
                          text: '${club.meets} · ${club.members} members',
                        ),
                        const SizedBox(height: 10),
                        PillButton(
                          label: joined.contains(club.id) ? 'Leave club' : 'Join club',
                          icon: joined.contains(club.id)
                              ? Icons.logout_rounded
                              : Icons.group_add_rounded,
                          filled: !joined.contains(club.id),
                          onPressed: () => runCampusAction<bool>(
                            context,
                            () => state.toggleClub(club.id),
                            success: (joinedNow) => joinedNow
                                ? 'Welcome to ${club.name}!'
                                : 'You left ${club.name}',
                            icon: (joinedNow) => joinedNow
                                ? Icons.celebration_rounded
                                : Icons.info_rounded,
                          ),
                        ),
                      ],
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
