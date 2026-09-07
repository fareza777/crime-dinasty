import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vice_dynasty/engine/game_engine.dart';
import 'package:vice_dynasty/game_controller.dart';
import 'package:vice_dynasty/main.dart';
import 'package:vice_dynasty/screens/hub.dart';
import 'package:vice_dynasty/services/save_service.dart';
import 'package:vice_dynasty/theme/app_theme.dart';
import 'package:vice_dynasty/tour.dart';

import 'game_engine_test.dart' show loadCatalog;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('title screen renders and opens new game', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = GameController(saves: SaveService(memory: {}));
    c.catalog = loadCatalog();
    c.tourEnabled = false;
    c.view = AppView.title;
    await tester.pumpWidget(ViceApp(controller: c));
    expect(find.text('VICE DYNASTY'), findsOneWidget);
    expect(find.text('CRIME LIFE SIMULATOR'), findsOneWidget);
    await tester.tap(find.text('NEW GAME'));
    await tester.pumpAndSettle();
    expect(find.text('New game'), findsOneWidget);
    expect(find.text('Name + 2 traits to start'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.tap(find.text('Fill a sample character'));
    await tester.pump();
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(c.view, AppView.play);
    expect(find.text('Life'), findsOneWidget);
    expect(find.text('Family'), findsWidgets);
    expect(find.text('City'), findsOneWidget);
    expect(find.text('What happens this year'), findsWidgets);
    expect(find.text('Do something'), findsOneWidget);
    expect(find.text('Next year'), findsOneWidget);
  });

  testWidgets('hub more grid opens family history without dead ends', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = GameController(saves: SaveService(memory: {}));
    c.catalog = loadCatalog();
    c.tourEnabled = false;
    await c.startNewGame(
      first: 'Julian',
      last: 'Hart',
      gender: 'man',
      traits: const ['Ambitious', 'Cunning'],
    );
    await tester.pumpWidget(ViceApp(controller: c));
    await tester.pumpAndSettle();
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Dynasty'), findsWidgets);
    await tester.tap(find.text('Dynasty'));
    await tester.pumpAndSettle();
    expect(find.text('Dynasty'), findsWidgets);
    expect(find.textContaining('The name keeps cash'), findsOneWidget);
    final dynastyScroll = find.descendant(of: find.byType(LegacyPage), matching: find.byType(Scrollable));
    await tester.scrollUntilVisible(find.text('THE CIRCLE'), 240, scrollable: dynastyScroll);
    expect(find.text('THE CHAIR'), findsWidgets);
    expect(find.text('chair'), findsWidgets);
    expect(find.text('THE CIRCLE'), findsOneWidget);
  });

  testWidgets('help sheet shows how to play', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = GameController(saves: SaveService(memory: {}));
    c.catalog = loadCatalog();
    c.tourEnabled = false;
    await c.startNewGame(
      first: 'Julian',
      last: 'Hart',
      gender: 'man',
      traits: const ['Ambitious', 'Cunning'],
    );
    await tester.pumpWidget(ViceApp(controller: c));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('How to play'));
    await tester.pumpAndSettle();
    expect(find.text('How to play'), findsOneWidget);
    expect(find.text('1. Tap What happens this year.'), findsOneWidget);
    expect(find.textContaining('Sit with only one person each year'), findsOneWidget);
    expect(find.text('Replay tour'), findsOneWidget);
  });

  testWidgets('tour overlay is skippable from new game', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = GameController(saves: SaveService(memory: {}));
    c.catalog = loadCatalog();
    c.view = AppView.title;
    await tester.pumpWidget(ViceApp(controller: c));
    await tester.tap(find.text('NEW GAME'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.tourActive, isTrue);
    expect(find.text('Start here'), findsOneWidget);
    expect(find.text('Step 1 of 14'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pump();
    expect(c.tourActive, isFalse);
    expect(c.tourDone, isTrue);
  });

  testWidgets('tour spotlight keys move between real widgets', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = GameController(saves: SaveService(memory: {}));
    c.catalog = loadCatalog();
    c.view = AppView.title;
    await tester.pumpWidget(ViceApp(controller: c));
    await tester.tap(find.text('NEW GAME'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(Tour.steps[c.tourIndex].anchor, TourAnchor.newGame);
    expect(c.tourTargetKey(), c.tourKeys.newGame);
    expect(c.tourTargetKey()!.currentContext, isNotNull);

    await c.startNewGame(
      first: 'Julian',
      last: 'Hart',
      gender: 'man',
      traits: const ['Ambitious', 'Cunning'],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(Tour.steps[c.tourIndex].anchor, TourAnchor.yearCta);
    expect(c.tourTargetKey(), c.tourKeys.yearCta);
    expect(c.tourTargetKey()!.currentContext, isNotNull);
    expect(c.hubIndex, 0);

    c.nextTour();
    await tester.pump();
    expect(Tour.steps[c.tourIndex].anchor, TourAnchor.choice);

    c.nextTour();
    await tester.pump();
    expect(Tour.steps[c.tourIndex].anchor, TourAnchor.nextYear);
    expect(c.tourTargetKey(), c.tourKeys.nextYear);
    expect(c.tourTargetKey()!.currentContext, isNotNull);

    c.nextTour();
    await tester.pump();
    expect(Tour.steps[c.tourIndex].anchor, TourAnchor.navFamily);
    expect(c.tourTargetKey(), c.tourKeys.navFamily);
    expect(c.tourTargetKey()!.currentContext, isNotNull);

    await tester.tap(find.byKey(c.tourKeys.navFamily));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.hubIndex, 1);
    expect(Tour.steps[c.tourIndex].anchor, TourAnchor.familyTree);
    expect(c.tourTargetKey(), c.tourKeys.familyTree);
    expect(c.tourTargetKey()!.currentContext, isNotNull);

    c.nextTour();
    await tester.pump();
    expect(Tour.steps[c.tourIndex].anchor, TourAnchor.navCity);
    expect(c.tourTargetKey()!.currentContext, isNotNull);

    c.nextTour();
    await tester.pump();
    expect(c.hubIndex, 2);
    expect(Tour.steps[c.tourIndex].anchor, TourAnchor.cityDistrict);
    expect(c.tourTargetKey()!.currentContext, isNotNull);

    c.nextTour();
    await tester.pump();
    expect(Tour.steps[c.tourIndex].anchor, TourAnchor.navMore);
    c.nextTour();
    await tester.pump();
    expect(c.hubIndex, 3);
    expect(Tour.steps[c.tourIndex].anchor, TourAnchor.moreActivities);
    expect(c.tourTargetKey()!.currentContext, isNotNull);
  });

  testWidgets('Empire empty layout is readable on a small phone', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = GameController(saves: SaveService(memory: {}));
    c.catalog = loadCatalog();
    c.tourEnabled = false;
    await c.startNewGame(
      first: 'Julian',
      last: 'Hart',
      gender: 'man',
      traits: const ['Ambitious', 'Cunning'],
    );
    await tester.pumpWidget(ViceApp(controller: c));
    await tester.pumpAndSettle();
    c.setHub(3);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Empire'));
    await tester.pumpAndSettle();

    expect(find.text('The books'), findsOneWidget);
    expect(find.textContaining('No one on the books'), findsOneWidget);
    expect(find.textContaining('Hire a hand'), findsWidgets);
    final empireScroll = find.descendant(of: find.byType(EmpireScreen), matching: find.byType(Scrollable));
    await tester.scrollUntilVisible(find.textContaining('No fronts yet'), 240, scrollable: empireScroll);
    expect(find.textContaining('No fronts yet'), findsOneWidget);
    expect(find.byType(Scaffold), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Empire with crew and a front stays readable', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = GameController(saves: SaveService(memory: {}));
    c.catalog = loadCatalog();
    c.tourEnabled = false;
    await c.startNewGame(
      first: 'Julian',
      last: 'Hart',
      gender: 'man',
      traits: const ['Ambitious', 'Cunning'],
    );
    c.engine!.state.stats.money = 8000;
    expect(c.engine!.hireHand(), isNull);
    c.engine!.debugBusiness('club');
    await tester.pumpWidget(ViceApp(controller: c));
    await tester.pumpAndSettle();
    c.setHub(3);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Empire'));
    await tester.pumpAndSettle();

    expect(find.text('The books'), findsOneWidget);
    expect(find.text('Crew'), findsWidgets);
    expect(find.textContaining('Pay'), findsOneWidget);
    expect(find.text('Raise cut'), findsOneWidget);
    expect(find.text('Let go'), findsOneWidget);
    final empireList = find.descendant(of: find.byType(EmpireScreen), matching: find.byType(Scrollable));
    await tester.scrollUntilVisible(find.text('The Lantern Room'), 240, scrollable: empireList);
    expect(find.text('Fronts'), findsOneWidget);
    expect(find.text('The Lantern Room'), findsOneWidget);
    expect(find.text('INCOME'), findsWidgets);
    expect(find.text('RISK'), findsOneWidget);
    expect(find.textContaining('Invest'), findsOneWidget);
    expect(find.text('Assign'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Life shows ambition and a year-close card after next year', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = GameController(saves: SaveService(memory: {}));
    c.catalog = loadCatalog();
    c.tourEnabled = false;
    await c.startNewGame(
      first: 'Julian',
      last: 'Hart',
      gender: 'man',
      traits: const ['Ambitious', 'Cunning'],
    );
    await tester.pumpWidget(ViceApp(controller: c));
    await tester.pump();
    expect(find.text('THIS YEAR'), findsOneWidget);
    expect(c.engine!.ambition(), isNotEmpty);

    await c.seeYear();
    await tester.pump();
    final ev = c.engine!.currentEvent();
    expect(ev, isNotNull);
    await c.choose(c.engine!.choicesFor(ev!).firstWhere((ch) => ch.enabled).choice.id);
    c.dismissOutcome();
    await c.nextYear();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.engine!.state.lastYearLog, isNotEmpty);
    final lifeScroll = find.descendant(of: find.byType(LifeScreen), matching: find.byType(Scrollable));
    await tester.scrollUntilVisible(find.text('WHEN THE YEAR CLOSED'), 200, scrollable: lifeScroll);
    expect(find.text('WHEN THE YEAR CLOSED'), findsOneWidget);
  });

  testWidgets('Family sit is once per year and hides on the others', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = GameController(saves: SaveService(memory: {}));
    c.catalog = loadCatalog();
    c.tourEnabled = false;
    await c.startNewGame(
      first: 'Julian',
      last: 'Hart',
      gender: 'man',
      traits: const ['Ambitious', 'Cunning'],
    );
    await tester.pumpWidget(ViceApp(controller: c));
    await tester.pump();
    c.setHub(1);
    await tester.pump();
    expect(find.textContaining('Sit with one person this year'), findsOneWidget);
    expect(find.textContaining('Gift one person this year'), findsOneWidget);
    expect(find.text('Sit'), findsWidgets);

    await tester.tap(find.text('Sit').first);
    await tester.pump();
    expect(find.text('A quiet hour'), findsOneWidget);
    expect(c.engine!.satThisYear, isTrue);
    await tester.tap(find.text('OK'));
    await tester.pump();

    expect(find.textContaining('Sat with'), findsWidgets);
    expect(find.text('Sat with them this year.'), findsOneWidget);
    expect(find.text('Already sat with someone this year.'), findsWidgets);
    expect(find.text('Sit'), findsNothing);
    expect(find.textContaining('Gift'), findsWidgets);
    expect(find.textContaining('Already sat with someone this year'), findsWidgets);
    expect(find.textContaining('Gift ·'), findsWidgets);
  });

  testWidgets('Family gift is once per year and independent of Sit', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = GameController(saves: SaveService(memory: {}));
    c.catalog = loadCatalog();
    c.tourEnabled = false;
    await c.startNewGame(
      first: 'Julian',
      last: 'Hart',
      gender: 'man',
      traits: const ['Ambitious', 'Cunning'],
    );
    c.engine!.state.stats.money = 800;
    await tester.pumpWidget(ViceApp(controller: c));
    await tester.pump();
    c.setHub(1);
    await tester.pump();
    expect(find.textContaining('Gift ·'), findsWidgets);

    await tester.tap(find.textContaining('Gift ·').first);
    await tester.pump();
    expect(c.engine!.giftedThisYear, isTrue);
    expect(find.text('Gifted them this year.'), findsOneWidget);
    expect(find.text('Already gifted someone this year.'), findsWidgets);
    expect(find.textContaining('Gift ·'), findsNothing);
    expect(find.text('Sit'), findsWidgets);

    await tester.tap(find.text('Sit').first);
    await tester.pump();
    expect(find.text('A quiet hour'), findsOneWidget);
    expect(c.engine!.satThisYear, isTrue);
    await tester.tap(find.text('OK'));
    await tester.pump();
    expect(c.engine!.satThisYear, isTrue);
    expect(c.engine!.giftedThisYear, isTrue);
    expect(find.text('Sit'), findsNothing);
    expect(find.textContaining('Gift ·'), findsNothing);
  });

  testWidgets('Life has no permanent year-step coaching', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = GameController(saves: SaveService(memory: {}));
    c.catalog = loadCatalog();
    c.tourEnabled = false;
    expect(c.darkMode, isTrue);
    expect(Palette.light, isFalse);
    await c.startNewGame(
      first: 'Julian',
      last: 'Hart',
      gender: 'man',
      traits: const ['Ambitious', 'Cunning'],
    );
    await tester.pumpWidget(ViceApp(controller: c));
    await tester.pump();
    expect(find.text('See the card'), findsNothing);
    expect(find.textContaining('SEE THE CARD'), findsNothing);
    expect(find.textContaining('PICK ONCE'), findsNothing);
    expect(find.textContaining('1 SEE THE CARD'), findsNothing);
    expect(find.textContaining('2/3'), findsNothing);
    expect(find.textContaining('See the card | pick once'), findsNothing);
    expect(find.text('What happens this year'), findsWidgets);
  });

  testWidgets('Event choices do not spoil rewards', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = GameController(saves: SaveService(memory: {}));
    c.catalog = loadCatalog();
    c.tourEnabled = false;
    await c.startNewGame(
      first: 'Julian',
      last: 'Hart',
      gender: 'man',
      traits: const ['Ambitious', 'Cunning'],
    );
    await tester.pumpWidget(ViceApp(controller: c));
    await tester.pump();
    await c.seeYear();
    await tester.pump();
    final ev = c.engine!.currentEvent();
    expect(ev, isNotNull);
    expect(find.textContaining('2/3'), findsNothing);
    expect(find.textContaining('Pick one. Gold is suggested'), findsNothing);
    expect(find.textContaining('pay ·'), findsNothing);
    expect(find.text('heat · bond'), findsNothing);
    for (final ch in c.engine!.choicesFor(ev!)) {
      final hint = GameEngine.choiceHint(ch.choice);
      if (hint.isNotEmpty) {
        expect(find.text(hint), findsNothing);
      }
    }
    expect(find.textContaining('Suggested —'), findsWidgets);
  });

  testWidgets('Settings defaults to dark and can toggle paper', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = GameController(saves: SaveService(memory: {}));
    c.catalog = loadCatalog();
    c.tourEnabled = false;
    await c.startNewGame(
      first: 'Julian',
      last: 'Hart',
      gender: 'man',
      traits: const ['Ambitious', 'Cunning'],
    );
    expect(c.darkMode, isTrue);
    expect(Palette.light, isFalse);
    await tester.pumpWidget(ViceApp(controller: c));
    await tester.pumpAndSettle();
    c.setHub(3);
    await tester.pumpAndSettle();
    expect(find.text('Dynasty'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(SwitchListTile, 'Dark mode'), findsOneWidget);
    expect(find.textContaining('Night is the default'), findsOneWidget);
    await c.toggleDarkMode();
    await tester.pump();
    expect(c.darkMode, isFalse);
    expect(Palette.light, isTrue);
    expect(find.textContaining('Soft paper'), findsOneWidget);
    final settingsScroll = find.descendant(of: find.byType(SettingsPage), matching: find.byType(Scrollable));
    await tester.scrollUntilVisible(find.text('Vice Dynasty 1.9.3'), 240, scrollable: settingsScroll);
    expect(find.text('Vice Dynasty 1.9.3'), findsOneWidget);
  });

  testWidgets('Dynasty label is fully visible on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = GameController(saves: SaveService(memory: {}));
    c.catalog = loadCatalog();
    c.tourEnabled = false;
    await c.startNewGame(
      first: 'Julian',
      last: 'Hart',
      gender: 'man',
      traits: const ['Ambitious', 'Cunning'],
    );
    await tester.pumpWidget(ViceApp(controller: c));
    await tester.pumpAndSettle();
    c.setHub(3);
    await tester.pumpAndSettle();
    final moreScroll = find.descendant(of: find.byType(MoreScreen), matching: find.byType(Scrollable));
    await tester.scrollUntilVisible(find.text('Dynasty'), 200, scrollable: moreScroll);

    void expectFullDynasty(Finder finder) {
      expect(finder, findsWidgets);
      expect(find.textContaining('…'), findsNothing);
      expect(find.textContaining('Dynas'), findsWidgets);
      for (final el in finder.evaluate()) {
        expect(el.widget, isA<Text>());
        final text = el.widget as Text;
        expect(text.data, 'Dynasty');
        expect(text.overflow, isNot(TextOverflow.ellipsis));
        final ro = el.renderObject;
        expect(ro, isA<RenderParagraph>());
        final para = ro! as RenderParagraph;
        expect(para.text.toPlainText(), 'Dynasty');
        expect(para.didExceedMaxLines, isFalse);
        expect(para.size.width, greaterThan(50));
      }
    }

    expectFullDynasty(find.text('Dynasty'));
    await tester.tap(find.text('Dynasty'));
    await tester.pumpAndSettle();
    expect(find.byType(LegacyPage), findsOneWidget);
    expectFullDynasty(find.descendant(of: find.byType(AppBar), matching: find.text('Dynasty')));
  });
}
