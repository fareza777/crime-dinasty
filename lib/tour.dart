import 'package:flutter/material.dart';

enum TourAnchor {
  newGame,
  yearCta,
  choice,
  outcome,
  nextYear,
  navFamily,
  familyTree,
  navCity,
  cityDistrict,
  navMore,
  moreActivities,
  moreRelations,
  moreCourt,
  moreLegacy,
  moreSettings,
}

class TourStep {
  const TourStep({
    required this.anchor,
    required this.title,
    required this.body,
    this.hubIndex,
    this.waitForTap = true,
  });
  final TourAnchor anchor;
  final String title;
  final String body;
  /// Life 0 · Family 1 · City 2 · More 3. Null leaves the current tab.
  final int? hubIndex;
  /// When true, the tip has no Next — the player taps the glowing control.
  final bool waitForTap;

  GlobalKey? keyOf(TourKeys keys) => keys.forAnchor(anchor);
}

class Tour {
  static const steps = <TourStep>[
    TourStep(
      anchor: TourAnchor.yearCta,
      title: 'Open the year',
      body: 'Tap the glowing button. That card is the year.',
      hubIndex: 0,
    ),
    TourStep(
      anchor: TourAnchor.choice,
      title: 'Pick a line',
      body: 'Tap one answer. The city does not preview the cost.',
      hubIndex: 0,
    ),
    TourStep(
      anchor: TourAnchor.outcome,
      title: 'What landed',
      body: 'Read it, then tap OK.',
      hubIndex: 0,
    ),
    TourStep(
      anchor: TourAnchor.nextYear,
      title: 'Close the year',
      body: 'Prologue only needs the card. Tap Next year when you are done.',
      hubIndex: 0,
    ),
    TourStep(
      anchor: TourAnchor.navFamily,
      title: 'Family',
      body: 'Tap Family. Sit with one person a year.',
      hubIndex: 0,
    ),
    TourStep(
      anchor: TourAnchor.familyTree,
      title: 'Sit',
      body: 'Tap Sit on one name. Gift is a separate once-a-year.',
      hubIndex: 1,
    ),
    TourStep(
      anchor: TourAnchor.navCity,
      title: 'City',
      body: 'Tap City. Open streets take a press. Held streets: squeeze, keep quiet, or tribute.',
      hubIndex: 1,
    ),
    TourStep(
      anchor: TourAnchor.cityDistrict,
      title: 'Turf',
      body: 'This is the board. You do not need it to close a year.',
      hubIndex: 2,
    ),
    TourStep(
      anchor: TourAnchor.navMore,
      title: 'More',
      body: 'Empire, court, dynasty, settings. Tap More.',
      hubIndex: 2,
    ),
  ];

  static int get length => steps.length;
}

class TourKeys {
  final newGame = GlobalKey(debugLabel: 'tour.newGame');
  final yearCta = GlobalKey(debugLabel: 'tour.yearCta');
  final choice = GlobalKey(debugLabel: 'tour.choice');
  final outcome = GlobalKey(debugLabel: 'tour.outcome');
  final nextYear = GlobalKey(debugLabel: 'tour.nextYear');
  final navLife = GlobalKey(debugLabel: 'tour.navLife');
  final navFamily = GlobalKey(debugLabel: 'tour.navFamily');
  final familyTree = GlobalKey(debugLabel: 'tour.familyTree');
  final navCity = GlobalKey(debugLabel: 'tour.navCity');
  final cityDistrict = GlobalKey(debugLabel: 'tour.cityDistrict');
  final navMore = GlobalKey(debugLabel: 'tour.navMore');
  final moreActivities = GlobalKey(debugLabel: 'tour.moreActivities');
  final moreRelations = GlobalKey(debugLabel: 'tour.moreRelations');
  final moreCourt = GlobalKey(debugLabel: 'tour.moreCourt');
  final moreLegacy = GlobalKey(debugLabel: 'tour.moreLegacy');
  final moreSettings = GlobalKey(debugLabel: 'tour.moreSettings');

  GlobalKey? forAnchor(TourAnchor a) => switch (a) {
        TourAnchor.newGame => newGame,
        TourAnchor.yearCta => yearCta,
        TourAnchor.choice => choice,
        TourAnchor.outcome => outcome,
        TourAnchor.nextYear => nextYear,
        TourAnchor.navFamily => navFamily,
        TourAnchor.familyTree => familyTree,
        TourAnchor.navCity => navCity,
        TourAnchor.cityDistrict => cityDistrict,
        TourAnchor.navMore => navMore,
        TourAnchor.moreActivities => moreActivities,
        TourAnchor.moreRelations => moreRelations,
        TourAnchor.moreCourt => moreCourt,
        TourAnchor.moreLegacy => moreLegacy,
        TourAnchor.moreSettings => moreSettings,
      };
}
