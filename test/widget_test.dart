import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crimson_campus/main.dart';
import 'package:crimson_campus/state/app_state.dart';
import 'package:crimson_campus/widgets/campus_action_card.dart';
import 'package:crimson_campus/screens/campus_map_screen.dart';
import 'package:crimson_campus/widgets/landing_effects.dart';

import 'fake_campus_api.dart';

void main() {
  late FakeCampusApi api;

  setUp(() async {
    LandingMotion.enabled = false;
    CampusMapScreen.showTiles = false;
    api = FakeCampusApi()..seedAccount(demoStudent);
    AppState.instance.api = api;
    await AppState.instance.logout();
  });

  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('log in from the landing page and see your own name', (tester) async {
    await phone(tester);
    await tester.pumpWidget(const CrimsonCampusApp());
    expect(find.text('Crimson Campus'), findsOneWidget);
    expect(find.bySemanticsLabel('INTI logo'), findsWidgets);

    // The top-bar "Log in" scrolls down to the login form on the landing page.
    await tester.tap(find.text('Log in').first);
    await tester.pumpAndSettle();
    expect(find.text('Log in to your campus'), findsOneWidget);
    final idField = find.byType(TextFormField).at(0);
    final passwordField = find.byType(TextFormField).at(1);
    expect(idField.hitTestable(), findsOneWidget);

    // Wrong password shows an error and stays on the page.
    await tester.enterText(idField, 'I23012345');
    await tester.enterText(passwordField, 'wrong');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Incorrect email/student ID or password'), findsOneWidget);

    await tester.enterText(passwordField, 'secret123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('My Campus Today'), findsOneWidget);
    expect(find.text('Nur Aisyah Rahman'), findsOneWidget);
    expect(find.text('3.62'), findsOneWidget);

    // A service page saves to the backend.
    final libraryCard = find.ancestor(
      of: find.text('Library'),
      matching: find.byType(CampusActionCard),
    );
    await tester.scrollUntilVisible(libraryCard.hitTestable(), 120,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(libraryCard);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Renew').first);
    await tester.pumpAndSettle();
    expect(api.lists['library-renewals'], {'osc'});
  });

  testWidgets('create an account and land on a personalised dashboard', (tester) async {
    await phone(tester);
    await tester.pumpWidget(const CrimsonCampusApp());
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Set up your student account'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Daniel Tan Wei Ming');
    await tester.enterText(fields.at(1), 'I24099887');
    await tester.enterText(fields.at(2), 'daniel@student.inti.edu.my');
    await tester.enterText(fields.at(3), 'hunter22');
    await tester.enterText(fields.at(4), 'hunter22');

    // Programme is required.
    await tapVisible(tester, find.widgetWithText(InkWell, 'Create account'));
    expect(find.text('Choose your programme'), findsOneWidget);

    await tapVisible(tester, find.text('Programme'));
    await tester.tap(find.text('BSc (Hons) Software Engineering').last);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.widgetWithText(InkWell, 'Create account'));

    expect(find.text('My Campus Today'), findsOneWidget);
    expect(find.text('Daniel Tan Wei Ming'), findsOneWidget);
    expect(AppState.instance.me.id, 'I24099887');
  });

  testWidgets('protected pages ask for login first', (tester) async {
    await phone(tester);
    await tester.pumpWidget(const CrimsonCampusApp());
    final navigator = AppState.instance.navigatorKey.currentState!;
    navigator.pushNamed('/fees');
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('OUTSTANDING BALANCE'), findsNothing);
  });
}
