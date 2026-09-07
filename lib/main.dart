import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_controller.dart';
import 'art.dart';
import 'screens/hub.dart';
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
            Center(child: CircularProgressIndicator(color: Palette.gold)),
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
      case AppView.title:
      case AppView.boot:
        page = TitleScreen(c: c);
        break;
    }
    return Stack(
      children: [
        page,
        if (c.tourActive && c.tourEnabled && !c.showHelp && (c.view == AppView.newGame || c.view == AppView.play))
          Positioned.fill(
            child: CoachMarkLayer(
              stepIndex: c.tourIndex,
              targetKey: c.tourTargetKey(),
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
