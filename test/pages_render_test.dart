import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crimson_campus/data/sample_data.dart';
import 'package:crimson_campus/models/student.dart';
import 'package:crimson_campus/prototype/prototype_switcher.dart';
import 'package:crimson_campus/routes.dart';
import 'package:crimson_campus/state/app_state.dart';
import 'package:crimson_campus/theme/app_theme.dart';
import 'package:crimson_campus/screens/campus_map_screen.dart';
import 'package:crimson_campus/screens/ticket_screens.dart';
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
      final routes = [...AppRoutes.routes.keys, AppRoutes.eventDetail, AppRoutes.shuttleRoute, AppRoutes.ticketDetail];
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

    Future<void> tapVisible(Finder finder) async {
      await tester.scrollUntilVisible(finder.hitTestable(), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(finder.hitTestable());
      await tester.pumpAndSettle();
    }

    // Step 1: student details come from the profile.
    expect(find.text('Request completion'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    await tapVisible(find.text('Next'));
    // Step 2: request details. Next is refused until it is complete.
    await tapVisible(find.text('Next'));
    expect(find.text('Request details'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Subject'), 'Wi-Fi down');
    await tester.enterText(find.widgetWithText(TextField, 'Describe your issue'), 'Cannot connect to campus Wi-Fi');
    await tapVisible(find.text('High'));
    await tapVisible(find.text('Next'));
    // Step 3: preferred date and contact method.
    await tapVisible(find.text('Today'));
    await tapVisible(find.text('Email'));
    await tapVisible(find.text('Next'));
    // Step 4: confirm and submit.
    expect(find.text('Confirmation details'), findsOneWidget);
    await tapVisible(find.byType(Checkbox));
    expect(find.text('100%'), findsOneWidget);
    await tapVisible(find.text('Submit ticket'));

    final saved = api.tickets.single;
    expect(saved.message, 'Cannot connect to campus Wi-Fi');
    expect(saved.subject, 'Wi-Fi down');
    expect(saved.priority, 'High');
    expect(saved.contactMethod, 'Email');
    expect(saved.preferredDate, isNotNull);
    // Raising a ticket opens its details.
    expect(find.text('Your message'), findsOneWidget);
    expect(find.text('Your preference'), findsOneWidget);
    expect(find.text('Ticket submitted'), findsOneWidget);
    expect(find.text('Cannot connect to campus Wi-Fi'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('My tickets (1)'), findsOneWidget);
  });

  testWidgets('ticket history filters, searches and opens a ticket', (tester) async {
    sizeView(tester, const Size(390, 844));
    final state = AppState.instance;
    await state.raiseTicket(const TicketRequest(category: 'Hostel', message: 'Air conditioner in room B-12 is leaking water'));
    await state.raiseTicket(const TicketRequest(category: 'Fees', message: 'Hostel fee shows twice on my statement'));
    await state.raiseTicket(const TicketRequest(category: 'IT & Wi-Fi', message: 'Library printer does not accept my card'));

    await tester.pumpWidget(appAt(AppRoutes.helpdesk));
    await tester.pumpAndSettle();
    // Helpdesk shows the latest three and links to the full history.
    expect(find.text('My tickets (3)'), findsOneWidget);
    final viewAll = find.text('View all');
    await tester.scrollUntilVisible(viewAll.hitTestable(), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(viewAll);
    await tester.pumpAndSettle();
    expect(find.text('Ticket history'), findsOneWidget);

    // Category filter.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Fees'));
    await tester.pumpAndSettle();
    expect(find.text('Showing 1 of 3'), findsOneWidget);
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('Showing 3 of 3'), findsOneWidget);

    // Date filter: every ticket was raised within the last week.
    await tester.tap(find.text('Last 7 days'));
    await tester.pumpAndSettle();
    expect(find.text('Showing 3 of 3'), findsOneWidget);

    // Grid view shows the same tickets as cards.
    await tester.tap(find.byTooltip('Grid view'));
    await tester.pumpAndSettle();
    expect(find.byType(TicketGridCard), findsWidgets);
    await tester.tap(find.byTooltip('List view'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'printer');
    await tester.pumpAndSettle();
    expect(find.textContaining('Library printer'), findsOneWidget);
    expect(find.textContaining('Air conditioner'), findsNothing);

    final printer = find.textContaining('Library printer');
    await tester.scrollUntilVisible(printer.hitTestable(), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(printer.hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Your message'), findsOneWidget);
    expect(find.text('Library printer does not accept my card'), findsOneWidget);
    expect(find.text('IT & Wi-Fi'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation menu shows as a grid and as a list behind the menu icon', (tester) async {
    sizeView(tester, const Size(390, 844));
    await tester.pumpWidget(appAt(AppRoutes.home));
    await tester.pumpAndSettle();

    // Grid view is on the dashboard; the list is hidden until the menu icon is tapped.
    expect(find.text('Navigation'), findsOneWidget);
    expect(find.text('Menu'), findsNothing);
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('Menu'), findsOneWidget);
    expect(find.text('ACADEMICS'), findsOneWidget);

    // Picking a page closes the list and opens the page.
    await tester.tap(find.widgetWithText(ListTile, 'Fees'));
    await tester.pumpAndSettle();
    expect(find.text('Menu'), findsNothing);
    expect(find.text('Fees'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // The list button in the grid header opens the same list; tabs switch in place.
    final listView = find.byTooltip('List view');
    await tester.scrollUntilVisible(listView.hitTestable(), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(listView.hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Menu'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, 'Profile'));
    await tester.pumpAndSettle();
    expect(AppState.instance.currentTab.value, 3);

    // The other tabs have ☰ in the top-left too, in place of a back arrow.
    for (final (tab, title) in const [(1, 'Timetable'), (2, 'Campus life'), (3, 'Profile')]) {
      AppState.instance.currentTab.value = tab;
      await tester.pumpAndSettle();
      final appBar = find.widgetWithText(AppBar, title);
      expect(find.descendant(of: appBar, matching: find.byType(BackButton)), findsNothing);
      await tester.tap(find.descendant(of: appBar, matching: find.byTooltip('Open navigation menu')));
      await tester.pumpAndSettle();
      expect(find.text('Menu'), findsOneWidget, reason: '$title tab');
      await tester.tap(find.byTooltip('Close menu'));
      await tester.pumpAndSettle();
    }
    // Pages opened on their own keep their back arrow.
    AppState.instance.navigatorKey.currentState!.pushNamed(AppRoutes.fees);
    await tester.pumpAndSettle();
    final feesBar = find.widgetWithText(AppBar, 'Fees');
    expect(find.descendant(of: feesBar, matching: find.byTooltip('Open navigation menu')), findsNothing);
    expect(find.descendant(of: feesBar, matching: find.byType(BackButton)), findsOneWidget);
    expect(tester.takeException(), isNull);
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

