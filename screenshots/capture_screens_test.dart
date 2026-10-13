// Renders every page of the app to PNG for design review.
//
// Run:  flutter test screenshots/capture_screens_test.dart
// Output: design/screens/*.png (phone width 390, full page length, @2x)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crimson_campus/data/sample_data.dart';
import 'package:crimson_campus/models/student.dart';
import 'package:crimson_campus/prototype/prototype_switcher.dart';
import 'package:crimson_campus/routes.dart';
import 'package:crimson_campus/state/app_state.dart';
import 'package:crimson_campus/theme/app_theme.dart';
import 'package:crimson_campus/widgets/inti_logo.dart';
import 'package:crimson_campus/screens/campus_map_screen.dart';
import 'package:crimson_campus/widgets/landing_effects.dart';

import '../test/fake_campus_api.dart';

const double _width = 390;
const double _phoneHeight = 844;
const double _dpr = 2;
Directory _outDir = Directory('design/screens');
final _boundaryKey = GlobalKey();
final List<String> _photos = [];

Future<void> _loadFonts() async {
  final sdk = Platform.environment['FLUTTER_ROOT'] ??
      r'C:\Users\ajayn\Downloads\flutter_windows_3.47.6-stable\flutter';
  final dir = '$sdk/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String name) async =>
      ByteData.sublistView(await File('$dir/$name').readAsBytes());

  final roboto = FontLoader('Roboto');
  for (final w in ['regular', 'medium', 'bold', 'black', 'light']) {
    roboto.addFont(read('roboto-$w.ttf'));
  }
  await roboto.load();
  final icons = FontLoader('MaterialIcons')..addFont(read('materialicons-regular.otf'));
  await icons.load();
}

Widget _app(String route) => RepaintBoundary(
      key: _boundaryKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        navigatorKey: AppState.instance.navigatorKey,
        routes: AppRoutes.routes,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        initialRoute: route,
        // After login the app clears history, so Home has no back arrow.
        onGenerateInitialRoutes: route == AppRoutes.home
            ? (name) => [MaterialPageRoute<void>(builder: AppRoutes.routes[name]!)]
            : null,
      ),
    );

void _setHeight(WidgetTester tester, double height) {
  tester.view.devicePixelRatio = _dpr;
  tester.view.physicalSize = Size(_width * _dpr, height * _dpr);
}

/// Largest scroll extent of the visible page, so long pages are captured whole.
double _scrollExtent(WidgetTester tester) {
  var extent = 0.0;
  for (final element in find.byType(Scrollable).evaluate()) {
    final state = (element as StatefulElement).state as ScrollableState;
    final pos = state.position;
    if (pos.axis == Axis.vertical && pos.hasContentDimensions) {
      extent = extent < pos.maxScrollExtent ? pos.maxScrollExtent : extent;
    }
  }
  return extent;
}

