import 'package:flutter/material.dart';

import 'data/sample_data.dart';
import 'routes.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState.instance..loginRoute = AppRoutes.login;
  // Picks up a saved login so a page refresh keeps the student signed in.
  await state.restoreSession();
  runApp(const CrimsonCampusApp());
}

class CrimsonCampusApp extends StatelessWidget {
  const CrimsonCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      navigatorKey: AppState.instance.navigatorKey,
      // '/' (the landing page) is the default route; leaving initialRoute
      // unset lets web deep links such as /#/fees open directly.
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
