import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crimson_campus/data/sample_data.dart';
import 'package:crimson_campus/prototype/prototype_switcher.dart';
import 'package:crimson_campus/routes.dart';
import 'package:crimson_campus/state/app_state.dart';
import 'package:crimson_campus/theme/app_theme.dart';
import 'package:crimson_campus/screens/campus_map_screen.dart';
import 'package:crimson_campus/widgets/landing_effects.dart';

import 'fake_campus_api.dart';

/// Opens every page at phone and tablet sizes; any RenderFlex overflow or
/// build error fails the test.
void main() {
  const sizes = {
    'small phone 320x640': Size(320, 640),
    'phone 390x844': Size(390, 844),
    'tablet 820x1180': Size(820, 1180),
  };

  late FakeCampusApi api;

  setUp(() async {
    LandingMotion.enabled = false;
    CampusMapScreen.showTiles = false;
    api = FakeCampusApi()..seedAccount(demoStudent);
    final state = AppState.instance..api = api;
    await state.logout();
    await state.login(demoStudent.email, demoStudent.password);
  });

  Widget appAt(String route) => MaterialApp(
        theme: AppTheme.theme,
        navigatorKey: AppState.instance.navigatorKey,
        routes: AppRoutes.routes,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        initialRoute: route,
      );

  void sizeView(WidgetTester tester, Size size) {
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  for (final entry in sizes.entries) {
    group(entry.key, () {
      final routes = [...AppRoutes.routes.keys, AppRoutes.eventDetail, AppRoutes.shuttleRoute];
      for (final route in routes) {
        testWidgets('renders $route', (tester) async {
          sizeView(tester, entry.value);
          await tester.pumpWidget(appAt(route));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('renders login and register while logged out', (tester) async {
        sizeView(tester, entry.value);
        await AppState.instance.logout();
        for (final route in [AppRoutes.landing, AppRoutes.login, AppRoutes.register]) {
          await tester.pumpWidget(appAt(route));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: route);
        }
      });

      testWidgets('renders every About variant in both themes', (tester) async {
        sizeView(tester, entry.value);
        await AppState.instance.logout();
        for (final mode in [ThemeMode.dark, ThemeMode.light]) {
          AppState.instance.themeMode.value = mode;
          for (final variant in ['A', 'B', 'C']) {
            aboutVariant.value = variant;
            await tester.pumpWidget(appAt(AppRoutes.landing));
            await tester.pumpAndSettle();
            // Scroll through the page so every scroll-driven layout runs.
            final position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
            for (final f in [0.25, 0.5, 0.75, 1.0]) {
              position.jumpTo(position.maxScrollExtent * f);
              await tester.pumpAndSettle();
            }
            expect(tester.takeException(), isNull, reason: '$mode variant $variant');
          }
        }
        AppState.instance.themeMode.value = ThemeMode.dark;
        aboutVariant.value = 'A';
      });

      testWidgets('renders the campus map in both themes', (tester) async {
        sizeView(tester, entry.value);
        for (final mode in [ThemeMode.dark, ThemeMode.light]) {
          AppState.instance.themeMode.value = mode;
          await tester.pumpWidget(appAt(AppRoutes.campusMap));
          await tester.pumpAndSettle();
          expect(find.text('Campus map'), findsOneWidget);
          await tester.tap(find.text('Academic Block A').last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$mode');
        }
        AppState.instance.themeMode.value = ThemeMode.dark;
      });

      testWidgets('renders login and create account in light theme', (tester) async {
        sizeView(tester, entry.value);
        await AppState.instance.logout();
        AppState.instance.themeMode.value = ThemeMode.light;
        for (final route in [AppRoutes.login, AppRoutes.register]) {
          await tester.pumpWidget(appAt(route));
          await tester.pumpAndSettle();
          expect(find.byTooltip('Switch to dark theme'), findsOneWidget, reason: route);
          expect(tester.takeException(), isNull, reason: route);
        }
        AppState.instance.themeMode.value = ThemeMode.dark;
      });

      testWidgets('renders every home tab', (tester) async {
        sizeView(tester, entry.value);
        await tester.pumpWidget(appAt(AppRoutes.home));
        for (var tab = 0; tab < 4; tab++) {
          AppState.instance.currentTab.value = tab;
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    });
  }

  testWidgets('pages show the logged-in student', (tester) async {
    sizeView(tester, const Size(390, 844));
    await tester.pumpWidget(appAt(AppRoutes.home));
    await tester.pumpAndSettle();
    expect(find.text(demoStudent.fullName), findsOneWidget);

    AppState.instance.currentTab.value = 3; // Profile
    await tester.pumpAndSettle();
    expect(find.text(demoStudent.fullName), findsWidgets);
    expect(find.text(demoStudent.email), findsOneWidget);
    expect(find.text('I23012345'), findsWidgets);
  });

  testWidgets('event registration is saved through the API', (tester) async {
    sizeView(tester, const Size(390, 844));
    final event = campusEvents.first;
    await tester.pumpWidget(appAt(AppRoutes.eventDetail));
    await tester.pumpAndSettle();

    final button = find.text('Register for this event');
    await tester.scrollUntilVisible(button.hitTestable(), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(api.lists['events'], {event.id});
    expect(find.text('Cancel registration'), findsOneWidget);
  });

  testWidgets('helpdesk ticket is saved and listed', (tester) async {
    sizeView(tester, const Size(390, 844));
    await tester.pumpWidget(appAt(AppRoutes.helpdesk));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Cannot connect to campus Wi-Fi');
    final submit = find.text('Submit ticket');
    await tester.scrollUntilVisible(submit.hitTestable(), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(api.tickets.single.message, 'Cannot connect to campus Wi-Fi');
    expect(find.text('My tickets (1)'), findsOneWidget);
  });

  testWidgets('photo upload shows on the virtual ID', (tester) async {
    sizeView(tester, const Size(390, 844));
    await tester.pumpWidget(appAt(AppRoutes.home));
    AppState.instance.currentTab.value = 3;
    await tester.pumpAndSettle();
    expect(find.text('Virtual student ID'), findsOneWidget);
    expect(find.text('Upload photo'), findsOneWidget);

    await AppState.instance.uploadPhoto([1, 2, 3]);
    await tester.pumpAndSettle();
    expect(api.photoUploads, 1);
    expect(find.text('Change photo'), findsOneWidget);
    expect(find.text('Remove photo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a shuttle card opens its route details', (tester) async {
    sizeView(tester, const Size(390, 844));
    await tester.pumpWidget(appAt(AppRoutes.shuttle));
    await tester.pumpAndSettle();
    final lineB = find.text('Line B');
    await tester.scrollUntilVisible(lineB.hitTestable(), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(lineB);
    await tester.pumpAndSettle();
    expect(find.text('Route map'), findsOneWidget);
    expect(find.text('Lincoln Hall'), findsWidgets);
    expect(find.text('Stops'), findsOneWidget);
  });

  testWidgets('profile edits are saved and shown', (tester) async {
    sizeView(tester, const Size(390, 844));
    await tester.pumpWidget(appAt(AppRoutes.home));
    AppState.instance.currentTab.value = 3;
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit profile'));
    await tester.pumpAndSettle();
    final residence = find.widgetWithText(TextFormField, 'Residence / hostel');
    await tester.enterText(residence, 'INTI Residence Block C');
    final save = find.text('Save changes');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(AppState.instance.me.residence, 'INTI Residence Block C');
    expect(find.text('INTI Residence Block C'), findsOneWidget);
  });
}

