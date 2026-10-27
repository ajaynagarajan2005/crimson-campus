import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/student.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/campus_themed.dart';
import '../widgets/campus_cards.dart';
import '../widgets/common.dart';
import '../widgets/glass_container.dart';
import '../widgets/glass_page.dart';
import '../widgets/nav_menu.dart';

/// Home dashboard: identity, profile, academic snapshot, quick access,
/// campus update and student life.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Student?>(
      valueListenable: AppState.instance.student,
      builder: (context, me, _) {
        if (me == null) return const SizedBox.shrink();
        return _content(context, me);
      },
    );
  }

  Widget _content(BuildContext context, Student me) {
    return GlassPage(
      children: [
        const _DashboardHeader(),
        const SizedBox(height: AppSpacing.md),
        _ProfileCard(student: me),
        SectionHeader(
          title: 'Academic snapshot',
          icon: Icons.insights_rounded,
          actionLabel: 'Results',
          onAction: () => Navigator.pushNamed(context, AppRoutes.results),
        ),
        _AcademicSnapshot(student: me),
        const _NavigationHeader(),
        const NavMenuGrid(),
        const _CampusMapBanner(),
        SectionHeader(
          title: 'Campus update',
          icon: Icons.campaign_rounded,
          actionLabel: 'See all',
          onAction: () => Navigator.pushNamed(context, AppRoutes.announcements),
        ),
        AnnouncementCard(
          announcement: announcements.first,
          onTap: () {
            AppState.instance.markReadInBackground(announcements.first.id);
            Navigator.pushNamed(context, AppRoutes.announcements);
          },
        ),
        SectionHeader(
          title: 'Student life',
          icon: Icons.celebration_rounded,
          actionLabel: 'See all',
          onAction: () => AppState.instance.currentTab.value = 2,
        ),
        EventCard(event: campusEvents.first),
        const _ShuttleNotice(),
        // Leaves room above the floating navigation bar.
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const NavMenuButton(),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('CRIMSON CAMPUS', style: AppText.overline),
              Text('My Campus Today', style: AppText.h2),
            ],
          ),
        ),
        const ThemeToggleButton(),
        const SizedBox(width: 10),
        ValueListenableBuilder<Set<String>>(
          valueListenable: AppState.instance.readAnnouncements,
          builder: (context, read, _) {
            final unread = announcements.where((a) => !read.contains(a.id)).length;
            return Tooltip(
              message: 'Announcements',
              child: GlassContainer(
                width: 48,
                height: 48,
                padding: EdgeInsets.zero,
                borderRadius: 16,
                alignment: Alignment.center,
                semanticLabel: '$unread unread announcements',
                onTap: () => Navigator.pushNamed(context, AppRoutes.announcements),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.notifications_none_rounded, color: context.accentInk),
                    if (unread > 0)
                      Positioned(
                        top: -6,
                        right: -8,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 18),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: context.selectedBg,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            '$unread',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.selectedFg,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
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
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      tint: 0.18,
      semanticLabel: 'Open profile',
      onTap: () => AppState.instance.currentTab.value = 3,
      child: Row(
        children: [
          ProfileAvatar(student: student, size: 76),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${greetingFor(DateTime.now())},', style: AppText.body),
                Text(student.name, style: AppText.h2),
                const SizedBox(height: 4),
                Text(student.programme, style: AppText.caption),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    StatusBadge(label: student.id, tone: BadgeTone.info),
                    StatusBadge(label: student.year),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular initials avatar with an "active" status dot.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.student, this.size = 76, this.onEditPhoto});

  final Student student;
  final double size;

  /// When set, shows a camera button for uploading a new photo.
  final VoidCallback? onEditPhoto;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Profile picture of ${student.name}',
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, AppColors.tintBlush],
              ),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: _photoOrInitials(),
          ),
          if (onEditPhoto == null)
            Positioned(
              right: size * 0.03,
              bottom: size * 0.03,
              child: Container(
                width: size * 0.22,
                height: size * 0.22,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
              ),
            )
          else
            Positioned(
              right: -2,
              bottom: -2,
              child: Tooltip(
                message: student.photoUrl == null ? 'Upload photo' : 'Change photo',
                child: Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 2.5)),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onEditPhoto,
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.photo_camera_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

