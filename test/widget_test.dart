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
import 'package:vice_dynasty/widgets/common.dart';

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
    final lockup = tester.renderObject<RenderParagraph>(find.text('VICE DYNASTY'));
    expect(lockup.didExceedMaxLines, isFalse);
    expect(lockup.size.width, greaterThan(80));
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
    expect(find.text('City'), findsWidgets);
    expect(find.text('What happens this year'), findsWidgets);
    expect(find.text('THIS YEAR\'S MOVES'), findsOneWidget);
    expect(find.text('Sit with someone'), findsOneWidget);
    expect(find.text('Do something'), findsNothing);
    expect(c.engine!.yearEventPending, isTrue);
    expect(find.text('Next year'), findsNothing);
  });

  testWidgets('title lockup stays whole on a short phone', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = GameController(saves: SaveService(memory: {}));
    c.catalog = loadCatalog();
    c.tourEnabled = false;
    c.view = AppView.title;
    await tester.pumpWidget(ViceApp(controller: c));
    expect(find.text('VICE DYNASTY'), findsOneWidget);
    expect(find.text('CRIME LIFE SIMULATOR'), findsOneWidget);
    expect(find.textContaining('…'), findsNothing);
    final lockup = tester.renderObject<RenderParagraph>(find.text('VICE DYNASTY'));
    expect(lockup.didExceedMaxLines, isFalse);
    expect(lockup.size.width, greaterThan(80));
    expect(tester.takeException(), isNull);
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
    await tester.pump();
    expect(find.text('How to play'), findsOneWidget);
    expect(find.textContaining('Tap What happens this year'), findsOneWidget);
    expect(find.textContaining('a job or a street'), findsOneWidget);
    expect(find.textContaining('Prologue years only need the card'), findsOneWidget);
    expect(find.textContaining('Game Over, no heir'), findsOneWidget);
    expect(find.text('Replay tour'), findsOneWidget);
  });

  testWidgets('new game Start works while the tour is still pending', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = GameController(saves: SaveService(memory: {}));
    c.catalog = loadCatalog();
    c.view = AppView.title;
    expect(c.tourEnabled, isTrue);
    expect(c.tourDone, isFalse);
    await tester.pumpWidget(ViceApp(controller: c));
    await tester.tap(find.text('NEW GAME'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.tourActive, isFalse);
    expect(find.text('Start here'), findsNothing);
    expect(find.text('Fill a sample character'), findsOneWidget);
    await tester.tap(find.text('Fill a sample character'));
    await tester.pump();
    expect(find.text('Start'), findsOneWidget);
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.view, AppView.play);
    expect(c.tourActive, isTrue);
    expect(Tour.steps[c.tourIndex].anchor, TourAnchor.yearCta);
    expect(find.text('Open the year'), findsOneWidget);
    expect(find.textContaining('Step 1 of ${Tour.length}'), findsOneWidget);
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
    expect(c.tourActive, isFalse);

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

    await c.seeYear();
    await tester.pump();
    expect(Tour.steps[c.tourIndex].anchor, TourAnchor.choice);
    expect(c.tourTargetKey(), c.tourKeys.choice);
    expect(c.tourTargetKey()!.currentContext, isNotNull);

    final ev = c.engine!.currentEvent();
    expect(ev, isNotNull);
    await c.choose(c.engine!.choicesFor(ev!).firstWhere((ch) => ch.enabled).choice.id);
    await tester.pump();
    expect(Tour.steps[c.tourIndex].anchor, TourAnchor.outcome);
    expect(c.tourTargetKey(), c.tourKeys.outcome);
    expect(c.tourTargetKey()!.currentContext, isNotNull);

    c.dismissOutcome();
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
    expect(find.textContaining('hire a hand'), findsWidgets);
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
    c.engine!.state.flags.remove('empire_year_${c.engine!.state.year}');
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
    final hired = c.engine!.state.people[c.engine!.state.crew.first.personId]!;
    expect(hired.portraitKey, isNotEmpty);
    expect(
      find.byWidgetPredicate((w) => w is PixelPortrait && w.person.id == hired.id),
      findsOneWidget,
    );
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
    expect(find.textContaining('Suggested —'), findsNothing);
    expect(find.textContaining('pay ·'), findsNothing);
    for (final ch in c.engine!.choicesFor(ev!)) {
      final hint = GameEngine.choiceHint(ch.choice);
      if (hint.isNotEmpty) {
        expect(find.text(hint), findsNothing);
      }
      expect(find.text('${ch.choice.text}  (${ch.reason})'), findsNothing);
    }
    expect(find.textContaining('Need nerve'), findsNothing);
    expect(find.textContaining('Need \$'), findsNothing);
  });

  testWidgets('next year continues after the year card', (tester) async {
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
    final year = c.engine!.state.year;
    await tester.pumpWidget(ViceApp(controller: c));
    await tester.pump();
    await c.seeYear();
    await tester.pump();
    final ev = c.engine!.currentEvent();
    expect(ev, isNotNull);
    await c.choose(c.engine!.choicesFor(ev!).firstWhere((ch) => ch.enabled).choice.id);
    c.dismissOutcome();
    await tester.pump();
    expect(c.engine!.canAgeUp, isTrue);
    expect(find.text('Next year'), findsWidgets);
    await tester.tap(find.text('Next year'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.engine!.state.year, year + 1);
    expect(find.text('What happens this year'), findsWidgets);
  });

  testWidgets('tour glow walk can close a year', (tester) async {
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
    await c.startNewGame(
      first: 'Julian',
      last: 'Hart',
      gender: 'man',
      traits: const ['Ambitious', 'Cunning'],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(Tour.steps[c.tourIndex].anchor, TourAnchor.yearCta);
    final year = c.engine!.state.year;
    await tester.tap(find.text('What happens this year'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(c.engine!.currentEvent(), isNotNull);
    expect(Tour.steps[c.tourIndex].anchor, TourAnchor.choice);
    final ev = c.engine!.currentEvent()!;
    await c.choose(c.engine!.choicesFor(ev).firstWhere((ch) => ch.enabled).choice.id);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(Tour.steps[c.tourIndex].anchor, TourAnchor.outcome);
    c.dismissOutcome();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(Tour.steps[c.tourIndex].anchor, TourAnchor.nextYear);
    expect(c.engine!.canAgeUp, isTrue);
    await tester.tap(find.text('Next year'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(c.engine!.state.year, year + 1);
  });

  testWidgets('missing tour spotlight does not block the year button', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = GameController(saves: SaveService(memory: {}));
    c.catalog = loadCatalog();
    c.tourEnabled = true;
    await c.startNewGame(
      first: 'Julian',
      last: 'Hart',
      gender: 'man',
      traits: const ['Ambitious', 'Cunning'],
    );
    c.tourActive = true;
    c.tourIndex = Tour.steps.indexWhere((s) => s.anchor == TourAnchor.choice);
    await tester.pumpWidget(ViceApp(controller: c));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(c.engine!.currentEvent(), isNull);
    await tester.tap(find.text('What happens this year'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(c.engine!.currentEvent(), isNotNull);
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
    await tester.scrollUntilVisible(find.text('Vice Dynasty 1.9.11'), 240, scrollable: settingsScroll);
    expect(find.text('Vice Dynasty 1.9.11'), findsOneWidget);
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
