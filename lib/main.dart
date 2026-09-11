import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_controller.dart';
import 'art.dart';
import 'screens/hub.dart';
import 'screens/opening.dart';
import 'screens/title_screens.dart';
import 'theme/app_theme.dart';
import 'widgets/coach_mark.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details, forceReport: kDebugMode);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught: $error\n$stack');
    return true;
  };
  try {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  } catch (_) {}
  try {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  } catch (_) {}

  final c = GameController();
  runApp(ViceApp(controller: c));
  // First frame (splash/title spinner) before any Play/AdMob/Billing work.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(c.boot());
  });
}

class ViceApp extends StatelessWidget {
  const ViceApp({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        Palette.light = !controller.darkMode;
        try {
          SystemChrome.setSystemUIOverlayStyle(Palette.overlay);
        } catch (_) {}
        return MaterialApp(
          title: 'Vice Dynasty',
          debugShowCheckedModeBanner: false,
          theme: controller.darkMode ? AppTheme.dark : AppTheme.paper,
          home: _Root(c: controller),
        );
      },
    );
  }
}

class _Root extends StatelessWidget {
  const _Root({required this.c});
  final GameController c;

  @override
  Widget build(BuildContext context) {
    if (c.view == AppView.boot) {
      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(Art.splash, fit: BoxFit.cover, errorBuilder: (_, _, _) => ColoredBox(color: Palette.navy)),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Palette.navy.withValues(alpha: 0.15),
                    Palette.navy.withValues(alpha: 0.55),
                    Palette.navy.withValues(alpha: 0.78),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
                child: Column(
                  children: [
                    const Spacer(),
                    Image.asset(Art.logoPlate, height: 72, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                    const SizedBox(height: 16),
                    Text(
                      'VICE DYNASTY',
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        color: Palette.gold,
                        fontSize: 28,
                        letterSpacing: 2.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The rain is still deciding.',
                      style: TextStyle(color: Palette.cream.withValues(alpha: 0.8), fontSize: 13),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 1.6, color: Palette.gold.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    Widget page;
    switch (c.view) {
      case AppView.newGame:
        page = NewGameScreen(c: c);
        break;
      case AppView.load:
        page = LoadScreen(c: c);
        break;
      case AppView.play:
        page = HubShell(c: c);
        break;
      case AppView.opening:
        page = OpeningScreen(c: c);
        break;
      case AppView.title:
      case AppView.boot:
        page = TitleScreen(c: c);
        break;
    }
    return Stack(
      children: [
        page,
        if (c.tourActive && c.tourEnabled && !c.showHelp && c.view == AppView.play)
          Positioned.fill(
            child: CoachMarkLayer(
              stepIndex: c.tourIndex,
              targetKey: c.tourTargetKey(),
              measureToken: c.tourMeasureToken,
              onNext: c.nextTour,
              onSkip: c.skipTour,
            ),
          ),
        if (c.toast != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Material(
              color: Palette.charcoal,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(c.toast!, style: TextStyle(color: Palette.cream)),
              ),
            ),
          ),
      ],
    );
  }
}