extension on ProfileAvatar {
  Widget _photoOrInitials() {
    final initials = Text(
      student.initials,
      style: TextStyle(
        color: AppColors.primary,
        fontSize: size * 0.34,
        fontWeight: FontWeight.w800,
      ),
    );
    final path = student.photoUrl;
    if (path == null) return initials;
    return ClipOval(
      child: Image.network(
        AppState.instance.api.mediaUrl(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Center(child: initials),
      ),
    );
  }
}

class _AcademicSnapshot extends StatelessWidget {
  const _AcademicSnapshot({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    final attendance = overallAttendance;
    final upcoming = nextClass();

    return GlassContainer(
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 520 ? 4 : 2;
              const gap = 12.0;
              final tileWidth =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  _StatTile(
                    width: tileWidth,
                    icon: Icons.layers_rounded,
                    label: 'Semester',
                    value: '${student.semester}',
                    caption: 'of ${student.totalSemesters} semesters',
                    progress: student.semester / student.totalSemesters,
                  ),
                  _StatTile(
                    width: tileWidth,
                    icon: Icons.star_rounded,
                    label: 'CGPA',
                    value: student.cgpaLabel,
                    caption: student.cgpa == null ? 'add it in Profile' : 'out of 4.00',
                    progress: (student.cgpa ?? 0) / 4,
                  ),
                  _StatTile(
                    width: tileWidth,
                    icon: Icons.workspace_premium_rounded,
                    label: 'Credits',
                    value: '${student.creditsEarned}',
                    caption: 'of ${student.creditsRequired} earned',
                    progress: student.creditsRequired == 0
                        ? 0
                        : student.creditsEarned / student.creditsRequired,
                  ),
                  _StatTile(
                    width: tileWidth,
                    icon: Icons.how_to_reg_rounded,
                    label: 'Attendance',
                    value: '${(attendance * 100).round()}%',
                    caption: 'minimum 75%',
                    progress: attendance,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.attendance),
                  ),
                ],
              );
            },
          ),
          const Divider(),
          InfoRow(
            icon: Icons.person_pin_rounded,
            label: 'Academic advisor',
            value: student.advisor,
          ),
          InfoRow(
            icon: Icons.class_rounded,
            label: upcoming == null ? 'Next class' : 'Next class · ${upcoming.when}',
            value: upcoming == null
                ? 'No classes scheduled'
                : '${upcoming.session.code} ${upcoming.session.title} · '
                    '${formatTime(upcoming.session.start)} · ${upcoming.session.room}',
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.progress,
    this.onTap,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final double progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.faint,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        border: Border.all(color: context.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: context.accentInk),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: AppText.caption)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(caption, style: AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          GlassProgressBar(value: progress, height: 6),
        ],
      ),
    );

    if (onTap == null) return tile;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: tile,
      ),
    );
  }
}

/// "Navigation" title with the grid / list switch.
class _NavigationHeader extends StatelessWidget {
  const _NavigationHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm, left: AppSpacing.xs),
      child: Row(
        children: [
          Icon(Icons.apps_rounded, size: 20, color: context.accentInk),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Semantics(header: true, child: const Text('Navigation', style: AppText.h3))),
          const NavViewToggle(),
        ],
      ),
    );
  }
}

class _ShuttleNotice extends StatelessWidget {
  const _ShuttleNotice();

  @override
  Widget build(BuildContext context) {
    final line = shuttleRoutes.first;
    return GlassContainer(
      margin: const EdgeInsets.only(top: 12),
      semanticLabel: 'Shuttle update',
      onTap: () => Navigator.pushNamed(context, AppRoutes.shuttle),
      child: Row(
        children: [
          const IconBubble(icon: Icons.directions_bus_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${line.name} · ${line.path}', style: AppText.title),
                Text('Next departure ${line.nextDeparture} from ${line.stops.first.name}', style: AppText.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusBadge(label: line.status, tone: line.tone),
        ],
      ),
    );
  }
}

class _CampusMapBanner extends StatelessWidget {
  const _CampusMapBanner();

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: const EdgeInsets.only(top: 12),
      tint: 0.18,
      semanticLabel: 'Open the live campus map',
      onTap: () => Navigator.pushNamed(context, AppRoutes.campusMap),
      child: const Row(
        children: [
          IconBubble(icon: Icons.map_rounded),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Campus map', style: AppText.title),
                Text('Live location and walking directions to every building', style: AppText.caption),
              ],
            ),
          ),
          StatusBadge(label: 'Live', tone: BadgeTone.success),
        ],
      ),
    );
  }
}
