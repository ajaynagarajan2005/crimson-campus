import 'package:flutter/material.dart';

import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'campus_action_card.dart';
import 'common.dart';
import 'glass_container.dart';

/// One place the navigation menu can take the student: a home tab or a page.
class NavDestination {
  const NavDestination(this.label, this.icon, {this.route, this.tab, this.badge, this.tone = BadgeTone.light})
      : assert((route == null) != (tab == null), 'Give either a route or a tab');

  final String label;
  final IconData icon;

  /// Named route to push, for pages outside the home tabs.
  final String? route;

  /// Index of a home tab (0 Home, 1 Timetable, 2 Campus, 3 Profile).
  final int? tab;
  final String? badge;
  final BadgeTone tone;
}

/// The whole navigation menu, grouped. The dashboard grid and the side panel
/// list both read from this, so they always offer the same pages.
const navMenuSections = <(String, List<NavDestination>)>[
  (
    'Main',
    [
      NavDestination('Home', Icons.home_rounded, tab: 0),
      NavDestination('Timetable', Icons.calendar_month_rounded, tab: 1),
      NavDestination('Campus life', Icons.celebration_rounded, tab: 2),
      NavDestination('Profile', Icons.person_rounded, tab: 3),
    ],
  ),
  (
    'Academics',
    [
      NavDestination('Results', Icons.emoji_events_rounded,
          route: AppRoutes.results, badge: 'New', tone: BadgeTone.success),
      NavDestination('Attendance', Icons.fact_check_rounded, route: AppRoutes.attendance),
      NavDestination('Fees', Icons.account_balance_wallet_rounded,
          route: AppRoutes.fees, badge: 'Due', tone: BadgeTone.warning),
      NavDestination('Library', Icons.local_library_rounded, route: AppRoutes.library),
    ],
  ),
  (
    'Campus',
    [
      NavDestination('Shuttle', Icons.directions_bus_rounded,
          route: AppRoutes.shuttle, badge: 'Live', tone: BadgeTone.success),
      NavDestination('Campus map', Icons.map_rounded, route: AppRoutes.campusMap),
      NavDestination('Clubs', Icons.groups_rounded, route: AppRoutes.clubs),
      NavDestination('Announcements', Icons.campaign_rounded, route: AppRoutes.announcements),
    ],
  ),
  (
    'Support',
    [
      NavDestination('Helpdesk', Icons.support_agent_rounded, route: AppRoutes.helpdesk),
      NavDestination('My tickets', Icons.confirmation_number_rounded, route: AppRoutes.ticketHistory),
    ],
  ),
];

/// Opens a destination: switches home tab, or pushes the page.
void openNavDestination(BuildContext context, NavDestination d) {
  if (d.tab != null) {
    AppState.instance.currentTab.value = d.tab!;
    Navigator.popUntil(context, (route) => route.settings.name == AppRoutes.home || route.isFirst);
  } else {
    Navigator.pushNamed(context, d.route!);
  }
}

/// The Scaffold that holds the menu (the home shell). Pages have their own
/// Scaffold, so look past them.
ScaffoldState? _menuScaffold(BuildContext context) {
  ScaffoldState? withMenu;
  context.visitAncestorElements((element) {
    if (element is StatefulElement && element.state is ScaffoldState && (element.state as ScaffoldState).hasDrawer) {
      withMenu = element.state as ScaffoldState;
      return false;
    }
    return true;
  });
  return withMenu;
}

/// Whether this page sits inside the home shell, so ☰ can open the menu.
bool hasNavMenu(BuildContext context) => _menuScaffold(context) != null;

/// Opens the side panel.
void openNavMenu(BuildContext context) => _menuScaffold(context)?.openDrawer();

/// ☰ button that opens the navigation list in the side panel.
class NavMenuButton extends StatelessWidget {
  const NavMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Open navigation menu',
      child: GlassContainer(
        width: 48,
        height: 48,
        padding: EdgeInsets.zero,
        borderRadius: 16,
        alignment: Alignment.center,
        semanticLabel: 'Open navigation menu',
        onTap: () => openNavMenu(context),
        child: Icon(Icons.menu_rounded, color: context.accentInk, size: 26),
      ),
    );
  }
}

/// ☰ for the top-left of an app bar on the home tabs.
class NavMenuIconButton extends StatelessWidget {
  const NavMenuIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Open navigation menu',
      icon: const Icon(Icons.menu_rounded),
      onPressed: () => openNavMenu(context),
    );
  }
}

/// Side panel listing every destination; shown only after tapping ☰.
class NavMenuDrawer extends StatelessWidget {
  const NavMenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final student = AppState.instance.student.value;
    final currentTab = AppState.instance.currentTab.value;
    return Drawer(
      backgroundColor: context.isLight ? Colors.white : AppColors.primaryDark,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Close menu',
                  icon: Icon(Icons.close_rounded, color: context.accentInk),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                const Expanded(child: Text('Menu', style: AppText.h2)),
              ],
            ),
            if (student != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Text('${student.name} · ${student.id}', style: AppText.caption),
              ),
            for (final (title, items) in navMenuSections) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
                child: Semantics(header: true, child: Text(title.toUpperCase(), style: AppText.overline)),
              ),
              for (final d in items)
                _NavListTile(
                  destination: d,
                  selected: d.tab != null && d.tab == currentTab,
                  onTap: () {
                    Navigator.pop(context);
                    openNavDestination(context, d);
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavListTile extends StatelessWidget {
  const _NavListTile({required this.destination, required this.selected, required this.onTap});

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        onTap: onTap,
        selected: selected,
        selectedTileColor: context.faint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.tile)),
        leading: IconBubble(
          icon: destination.icon,
          size: 36,
          background: selected ? null : context.faint,
          iconColor: selected ? null : context.accentInk,
        ),
        title: Text(
          destination.label,
          style: AppText.title.copyWith(color: selected ? context.accentInk : context.ink),
        ),
        trailing: destination.badge == null
            ? Icon(Icons.chevron_right_rounded, color: context.inkMuted)
            : StatusBadge(label: destination.badge!, tone: destination.tone, dense: true),
      ),
    );
  }
}

/// Navigation menu as a grid of tiles, with a grid / list switch.
/// The list option opens the side panel.
class NavMenuGrid extends StatelessWidget {
  const NavMenuGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final (_, section) in navMenuSections)
        for (final d in section)
          // Home is where the grid lives; announcements have the bell.
          if (d.tab != 0 && d.route != AppRoutes.announcements) d,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 330 ? 3 : 4;
        const gap = 10.0;
        final cardWidth = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final d in items)
              CampusActionCard(
                width: cardWidth,
                icon: d.icon,
                label: d.label,
                badge: d.badge,
                badgeTone: d.tone,
                onTap: () => openNavDestination(context, d),
              ),
          ],
        );
      },
    );
  }
}

/// Grid / list switch for the navigation menu. Grid is what the page shows;
/// list opens the side panel.
class NavViewToggle extends StatelessWidget {
  const NavViewToggle({super.key});

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, String label, bool selected, VoidCallback onTap) {
      return Tooltip(
        message: label,
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              width: 44,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? context.selectedBg : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Icon(icon, size: 20, color: selected ? context.selectedFg : context.accentInk),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.faint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: context.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.grid_view_rounded, 'Grid view', true, () {}),
          button(Icons.view_list_rounded, 'List view', false, () => openNavMenu(context)),
        ],
      ),
    );
  }
}
