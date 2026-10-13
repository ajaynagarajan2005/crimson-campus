import 'package:flutter/material.dart';

import 'data/sample_data.dart';
import 'screens/announcements_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/campus_map_screen.dart';
import 'screens/clubs_screen.dart';
import 'screens/event_detail_screen.dart';
import 'screens/fees_screen.dart';
import 'screens/helpdesk_screen.dart';
import 'screens/home_shell.dart';
import 'screens/landing_screen.dart';
import 'screens/library_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/results_screen.dart';
import 'screens/shuttle_route_screen.dart';
import 'screens/shuttle_screen.dart';
import 'screens/timetable_screen.dart';
import 'state/app_state.dart';

/// Named routes for every page in the app.
class AppRoutes {
  AppRoutes._();

  static const String landing = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String timetable = '/timetable';
  static const String results = '/results';
  static const String attendance = '/attendance';
  static const String fees = '/fees';
  static const String library = '/library';
  static const String shuttle = '/shuttle';
  static const String clubs = '/clubs';
  static const String helpdesk = '/helpdesk';
  static const String announcements = '/announcements';
  static const String eventDetail = '/event';
  static const String campusMap = '/campus-map';
  static const String shuttleRoute = '/shuttle/route';

  static Map<String, WidgetBuilder> get routes => {
        landing: (_) => const LandingScreen(),
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),
        // Open to visitors too, so no login guard.
        campusMap: (_) => const CampusMapScreen(),
        home: _requireLogin((_) => const HomeShell()),
        timetable: _requireLogin((_) => const TimetableScreen()),
        results: _requireLogin((_) => const ResultsScreen()),
        attendance: _requireLogin((_) => const AttendanceScreen()),
        fees: _requireLogin((_) => const FeesScreen()),
        library: _requireLogin((_) => const LibraryScreen()),
        shuttle: _requireLogin((_) => const ShuttleScreen()),
        clubs: _requireLogin((_) => const ClubsScreen()),
        helpdesk: _requireLogin((_) => const HelpdeskScreen()),
        announcements: _requireLogin((_) => const AnnouncementsScreen()),
      };

  /// Pages that need an account show the login page until the student logs in.
  static WidgetBuilder _requireLogin(WidgetBuilder builder) =>
      (context) => AppState.instance.isLoggedIn ? builder(context) : const LoginScreen();

  /// Routes that need arguments.
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == eventDetail) {
      final event = settings.arguments is CampusEvent
          ? settings.arguments! as CampusEvent
          : campusEvents.first;
      return MaterialPageRoute<void>(
        settings: settings,
        builder: _requireLogin((_) => EventDetailScreen(event: event)),
      );
    }
    if (settings.name == shuttleRoute) {
      final route = settings.arguments is ShuttleRoute
          ? settings.arguments! as ShuttleRoute
          : shuttleRoutes.first;
      return MaterialPageRoute<void>(
        settings: settings,
        builder: _requireLogin((_) => ShuttleRouteScreen(route: route)),
      );
    }
    return null;
  }
}