Future<void> _capture(
  WidgetTester tester,
  String name, {
  required String route,
  Future<void> Function()? before,
  bool fullLength = true,
}) async {
  _setHeight(tester, _phoneHeight);
  await tester.pumpWidget(_app(route));
  await tester.pumpAndSettle();
  if (before != null) {
    await before();
    await tester.pumpAndSettle();
  }
  if (fullLength) {
    final extent = _scrollExtent(tester);
    if (extent > 0) {
      _setHeight(tester, _phoneHeight + extent);
      await tester.pumpAndSettle();
    }
  }
  // Let the logo image decode before taking the picture.
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
  await tester.pump();

  final boundary =
      _boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _dpr);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  File('${_outDir.path}/$name.png').writeAsBytesSync(bytes!);
  // Unmount and let any image / tile timers finish before the test ends.
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  late FakeCampusApi api;

  setUpAll(() async {
    LandingMotion.enabled = false;
    for (final photo in ['inti_students', 'inti_aerial', 'inti_atrium', 'inti_graduates']) {
      _photos.add('assets/images/$photo.jpg');
    }
    CampusMapScreen.showTiles = false;
    _outDir.createSync(recursive: true);
    await _loadFonts();
  });

  setUp(() async {
    api = FakeCampusApi()..seedAccount(demoStudent);
    api.lists['clubs'] = {'robotics', 'byteforge'};
    api.lists['events'] = {'robotics-build-night'};
    api.lists['announcements-read'] = {'maintenance'};
    api.lists['library-renewals'] = {'cn'};
    api.lists['shuttle-alerts'] = {'b'};
    final state = AppState.instance..api = api;
    await state.logout();
    await state.login(demoStudent.email, demoStudent.password);
    await state.updateProfile({
      'phone': '+60 12-345 6789',
      'residence': 'INTI Residence, Block C-12',
    });
    await state.raiseTicket('IT & Wi-Fi', 'Cannot connect to campus Wi-Fi in the library.');
  });

  Future<void> precacheLogo(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final context = tester.element(find.byType(SizedBox));
    await tester.runAsync(() async {
      await precacheImage(const AssetImage(IntiLogo.asset), context);
      await precacheImage(const AssetImage('assets/images/inti_campus.jpg'), context);
      for (final photo in _photos) {
        await precacheImage(AssetImage(photo), context);
      }
    });
  }

  void shot(String name, String route,
      {Future<void> Function(WidgetTester t)? before, bool loggedOut = false, bool fullLength = true}) {
    testWidgets(name, (tester) async {
      addTearDown(tester.view.reset);
      if (loggedOut) await AppState.instance.logout();
      await precacheLogo(tester);
      await _capture(
        tester,
        name,
        route: route,
        fullLength: fullLength,
        before: before == null ? null : () => before(tester),
      );
    });
  }

  Future<void> Function(WidgetTester) tab(int index) => (t) async {
        AppState.instance.currentTab.value = index;
      };

  // Landing is scroll-driven, so capture it at several scroll positions.
  Future<void> Function(WidgetTester) scrollTo(double fraction) => (t) async {
        final position = t.state<ScrollableState>(find.byType(Scrollable).first).position;
        position.jumpTo(position.maxScrollExtent * fraction);
      };
  shot('01a_landing_hero', AppRoutes.landing, loggedOut: true, fullLength: false);
  shot('01b_landing_zoom', AppRoutes.landing, loggedOut: true, fullLength: false, before: scrollTo(0.22));
  shot('01c_landing_features', AppRoutes.landing, loggedOut: true, fullLength: false, before: scrollTo(0.45));
  shot('01d_landing_3d_preview', AppRoutes.landing, loggedOut: true, fullLength: false, before: scrollTo(0.72));
  shot('01e_landing_login', AppRoutes.landing, loggedOut: true, fullLength: false, before: scrollTo(1.0));
  shot('02_login', AppRoutes.login, loggedOut: true);
  shot('03_create_account', AppRoutes.register, loggedOut: true);
  shot('04_home_dashboard', AppRoutes.home, before: tab(0));
  shot('05_timetable_tab', AppRoutes.home, before: tab(1));
  shot('06_campus_life_events', AppRoutes.home, before: tab(2));
  shot('07_campus_life_updates', AppRoutes.home, before: (t) async {
    AppState.instance.currentTab.value = 2;
    await t.pumpAndSettle();
    await t.tap(find.text('Updates'));
  });
  shot('08_profile_tab', AppRoutes.home, before: tab(3));
  shot('09_edit_profile_sheet', AppRoutes.home, fullLength: false, before: (t) async {
    AppState.instance.currentTab.value = 3;
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Edit profile'));
  });
  shot('10_results', AppRoutes.results);
  shot('11_attendance', AppRoutes.attendance);
  shot('12_fees', AppRoutes.fees);
  shot('13_library', AppRoutes.library);
  shot('14_shuttle', AppRoutes.shuttle);
  shot('15_clubs', AppRoutes.clubs);
  shot('16_helpdesk', AppRoutes.helpdesk);
  shot('17_announcements', AppRoutes.announcements);
  shot('18_event_details', AppRoutes.eventDetail);

  shot('19_shuttle_route', AppRoutes.shuttleRoute);

  // ---- New landing sections, login pages in light mode ----
  group('sections', () {
    setUp(() => _outDir = Directory('design/sections')..createSync(recursive: true));
    tearDown(() {
      _outDir = Directory('design/screens');
      AppState.instance.themeMode.value = ThemeMode.dark;
    });

    Future<void> Function(WidgetTester) scrollToText(ThemeMode mode, String text) => (t) async {
          AppState.instance.themeMode.value = mode;
          await t.pumpAndSettle();
          final position = t.state<ScrollableState>(find.byType(Scrollable).first).position;
          final top = t.getTopLeft(find.text(text)).dy;
          position.jumpTo(position.pixels + top - 70);
        };

    for (final mode in [ThemeMode.dark, ThemeMode.light]) {
      final theme = mode == ThemeMode.dark ? 'dark' : 'light';
      shot('courses_$theme', AppRoutes.landing, loggedOut: true, fullLength: false,
          before: scrollToText(mode, 'STUDY AT INTI'));
      shot('careers_$theme', AppRoutes.landing, loggedOut: true, fullLength: false,
          before: scrollToText(mode, 'CAREERS'));
      shot('international_$theme', AppRoutes.landing, loggedOut: true, fullLength: false,
          before: scrollToText(mode, 'INTERNATIONAL COMMUNITY'));
      shot('campus_details_$theme', AppRoutes.landing, loggedOut: true, fullLength: false,
          before: scrollToText(mode, 'ON CAMPUS'));
      shot('login_$theme', AppRoutes.login, loggedOut: true, before: (t) async {
        AppState.instance.themeMode.value = mode;
      });
      shot('register_$theme', AppRoutes.register, loggedOut: true, before: (t) async {
        AppState.instance.themeMode.value = mode;
      });
    }
  });

  // ---- Prototype: About INTI variants and the campus map, light + dark ----
  group('prototype', () {
    setUp(() => _outDir = Directory('design/prototype')..createSync(recursive: true));
    tearDown(() {
      _outDir = Directory('design/screens');
      AppState.instance.themeMode.value = ThemeMode.dark;
      aboutVariant.value = 'A';
      CampusMapScreen.showTiles = false;
    });

    for (final mode in [ThemeMode.dark, ThemeMode.light]) {
      final theme = mode == ThemeMode.dark ? 'dark' : 'light';
      shot('landing_hero_$theme', AppRoutes.landing, loggedOut: true, fullLength: false, before: (t) async {
        AppState.instance.themeMode.value = mode;
      });
      for (final variant in ['A', 'B', 'C']) {
        for (final (step, extra) in [(1, 0.15), (2, 0.9)]) {
          shot('about_${variant}_${theme}_$step', AppRoutes.landing, loggedOut: true, fullLength: false,
              before: (t) async {
            AppState.instance.themeMode.value = mode;
            aboutVariant.value = variant;
            await t.pumpAndSettle();
            final position = t.state<ScrollableState>(find.byType(Scrollable).first).position;
            // Start of the About section, then further into it.
            final heading = find.text('ABOUT THE UNIVERSITY');
            final headingTop = t.getTopLeft(heading).dy;
            position.jumpTo(position.pixels + headingTop - 80 + _phoneHeight * extra * (variant == 'C' ? 1.6 : 1));
          });
        }
      }
      shot('campus_map_$theme', AppRoutes.campusMap, fullLength: false, before: (t) async {
        AppState.instance.themeMode.value = mode;
        CampusMapScreen.showTiles = true;
        HttpOverrides.global = null; // allow real map tiles in this harness
        await t.pumpAndSettle();
        await t.tap(find.text('Start live location'));
        await t.pumpAndSettle();
        await t.tap(find.text('Try demo position'));
        await t.pumpAndSettle();
        await t.tap(find.text('Academic Block A').last);
        await t.pumpAndSettle();
        await t.tap(find.text('Show route'));
        await t.pumpAndSettle();
        for (var i = 0; i < 6; i++) {
          await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 700)));
          await t.pump(const Duration(milliseconds: 300));
        }
      });
    }
  });

  // Keep the analyzer happy about otherwise-unused imports in some builds.
  test('data sanity', () {
    expect(campusEvents, isNotEmpty);
    expect(NotificationPreferences.defaults.announcements, isTrue);
  });
}
