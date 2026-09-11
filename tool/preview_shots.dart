import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vice_dynasty/art.dart';
import 'package:vice_dynasty/game_controller.dart';
import 'package:vice_dynasty/main.dart';
import 'package:vice_dynasty/screens/hub.dart';
import 'package:vice_dynasty/services/save_service.dart';
import 'package:vice_dynasty/theme/app_theme.dart';

import '../test/game_engine_test.dart' show loadCatalog;

const _outs = [
  '/opt/cursor/artifacts/preview',
  'docs/preview',
];

Future<void> _loadPreviewFonts() async {
  Future<void> load(String family, List<String> assets) async {
    final loader = FontLoader(family);
    for (final a in assets) {
      loader.addFont(rootBundle.load(a));
    }
    await loader.load();
  }

  await load('Cinzel', [
    'assets/fonts/Cinzel-Regular.ttf',
    'assets/fonts/Cinzel-SemiBold.ttf',
    'assets/fonts/Cinzel-Bold.ttf',
  ]);
  await load('DMSans', [
    'assets/fonts/DMSans-Regular.ttf',
    'assets/fonts/DMSans-Medium.ttf',
    'assets/fonts/DMSans-Bold.ttf',
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture 1.9.3 phone preview PNGs', (tester) async {
    await _loadPreviewFonts();
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await tester.binding.setSurfaceSize(const Size(390, 844));

    final shotKey = GlobalKey();
    final c = GameController(saves: SaveService(memory: {}));
    c.catalog = loadCatalog();
    c.tourEnabled = false;
    c.audio.musicOn = false;
    c.audio.sfxOn = false;
    c.view = AppView.title;
    expect(c.darkMode, isTrue);
    expect(Palette.light, isFalse);

    await tester.pumpWidget(
      RepaintBoundary(
        key: shotKey,
        child: ViceApp(controller: c),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.runAsync(() async {
      final ctx = tester.element(find.byType(ViceApp));
      for (final path in [
        Art.titlePoster,
        Art.cover,
        Art.splash,
        Art.event('docks'),
        Art.event('skyline'),
        Art.event('sit'),
        Art.header('settings'),
        Art.header('legacy'),
        Art.header('empire'),
        Art.choice,
      ]) {
        await precacheImage(AssetImage(path), ctx);
      }
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await _shot(tester, shotKey, '01_title.png');
    await _shot(tester, shotKey, '01_title_dark.png');

    c.goNew();
    await tester.pump();
    await tester.tap(find.text('Fill a sample character'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await _shot(tester, shotKey, '02_new_game.png');

    await c.startNewGame(
      first: 'Julian',
      last: 'Hart',
      gender: 'man',
      traits: const ['Ambitious', 'Cunning'],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _shot(tester, shotKey, '03_life.png');
    await _shot(tester, shotKey, '03_life_dark.png');
    expect(find.textContaining('SEE THE CARD'), findsNothing);
    expect(find.textContaining('See the card'), findsNothing);

    c.setHub(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await _shot(tester, shotKey, '06_family_sit.png');

    final sit = find.text('Sit');
    expect(sit, findsWidgets);
    await tester.tap(sit.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('A quiet hour'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await _shot(tester, shotKey, '07_family_sat.png');

    c.engine!.state.stats.money = 800;
    await tester.pump();
    expect(find.textContaining('Gift ·'), findsWidgets);
    await tester.tap(find.textContaining('Gift ·').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Already gifted someone this year.'), findsWidgets);
    await _shot(tester, shotKey, '07_family_gift.png');

    c.setHub(2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await _shot(tester, shotKey, '08_city.png');

    c.setHub(3);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final moreScroll = find.descendant(of: find.byType(MoreScreen), matching: find.byType(Scrollable));
    await tester.scrollUntilVisible(find.text('Dynasty'), 180, scrollable: moreScroll);
    await tester.pump();
    await _shot(tester, shotKey, '10_more.png');
    await _shot(tester, shotKey, '10_more_dark.png');
    expect(find.text('Dynasty'), findsOneWidget);

    Future<void> pushPage(Widget page) async {
      final nav = Navigator.of(tester.element(find.byType(MoreScreen)));
      nav.push(MaterialPageRoute(builder: (_) => page));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    c.engine!.debugBirth();
    await pushPage(LegacyPage(c: c));
    expect(find.textContaining('The name keeps cash'), findsOneWidget);
    expect(find.text('Dynasty'), findsWidgets);
    final dynastyScroll = find.descendant(of: find.byType(LegacyPage), matching: find.byType(Scrollable));
    await tester.scrollUntilVisible(find.text('The tree'), 220, scrollable: dynastyScroll);
    await tester.pump();
    await _shot(tester, shotKey, '11_dynasty.png');
    await _shot(tester, shotKey, '11_dynasty_dark.png');
    Navigator.of(tester.element(find.byType(LegacyPage))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    c.engine!.state.stats.money = 2400;
    await pushPage(EmpireScreen(c: c));
    expect(find.byType(EmpireScreen), findsOneWidget);
    final empireScroll = find.descendant(of: find.byType(EmpireScreen), matching: find.byType(Scrollable));
    await tester.scrollUntilVisible(find.textContaining('Open a front'), 240, scrollable: empireScroll);
    await tester.pump();
    await _shot(tester, shotKey, '09_empire.png');
    Navigator.of(tester.element(find.byType(EmpireScreen))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await pushPage(SettingsPage(c: c));
    expect(find.text('Dark mode'), findsOneWidget);
    expect(find.textContaining('Night is the default'), findsOneWidget);
    await tester.pump();
    await _shot(tester, shotKey, '13_settings.png');
    await _shot(tester, shotKey, '13_settings_dark.png');
    Navigator.of(tester.element(find.byType(SettingsPage))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    c.engine!.debugStartWar();
    c.setHub(2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await _shot(tester, shotKey, '12_war.png');

    c.setHub(0);
    await tester.pump();
    await c.seeYear();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(c.engine!.currentEvent(), isNotNull);
    expect(find.textContaining('2/3'), findsNothing);
    await _shot(tester, shotKey, '04_event_choice.png');
    await _shot(tester, shotKey, '04_event_choice_dark.png');

    final ev = c.engine!.currentEvent()!;
    final choice = c.engine!.choicesFor(ev).firstWhere((ch) => ch.enabled);
    await c.choose(choice.choice.id);
    await tester.pump();
    c.dismissOutcome();
    await tester.pump();
    await c.nextYear();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    final lifeScroll = find.descendant(of: find.byType(LifeScreen), matching: find.byType(Scrollable));
    await tester.scrollUntilVisible(find.text('WHEN THE YEAR CLOSED'), 220, scrollable: lifeScroll);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await _shot(tester, shotKey, '05_year_close.png');

    await c.toggleDarkMode();
    expect(c.darkMode, isFalse);
    expect(Palette.light, isTrue);
    c.setHub(0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await _shot(tester, shotKey, '03_life_light.png');

    c.setHub(3);
    await tester.pump();
    await pushPage(SettingsPage(c: c));
    expect(find.textContaining('Soft paper'), findsOneWidget);
    await tester.pump();
    await _shot(tester, shotKey, '13_settings_light.png');
    Navigator.of(tester.element(find.byType(SettingsPage))).pop();
    await tester.pump();

    c.goTitle();
    await tester.pump();
    await tester.runAsync(() async {
      final ctx = tester.element(find.byType(ViceApp));
      await precacheImage(const AssetImage(Art.titlePoster), ctx);
      await precacheImage(const AssetImage(Art.splash), ctx);
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _shot(tester, shotKey, '01_title_light.png');
  });
}

Future<void> _shot(WidgetTester tester, GlobalKey key, String name) async {
  await tester.pump();
  final ro = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await tester.runAsync(() => ro.toImage(pixelRatio: 2));
  expect(image, isNotNull);
  final data = await tester.runAsync(() => image!.toByteData(format: ui.ImageByteFormat.png));
  expect(data, isNotNull);
  final bytes = data!.buffer.asUint8List();
  expect(bytes.length, greaterThan(8000));
  for (final dir in _outs) {
    Directory(dir).createSync(recursive: true);
    File('$dir/$name').writeAsBytesSync(bytes);
  }
}
