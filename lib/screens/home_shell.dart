import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_nav_bar.dart';
import 'campus_life_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'timetable_screen.dart';

/// Holds the four main tabs behind a floating glass navigation bar.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  static const List<GlassNavItem> _items = [
    GlassNavItem('Home', Icons.home_outlined, Icons.home_rounded),
    GlassNavItem('Timetable', Icons.calendar_month_outlined, Icons.calendar_month_rounded),
    GlassNavItem('Campus', Icons.celebration_outlined, Icons.celebration_rounded),
    GlassNavItem('Profile', Icons.person_outline_rounded, Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return ValueListenableBuilder<int>(
      valueListenable: state.currentTab,
      builder: (context, index, _) => Scaffold(
        extendBody: true,
        backgroundColor: AppColors.primaryDark,
        body: IndexedStack(
          index: index,
          children: const [
            DashboardScreen(),
            TimetableScreen(),
            CampusLifeScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: GlassNavBar(
          items: _items,
          currentIndex: index,
          onSelected: (i) => state.currentTab.value = i,
        ),
      ),
    );
  }
}
