import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vice_dynasty/art.dart';
import 'package:vice_dynasty/engine/catalog.dart';
import 'package:vice_dynasty/engine/game_engine.dart';
import 'package:vice_dynasty/services/save_service.dart';
import 'package:vice_dynasty/widgets/dynasty_tree.dart';

EventCatalog loadCatalog() {
  final dir = Directory('assets/events');
  final files = (jsonDecode(File('${dir.path}/manifest.json').readAsStringSync()) as List)
      .map((e) => '$e')
      .toList();
  final all = <dynamic>[];
  for (final f in files) {
    all.addAll(jsonDecode(File('${dir.path}/$f').readAsStringSync()) as List);
  }
  return EventCatalog.fromDecoded(all);
}

GameEngine fresh({int seed = 7}) {
  return GameEngine.newGame(
    catalog: loadCatalog(),
    firstName: 'Julian',
    lastName: 'Hart',
    gender: 'man',
    traits: const ['Ambitious', 'Cunning'],
    seed: seed,
  );
}

void main() {
  test('catalog loads unique events', () {
    final c = loadCatalog();
    expect(c.events.length, greaterThanOrEqualTo(80));
    expect(c.byId.length, c.events.length);
    expect(c['rain_on_orchard'], isNotNull);
    expect(c['glassridge_tip'], isNotNull);
    expect(c['prologue_rain'], isNotNull);
    expect(c['quiet_pier_whisper'], isNotNull);
    expect(c['crow_ledger_book'], isNotNull);
    expect(c['empty_chair_will'], isNotNull);
    expect(c['midlife_ledger_eyes'], isNotNull);
    expect(c['late_knees_rain'], isNotNull);
    expect(c['war_threat_card'], isNotNull);
  });

  test('new game starts playable in Ravenport at 18', () {
    final e = fresh();
    expect(e.state.cityName, 'Ravenport');
    expect(e.state.age, 18);
    expect(e.state.year, 1998);
    expect(e.state.stats.money, greaterThan(0));
    expect(e.state.player.isAlive, isTrue);
    expect(e.state.rivals.length, 4);
    expect(e.state.territories.length, 8);
    expect(e.continueLabel(), isNotEmpty);
    expect(e.activities(), isNotEmpty);
  });

  test('save and load round-trip preserves dynasty state', () async {
    final e = fresh(seed: 21);
    e.state.stats.money = 20000;
    e.state.flags.add('did_first_score');
    final giftee = e.state.people.values.firstWhere((p) => p.id != e.state.playerId && p.isAlive);
    expect(e.giftPerson(giftee.id), isNull);
    e.state.stats.money = 12345;
    e.debugBusiness('club');
    e.debugTerritory('old_quarter');
    final saves = SaveService(memory: {});
    await saves.write(1, e.state);
    final loaded = await saves.read(1);
    expect(loaded, isNotNull);
    expect(loaded!.stats.money, 12345);
    expect(loaded.flags.contains('did_first_score'), isTrue);
    expect(loaded.flags.contains('gift_year_${e.state.year}'), isTrue);
    expect(GameEngine(state: loaded, catalog: e.catalog).giftedThisYear, isTrue);
    expect(loaded.businesses, isNotEmpty);
    expect(loaded.territories.any((t) => t.id == 'old_quarter' && t.controller == 'player'), isTrue);
    final e2 = GameEngine(state: loaded, catalog: e.catalog);
    expect(e2.state.dynastyName, 'Hart');
    expect(e2.player.name, 'Julian Hart');
  });

  test('age-up advances year and writes a summary', () {
    final e = fresh(seed: 3);
    final y = e.state.year;
    e.ageUp();
    expect(e.state.year, y + 1);
    expect(e.state.age, 19);
    expect(e.state.phase, 'playing');
    expect(e.state.timeline, isNotEmpty);
  });

  test('crime activity can change money, heat, or send you inside', () {
    final e = fresh(seed: 11);
    e.state.stats.nerve = 80;
    e.debugBusiness('club');
    // recruit so robbery is available
    e.state.flags.add('has_crew');
    // spawn crew via activity-like hook
    final beforeMoney = e.state.stats.money;
    final beforeHeat = e.state.stats.heat;
    final r = e.doActivity('petty_theft');
    expect(r.skipped, isFalse);
    expect(
      e.state.stats.money != beforeMoney ||
          e.state.stats.heat != beforeHeat ||
          e.state.inPrison ||
          e.state.flags.contains('thief'),
      isTrue,
    );
  });

  test('prison is playable and then releases', () {
    final e = fresh(seed: 5);
    e.debugPrison(2);
    expect(e.state.inPrison, isTrue);
    expect(e.activities().any((a) => a.prisonOnly), isTrue);
    expect(e.activities().any((a) => a.id == 'petty_theft'), isFalse);
    e.ageUp();
    e.state.phase = 'playing';
    e.ageUp();
    expect(e.state.inPrison, isFalse);
    expect(e.state.achievements.contains('prison_out'), isTrue);
  });

  test('child grows traits and can inherit the chair', () {
    final e = fresh(seed: 42);
    e.debugMarry();
    e.debugBirth();
    final child = e.state.people.values.firstWhere((p) => p.relation == 'child');
    expect(child.ageIn(e.state.year), 0);
    // Advance 18 years
    for (var i = 0; i < 18; i++) {
      e.ageUp();
      e.state.phase = 'playing';
      e.state.awaitingHeir = false;
    }
    final grown = e.state.people[child.id]!;
    expect(grown.ageIn(e.state.year), 18);
    expect(grown.traits, isNotEmpty);
    expect(grown.adultIn(e.state.year), isTrue);

    e.debugBusiness('shipping');
    e.debugTerritory('docks');
    e.state.stats.money = 50000;
    e.state.stats.reputation = 40;
    final wealth = e.state.stats.money;
    final docks = e.state.territories.firstWhere((t) => t.id == 'docks').controller;
    e.debugKill();
    expect(e.state.awaitingHeir, isTrue);
    expect(e.eligibleHeirs().any((p) => p.id == child.id), isTrue);
    e.selectHeir(child.id);
    expect(e.state.playerId, child.id);
    expect(e.state.generation, 2);
    expect(e.state.awaitingHeir, isFalse);
    expect(e.state.hall, isNotEmpty);
    expect(e.state.stats.money, wealth); // cash carries
    expect(e.state.businesses.any((b) => b.type == 'shipping'), isTrue);
    expect(e.state.territories.firstWhere((t) => t.id == 'docks').controller, docks);
    expect(e.state.achievements.contains('heir_rise'), isTrue);
    // Keep playing
    e.ageUp();
    expect(e.player.isAlive, isTrue);
    expect(e.state.age, greaterThanOrEqualTo(18));
  });

  test('life sentence forces heir selection', () {
    final e = fresh(seed: 9);
    e.debugMarry();
    e.debugBirth();
    for (var i = 0; i < 18; i++) {
      e.ageUp();
      e.state.phase = 'playing';
      e.state.awaitingHeir = false;
    }
    e.debugPrison(99);
    e.ageUp();
    expect(e.state.awaitingHeir, isTrue);
    expect(e.state.heirReason, 'life sentence');
    final heir = e.eligibleHeirs().first;
    e.selectHeir(heir.id);
    expect(e.state.inPrison, isFalse);
    expect(e.state.generation, 2);
  });

  test('no softlock: there is always a way to spend a year', () {
    final e = fresh(seed: 1);
    expect(e.activities().any((a) => a.id == 'lay_low'), isTrue);
    e.debugPrison(3);
    expect(e.activities(), isNotEmpty);
    expect(e.continueLabel(), isNotEmpty);
  });

  test('multi-year loop does not crash', () {
    final e = fresh(seed: 99);
    for (var i = 0; i < 12; i++) {
      if (e.state.currentEventId == null && e.state.phase == 'playing') {
        e.drawEvent();
      }
      final ev = e.currentEvent();
      if (ev != null) {
        final ch = e.choicesFor(ev).firstWhere((c) => c.enabled);
        e.choose(ch.choice.id);
      }
      if (!e.state.awaitingHeir) {
        e.ageUp();
        e.state.phase = 'playing';
      }
    }
    expect(e.state.year, greaterThan(1998));
    expect(e.state.timeline.length, greaterThan(5));
  });

  test('prologue campaign sets first mark then queues heat', () {
    final e = fresh(seed: 7);
    expect(e.state.flags.contains('chapter_prologue'), isTrue);
    expect(e.continueLabel(), 'What happens this year');
    final first = e.drawEvent();
    expect(first?.id, 'prologue_rain');
    e.choose('take');
    expect(e.state.flags.contains('first_mark'), isTrue);
    expect(e.state.flags.contains('mentor_crowe'), isTrue);
    e.ageUp();
    e.state.phase = 'playing';
    final heat = e.drawEvent();
    expect(heat?.id, 'prologue_heat');
    expect(e.state.flags.contains('first_heat'), isFalse);
    e.choose('truth');
    expect(e.state.flags.contains('first_heat'), isTrue);
    expect(e.state.flags.contains('vale_file'), isTrue);
  });

  test('Quiet Pier chain leaves flags that fire a later crate', () {
    final e = fresh(seed: 13);
    e.state.pending.clear();
    e.state.flags
      ..remove('chapter_prologue')
      ..addAll(['mentor_crowe', 'docks_interest', 'prologue_done']);
    e.state.year = 2001; // age 21
    final open = e.drawEvent(preferId: 'quiet_pier_whisper');
    expect(open?.id, 'quiet_pier_whisper');
    e.choose('look');
    expect(e.state.flags.contains('quiet_pier_looked'), isTrue);
    e.ageUp();
    e.state.phase = 'playing';
    final crate = e.drawEvent();
    expect(crate?.id, 'quiet_pier_crate');
  });

  test('heir flow remains ceremonial and playable', () {
    final e = fresh(seed: 42);
    e.debugMarry();
    e.debugBirth();
    final child = e.state.people.values.firstWhere((p) => p.relation == 'child');
    for (var i = 0; i < 18; i++) {
      e.ageUp();
      e.state.phase = 'playing';
      e.state.awaitingHeir = false;
    }
    e.debugKill();
    expect(e.state.awaitingHeir, isTrue);
    expect(e.eligibleHeirs().any((p) => p.id == child.id), isTrue);
    expect(e.eligibleHeirs().any((p) => p.id == 'p_mentor'), isFalse);
    e.selectHeir(child.id);
    expect(e.state.generation, 2);
    expect(e.state.hall, isNotEmpty);
    expect(e.state.playerId, child.id);
  });

  test('prologue years do not dump random trivia', () {
    final e = fresh(seed: 4);
    e.state.pending.clear();
    final ev = e.drawEvent();
    expect(ev, isNotNull);
    expect(ev!.category, 'prologue');
  });

  test('each year is one event, then next year', () {
    final e = fresh(seed: 8);
    expect(e.state.eventTarget, 1);
    expect(e.yearEventPending, isTrue);
    expect(e.canAgeUp, isFalse);
    e.drawEvent();
    e.choose(e.choicesFor(e.currentEvent()!).firstWhere((c) => c.enabled).choice.id);
    expect(e.yearEventPending, isFalse);
    expect(e.canAgeUp, isTrue);
    e.state.stats.heat = 90;
    e.ageUp();
    expect(e.state.eventTarget, 1);
    expect(e.state.phase, 'playing');
  });

  test('empire hire pay and invest stay on the cash ledger', () {
    final e = fresh(seed: 6);
    e.state.stats.money = 4000;
    expect(e.hireHand(), isNull);
    expect(e.state.crew, hasLength(1));
    expect(e.state.stats.money, 4000 - GameEngine.hireCost);
    final id = e.state.crew.first.personId;
    final loyalty = e.state.crew.first.loyalty;
    expect(e.payBonus(id), isNull);
    expect(e.state.crew.first.loyalty, greaterThan(loyalty));
    e.debugBusiness('club');
    final income = e.state.businesses.first.yearlyIncome;
    expect(e.investFront(e.state.businesses.first.id), isNull);
    expect(e.state.businesses.first.yearlyIncome, greaterThan(income));
    expect(e.letGo(id), isNull);
    expect(e.state.crew, isEmpty);
  });

  test('hire is reachable early and unaffordable actions say how much more', () {
    final e = fresh(seed: 4);
    expect(e.state.stats.money, greaterThanOrEqualTo(500));
    expect(GameEngine.hireCost, lessThanOrEqualTo(350));
    e.state.stats.money = 40;
    expect(e.hireHand(), 'Need \$300 to hire.');
    expect(GameEngine.unaffordable(40, GameEngine.hireCost), 'Need \$260 more');
    expect(e.inheritBlurb(), contains('keeps cash'));
    final ev = e.catalog['prologue_rain']!;
    expect(GameEngine.choiceHint(ev.choices.first), contains('pay'));
  });

  test('press turf needs a hand; sit is once a year', () {
    final e = fresh(seed: 10);
    e.state.stats.money = 5000;
    expect(e.pressTurf('docks'), 'Need at least one hand.');
    expect(e.hireHand(), isNull);
    expect(e.pressTurf('docks'), isNull);
    expect(e.state.territories.firstWhere((t) => t.id == 'docks').controller, 'player');
    expect(e.coolTurf('docks'), isNull);
    final living = e.state.people.values.where((p) => p.id != e.state.playerId && p.isAlive).toList();
    expect(e.sitWith(living.first.id), isNull);
    expect(e.satThisYear, isTrue);
    expect(e.satPersonId(), living.first.id);
    expect(e.satPerson()?.firstName, living.first.firstName);
    expect(e.sitScene(living.first).id, 'sit');
    expect(e.sitWith(living.last.id), 'You already sat with someone this year.');
    expect(e.giftedThisYear, isFalse);
    expect(e.giftPerson(living.last.id), isNull);
    expect(e.giftedThisYear, isTrue);
    expect(e.giftedPersonId(), living.last.id);
    expect(e.giftPerson(living.first.id), 'You already gifted someone this year.');
    expect(e.satThisYear, isTrue);
    e.ageUp();
    e.state.phase = 'playing';
    expect(e.satThisYear, isFalse);
    expect(e.giftedThisYear, isFalse);
    expect(e.sitWith(living.last.id), isNull);
    expect(e.giftPerson(living.first.id), isNull);
  });

  test('gift is once a year, independent of sit, and unaffordable when cash is low', () {
    final e = fresh(seed: 11);
    final living = e.state.people.values.where((p) => p.id != e.state.playerId && p.isAlive).toList();
    expect(living.length, greaterThanOrEqualTo(2));
    e.state.stats.money = 40;
    expect(e.giftPerson(living.first.id), 'Need \$110 more');
    expect(e.giftedThisYear, isFalse);
    e.state.stats.money = 5000;
    expect(e.giftPerson(living.first.id), isNull);
    expect(e.giftedThisYear, isTrue);
    expect(e.giftedPersonId(), living.first.id);
    expect(e.giftPerson(living.last.id), 'You already gifted someone this year.');
    expect(e.sitWith(living.last.id), isNull);
    expect(e.satThisYear, isTrue);
    expect(e.satPersonId(), living.last.id);
    expect(e.satPersonId() == e.giftedPersonId(), isFalse);
    final year = e.state.year;
    expect(e.state.flags.contains('gift_year_$year'), isTrue);
    e.ageUp();
    expect(e.giftedThisYear, isFalse);
    expect(e.giftPerson(living.last.id), isNull);
  });

  test('recent events go on cooldown and still have a fallback pool', () {
    final e = fresh(seed: 8);
    e.state.pending.clear();
    e.state.flags
      ..remove('chapter_prologue')
      ..add('prologue_done');
    final first = e.drawEvent();
    expect(first, isNotNull);
    e.choose(e.choicesFor(first!).firstWhere((c) => c.enabled).choice.id);
    expect(e.state.recentEventIds, contains(first.id));
    expect(e.eventEligible(first), isFalse);
    if (!first.once) {
      expect(e.eventEligible(first, ignoreCooldown: true), isTrue);
    }
    for (final ev in e.catalog.events) {
      e.state.cooldowns[ev.id] = e.state.year + 9;
    }
    final again = e.drawEvent();
    expect(again, isNotNull);
  });

  test('assigned crew watches a front and pays on age-up', () {
    final e = fresh(seed: 6);
    e.state.stats.money = 8000;
    expect(e.hireHand(), isNull);
    e.debugBusiness('club');
    expect(e.assignCrew(e.state.crew.first.personId), isNull);
    expect(e.state.crew.first.assignedBizId, isNotNull);
    expect(e.ambition(), isNotEmpty);
    e.ageUp();
    expect(e.state.lastYearLog.any((l) => l.contains('watched')), isTrue);
  });

  test('fronts can be bought from the books and stay unique', () {
    final e = fresh(seed: 6);
    e.state.stats.money = 40;
    expect(e.buyFront(), 'Need \$800 to open a front.');
    expect(GameEngine.unaffordable(40, GameEngine.frontCost), 'Need \$760 more');
    e.state.stats.money = 2000;
    expect(e.buyFront('laundry'), isNull);
    expect(e.state.businesses.any((b) => b.type == 'laundry'), isTrue);
    expect(e.state.stats.money, 2000 - GameEngine.frontCost);
    expect(e.availableFrontTypes().contains('laundry'), isFalse);
    e.state.stats.money = 40;
    expect(e.buyFront(), 'Need \$800 to open a front.');
  });

  test('rival war season moves threat to heat and then cools', () {
    final e = fresh(seed: 6);
    e.debugStartWar();
    expect(e.warPhase, 'threat');
    expect(e.warLine(), contains('War season'));
    expect(e.cityPressure(), contains('War season'));
    final cash = e.state.stats.money;
    final heat = e.state.stats.heat;
    e.ageUp();
    expect(e.warPhase, 'escalate');
    expect(
      e.state.lastYearLog.any((l) => l.contains('pressed') || l.contains('took') || l.contains('hot')),
      isTrue,
    );
    expect(e.state.stats.heat >= heat || e.state.stats.money < cash, isTrue);
    e.state.phase = 'playing';
    e.ageUp();
    expect(e.warPhase, 'resolve');
    e.state.phase = 'playing';
    e.ageUp();
    expect(e.warPhase, isNull);
    expect(e.state.lastYearLog.any((l) => l.contains('War season closed')), isTrue);
  });

  test('dynasty tree groups elders, chair, and circle', () {
    final e = fresh(seed: 2);
    e.debugBirth();
    final layout = DynastyTreeLayout.from(e);
    expect(layout.elders.any((p) => p.id == 'p_mentor'), isTrue);
    expect(layout.peers.any((p) => p.id == e.state.playerId), isTrue);
    expect(layout.children.any((p) => p.relation == 'child'), isTrue);
    expect(layout.orbit.any((p) => p.id == 'p_foil'), isTrue);
    expect(layout.chairId, e.state.playerId);
  });

  test('named people use distinct portraits', () {
    final e = fresh(seed: 2);
    e.debugMarry();
    e.debugBirth();
    final keys = e.state.people.values.map((p) => Art.portraitKeyFor(p, year: e.state.year)).toList();
    expect(keys.toSet().length, keys.length);
    expect(Art.portraitKeyFor(e.state.people['p_mentor']!), 'mentor');
    expect(Art.portraitKeyFor(e.state.people['p_foil']!), 'vale');
    expect(Art.portraitKeyFor(e.state.people['p_cass']!), 'cass');
    expect(e.activities().any((a) => a.id == 'family_time'), isTrue);
  });
}
