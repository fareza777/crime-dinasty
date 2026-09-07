import 'package:flutter/material.dart';

enum TourAnchor {
  newGame,
  yearCta,
  choice,
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
  });
  final TourAnchor anchor;
  final String title;
  final String body;
  /// Life 0 · Family 1 · City 2 · More 3. Null leaves the current tab.
  final int? hubIndex;

  GlobalKey? keyOf(TourKeys keys) => keys.forAnchor(anchor);
}

class Tour {
  static const steps = <TourStep>[
    TourStep(
      anchor: TourAnchor.newGame,
      title: 'Start here',
      body: 'Name yourself, pick two traits, then tap Start.',
    ),
    TourStep(
      anchor: TourAnchor.yearCta,
      title: 'Your year',
      body: 'Tap this to see what happens this year.',
      hubIndex: 0,
    ),
    TourStep(
      anchor: TourAnchor.choice,
      title: 'Pick one',
      body: 'Gold is a suggestion. Any choice still counts.',
      hubIndex: 0,
    ),
    TourStep(
      anchor: TourAnchor.nextYear,
      title: 'Close the year',
      body: 'Tap Next year when you are ready. Do something is optional.',
      hubIndex: 0,
    ),
    TourStep(
      anchor: TourAnchor.navFamily,
      title: 'Family',
      body: 'Your people. Tap Family.',
      hubIndex: 0,
    ),
    TourStep(
      anchor: TourAnchor.familyTree,
      title: 'The tree',
      body: 'Sit with only one person each year. Gift is also once per year, separate from Sit. Someone here may take the chair one day.',
      hubIndex: 1,
    ),
    TourStep(
      anchor: TourAnchor.navCity,
      title: 'City',
      body: 'Districts and rivals. Optional. Tap City.',
      hubIndex: 1,
    ),
    TourStep(
      anchor: TourAnchor.cityDistrict,
      title: 'Turf',
      body: 'Who holds each street. You do not need this to play a year.',
      hubIndex: 2,
    ),
    TourStep(
      anchor: TourAnchor.navMore,
      title: 'More',
      body: 'Extra rooms. Tap More.',
      hubIndex: 2,
    ),
    TourStep(
      anchor: TourAnchor.moreActivities,
      title: 'Activities',
      body: 'The same extras as Do something, listed out.',
      hubIndex: 3,
    ),
    TourStep(
      anchor: TourAnchor.moreRelations,
      title: 'Relationships',
      body: 'Bonds and loyalty at a glance.',
      hubIndex: 3,
    ),
    TourStep(
      anchor: TourAnchor.moreCourt,
      title: 'Court',
      body: 'Heat, lawyers, and prison years.',
      hubIndex: 3,
    ),
    TourStep(
      anchor: TourAnchor.moreLegacy,
      title: 'Dynasty',
      body: 'The chair, who inherits, and the hall.',
      hubIndex: 3,
    ),
    TourStep(
      anchor: TourAnchor.moreSettings,
      title: 'Settings',
      body: 'Music, sound, saves, and ads.',
      hubIndex: 3,
    ),
  ];

  static int get length => steps.length;
}

class TourKeys {
  final newGame = GlobalKey(debugLabel: 'tour.newGame');
  final yearCta = GlobalKey(debugLabel: 'tour.yearCta');
  final choice = GlobalKey(debugLabel: 'tour.choice');
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
