import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'data/sample_data.dart';
import 'firebase_options.dart';
import 'routes.dart';
import 'services/firebase_campus_api.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

/// Which backend to use. The web build defaults to Firebase; pass
/// `--dart-define=BACKEND=fastapi` to use the local FastAPI server instead.
const String backend = String.fromEnvironment('BACKEND', defaultValue: 'firebase');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState.instance..loginRoute = AppRoutes.login;
  if (kIsWeb && backend == 'firebase') {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
    state.api = FirebaseCampusApi();
  }
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
