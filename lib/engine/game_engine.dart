import 'dart:convert';
import 'dart:math';

import '../art.dart';
import '../models/event_models.dart';
import '../models/game_models.dart';
import 'catalog.dart';

class ChoiceView {
  ChoiceView(this.choice, {required this.enabled, this.reason});
  final ChoiceDef choice;
  final bool enabled;
  final String? reason;
}

class ResolveResult {
  ResolveResult({
    required this.outcome,
    required this.event,
    this.skipped = false,
  });
  final OutcomeDef outcome;
  final EventDef event;
  final bool skipped;
}

class GameEngine {
  GameEngine({
    required this.state,
    required this.catalog,
    SeededRng? rng,
  }) : rng = rng ?? SeededRng(state.seed);

  GameState state;
  final EventCatalog catalog;
  SeededRng rng;
  List<String> lastUnlocks = [];
  String? lastPressResult;

  static GameEngine newGame({
    required EventCatalog catalog,
    required String firstName,
    required String lastName,
    required String gender,
    required List<String> traits,
    int seed = 0,
  }) {
    final s = seed == 0 ? DateTime.now().millisecondsSinceEpoch : seed;
    final rng = SeededRng(s);
    final id = 'p_founder';
    final year = WorldContent.startYear;
    final player = Person(
      id: id,
      firstName: firstName.trim().isEmpty ? 'Julian' : firstName.trim(),
      lastName: lastName.trim().isEmpty ? 'Hart' : lastName.trim(),
      gender: gender,
      birthYear: year - WorldContent.startAge,
      traits: List.of(traits),
      relation: 'self',
      lifePath: 'family',
      loyaltyToFamily: 70,
      portraitSeed: s,
      personalStats: Stats(),
    );
    final people = <String, Person>{id: player};
    // A sibling or cousin so early family screens aren't empty.
    final sibG = NameBank.gender(rng);
    final sib = Person(
      id: 'p_sib',
      firstName: NameBank.first(rng, sibG),
      lastName: player.lastName,
      gender: sibG,
      birthYear: player.birthYear + rng.nextInt(5) - 2,
      traits: [rng.pick(WorldContent.traits)],
      relation: 'sibling',
      lifePath: rng.chance(40) ? 'legal' : 'unknown',
      loyaltyToFamily: 45 + rng.nextInt(30),
    );
    people[sib.id] = sib;

    people['p_mentor'] = Person(
      id: 'p_mentor',
      firstName: 'Silas',
      lastName: 'Crowe',
      gender: 'man',
      birthYear: year - 52,
      traits: const ['Patient', 'Cunning'],
      relation: 'mentor',
      lifePath: 'family',
      loyaltyToFamily: 62,
      bond: 40,
      portraitSeed: s + 11,
    );
    people['p_foil'] = Person(
      id: 'p_foil',
      firstName: 'Rhea',
      lastName: 'Vale',
      gender: 'woman',
      birthYear: year - 34,
      traits: const ['Patient', 'Ambitious'],
      relation: 'foil',
      lifePath: 'legal',
      loyaltyToFamily: 8,
      bond: 12,
      portraitSeed: s + 23,
    );
    people['p_cass'] = Person(
      id: 'p_cass',
      firstName: 'Cass',
      lastName: 'Caldera',
      gender: 'nonbinary',
      birthYear: year - 20,
      traits: const ['Cunning', 'Charming'],
      relation: 'rival_heir',
      lifePath: 'rival',
      rivalFamilyId: 'calderas',
      loyaltyToFamily: 10,
      bond: 5,
      portraitSeed: s + 41,
    );
    people['p_mira'] = Person(
      id: 'p_mira',
      firstName: 'Mira',
      lastName: 'Keene',
      gender: 'woman',
      birthYear: year - 19,
      traits: const ['Charming', 'Cunning'],
      relation: 'acquaintance',
      lifePath: 'unknown',
      loyaltyToFamily: 22,
      bond: 18,
      portraitSeed: s + 61,
    );
    people['p_ben'] = Person(
      id: 'p_ben',
      firstName: 'Bennett',
      lastName: 'Lang',
      gender: 'man',
      birthYear: year - 21,
      traits: const ['Patient', 'Ambitious'],
      relation: 'acquaintance',
      lifePath: 'legal',
      loyaltyToFamily: 18,
      bond: 12,
      portraitSeed: s + 73,
    );

    final usedFaces = <String>{};
    for (final p in people.values) {
      Art.claimKey(p, usedFaces, year: year);
    }

    final territories = WorldContent.territories()
        .map(
          (t) => Territory(
            id: t['id']!,
            name: t['name']!,
            blurb: t['blurb']!,
            income: 350 + rng.nextInt(250),
            heat: 6 + rng.nextInt(10),
          ),
        )
        .toList();
    void own(String id, String who) {
      final t = territories.firstWhere((e) => e.id == id);
      t.controller = who;
      t.influence = who == 'player' ? 20 : 55;
    }

    own('glassridge', 'calderas');
    own('westmere', 'calderas');
    own('ironyard', 'rooke');
    own('the_flats', 'rooke');
    own('midtown', 'vex');
    own('harbor_lights', 'marrow');
    // docks + old_quarter start independent — the player's opening board.

    final rivals = [
      RivalFamily(
        id: 'calderas',
        name: 'The Calderas',
        bossName: 'Aurelia Caldera',
        power: 62,
        wealth: 48000,
        hostility: 12,
        personality: 'calculating',
        territories: ['glassridge', 'westmere'],
      ),
      RivalFamily(
        id: 'rooke',
        name: 'The Rooke Outfit',
        bossName: 'Dane Rooke',
        power: 48,
        wealth: 18000,
        hostility: 22,
        personality: 'aggressive',
        territories: ['ironyard', 'the_flats'],
      ),
      RivalFamily(
        id: 'vex',
        name: 'House Vex',
        bossName: 'Lior Vex',
        power: 44,
        wealth: 36000,
        hostility: 8,
        personality: 'opportunistic',
        territories: ['midtown'],
      ),
      RivalFamily(
        id: 'marrow',
        name: 'The Marrow Kin',
        bossName: 'Nessa Marrow',
        power: 40,
        wealth: 14000,
        hostility: 18,
        personality: 'aggressive',
        territories: ['harbor_lights'],
      ),
    ];

    final st = GameState(
      year: year,
      playerId: id,
      dynastyName: player.lastName,
      seed: s,
      rngState: s,
      people: people,
      territories: territories,
      rivals: rivals,
      eventTarget: 1,
      stats: Stats(
        health: 74,
        intelligence: 38 + rng.nextInt(16) + (traits.contains('Cunning') ? 6 : 0),
        charisma: 38 + rng.nextInt(16) + (traits.contains('Charming') ? 8 : 0),
        nerve: 36 + rng.nextInt(18) + (traits.contains('Reckless') ? 8 : 0),
        loyalty: 40 + rng.nextInt(16) + (traits.contains('Loyal') ? 10 : 0),
        reputation: 6,
        heat: 3,
        stress: 10 + (traits.contains('Paranoid') ? 8 : 0),
        money: 500 + rng.nextInt(80),
      ),
    );
    st.log('Ravenport, 1998. Eighteen, a thin wallet, and a surname the pavement is willing to learn.');
    st.flags.add('new_blood');
    st.flags.add('chapter_prologue');
    st.yearHeadline = '1998. The rain is already taking sides.';
    st.pending.add(PendingEvent(eventId: 'prologue_rain', triggerYear: year));
    final engine = GameEngine(state: st, catalog: catalog, rng: rng);
    engine._applyTraitStatNudge();
    engine._setYearBeats();
    return engine;
  }

  Person get player => state.player;

  List<Person> get livingFamily => state.people.values
      .where((p) => p.isAlive && p.id != state.playerId && _isFamily(p))
      .toList();

  bool _isFamily(Person p) => const {
        'self',
        'spouse',
        'child',
        'sibling',
        'parent',
        'cousin',
        'inlaw',
      }.contains(p.relation);

  List<Person> eligibleHeirs() {
    final kids = state.people.values
        .where((p) => p.isAlive && p.relation == 'child' && p.adultIn(state.year) && p.lifePath != 'rival')
        .toList()
      ..sort((a, b) => b.loyaltyToFamily.compareTo(a.loyaltyToFamily));
    if (kids.isNotEmpty) return kids;
    final blood = state.people.values
        .where((p) =>
            p.isAlive &&
            p.id != state.playerId &&
            p.adultIn(state.year) &&
            (p.relation == 'sibling' || p.relation == 'cousin') &&
            p.lifePath != 'rival')
        .toList();
    return blood;
  }

  EventDef? currentEvent() {
    final id = state.currentEventId;
    if (id == null) return null;
    return catalog[id];
  }

  List<ChoiceView> choicesFor(EventDef event) {
    final out = <ChoiceView>[];
    for (final c in event.choices) {
      final unmet = _unmetReason(c.requires);
      if (unmet != null && c.hideIfUnmet) continue;
      out.add(ChoiceView(c, enabled: unmet == null, reason: unmet));
    }
    if (out.isEmpty) {
      out.add(
        ChoiceView(
          ChoiceDef(
            id: 'fallback',
            text: 'Let the year pass',
            outcomes: [OutcomeDef(id: 'pass', title: 'Time moves', body: 'You keep your head down.', log: 'Kept quiet.')],
          ),
          enabled: true,
        ),
      );
    }
    return out;
  }

  bool eventEligible(EventDef e, {bool ignoreCooldown = false}) {
    if (state.age < e.minAge || state.age > e.maxAge) return false;
    if (e.once && state.seenEvents.contains(e.id)) return false;
    final cd = state.cooldowns[e.id];
    if (!ignoreCooldown && cd != null && cd > state.year) return false;
    if (state.inPrison && e.requires.inPrison != true && e.category != 'prison' && !e.tags.contains('inside_ok')) {
      return false;
    }
    if (!state.inPrison && (e.requires.inPrison == true || e.category == 'prison')) {
      return false;
    }
    if (state.flags.contains('chapter_prologue') && e.category != 'prologue') {
      return false;
    }
    return _unmetReason(e.requires, event: e) == null;
  }

  String? _unmetReason(RequireDef r, {EventDef? event}) {
    final flags = state.flags;
    for (final f in r.allFlags) {
      if (!flags.contains(f)) return 'Not yet.';
    }
    if (r.anyFlags.isNotEmpty && !r.anyFlags.any(flags.contains)) return 'Not yet.';
    for (final f in r.noneFlags) {
      if (flags.contains(f)) return 'That door is closed.';
    }
    for (final e in r.minStats.entries) {
      if (state.stats.get(e.key) < e.value) return 'Need ${e.key} ${e.value}.';
    }
    for (final e in r.maxStats.entries) {
      if (state.stats.get(e.key) > e.value) return '${e.key} is too high.';
    }
    if (state.stats.money < r.minMoney) return 'Need \$${r.minMoney}.';
    if (state.crew.length < r.minCrew) return 'Need more crew.';
    final spouse = _spouse();
    if (r.hasSpouse == true && spouse == null) return 'Requires a spouse.';
    if (r.hasSpouse == false && spouse != null) return 'Not while married.';
    final kids = state.people.values.where((p) => p.relation == 'child' && p.isAlive).toList();
    if (r.hasChildren == true && kids.isEmpty) return 'Requires a child.';
    if (r.hasChildren == false && kids.isNotEmpty) return 'Not with children.';
    if (r.minChildrenAdult > 0 &&
        kids.where((p) => p.adultIn(state.year)).length < r.minChildrenAdult) {
      return 'Need an adult heir.';
    }
    if (r.inPrison == true && !state.inPrison) return 'Not inside.';
    if (r.inPrison == false && state.inPrison && event?.tags.contains('inside_ok') != true) {
      return 'Not while locked up.';
    }
    if (r.hasBusiness == true && state.businesses.isEmpty) return 'Need a business.';
    if (r.hasTerritory == true && !state.territories.any((t) => t.controller == 'player')) {
      return 'Need turf.';
    }
    if (state.stats.heat < r.minHeat) return 'Heat is too quiet.';
    if (state.stats.reputation < r.minReputation) return 'Name is too small.';
    final traits = player.traits;
    if (r.traitsAny.isNotEmpty && !r.traitsAny.any(traits.contains)) {
      return 'Requires ${r.traitsAny.join('/')}';
    }
    if (r.traitsNone.any(traits.contains)) return 'Your nature refuses.';
    if (state.generation < r.minGeneration) return 'Too early in the dynasty.';
    if (event != null) {
      if (state.age < event.minAge || state.age > event.maxAge) return 'Wrong age.';
    }
    return null;
  }

  Person? _spouse() {
    final id = player.spouseId;
    if (id == null) return null;
    final p = state.people[id];
    if (p == null || !p.isAlive) return null;
    return p;
  }

  EventDef? drawEvent({String? preferId}) {
    if (preferId != null && catalog[preferId] != null) {
      final e = catalog[preferId]!;
      state.currentEventId = e.id;
      state.phase = 'event';
      state.retryUsed = false;
      return e;
    }
    final queued = state.pending.where((p) => p.triggerYear <= state.year).toList();
    queued.sort((a, b) => a.triggerYear.compareTo(b.triggerYear));
    for (final q in queued) {
      final def = catalog[q.eventId];
      state.pending.remove(q);
      if (def != null && eventEligible(def)) {
        state.currentEventId = def.id;
        state.phase = 'event';
        state.retryUsed = false;
        return def;
      }
    }
    var pool = catalog.events.where(eventEligible).toList();
    if (pool.isEmpty) {
      pool = catalog.events.where((e) => eventEligible(e, ignoreCooldown: true)).toList();
    }
    if (pool.isEmpty) return null;
    final lastCat = state.lastEventId == null ? null : catalog[state.lastEventId!]?.category;
    final picked = rng.weighted(pool, (e) {
      var w = max(1, e.weight);
      if (e.category == 'crime' && player.traits.contains('Reckless')) w += 6;
      if (e.category == 'family' && player.traits.contains('Loyal')) w += 6;
      if (e.category == 'business' && player.traits.contains('Ambitious')) w += 5;
      if (e.category == 'police' && state.stats.heat > 40) w += state.stats.heat ~/ 5;
      if (e.category == 'rival') {
        final host = state.rivals.fold<int>(0, (a, r) => a + r.hostility);
        w += host ~/ 20;
      }
      if (state.age >= 30 && e.tags.contains('midlife')) w += 14;
      if (state.age >= 48 && e.tags.contains('late')) w += 16;
      if (state.age < 28 && e.tags.contains('early')) w += 8;
      if (state.age >= 32 && e.tags.contains('early')) w = max(1, w ~/ 3);
      if (warPhase != null && (e.tags.contains('war') || e.category == 'rival')) w += 18;
      if (state.recentEventIds.contains(e.id)) w = max(1, w ~/ 6);
      if (lastCat != null && e.category == lastCat) w = max(1, w ~/ 2);
      return w;
    });
    state.currentEventId = picked.id;
    state.phase = 'event';
    state.retryUsed = false;
    return picked;
  }

  /// Primary life-loop label (plain verbs).
  String continueLabel() {
    if (state.phase == 'ending') {
      return state.endingId == 'forgotten' ? 'Game over' : 'See how it ended';
    }
    if (state.awaitingHeir) return 'Choose who takes over';
    if (state.currentEventId != null) return 'Finish this card';
    if (yearEventPending) return 'What happens this year';
    return 'Next year';
  }

  void _setYearBeats() {
    final hot = state.inPrison || warPhase != null || state.stats.heat >= 55 || midlifePinch;
    state.eventTarget = hot ? 2 : 1;
  }

  int sentenceAfterCounsel(int years) => max(0, years - (state.lawyerQuality ~/ 25));

  bool _hasRole(List<String> roles) =>
      state.crew.any((c) => !c.imprisoned && roles.contains(c.role));

  String _neededRole() {
    final have = state.crew.map((c) => c.role).toSet();
    const order = ['lookout', 'driver', 'hacker', 'accountant', 'muscle', 'enforcer'];
    for (final r in order) {
      if (!have.contains(r)) return r;
    }
    return rng.pick(WorldContent.crewRoles);
  }

  bool _satRecently(String id, int years) {
    for (var y = state.year - years; y <= state.year; y++) {
      if (state.flags.contains('sat_who_${y}_$id')) return true;
    }
    return false;
  }

  void _queueOnce(String eventId, {int yearsAhead = 0}) {
    if (state.pending.any((p) => p.eventId == eventId)) return;
    state.pending.add(PendingEvent(eventId: eventId, triggerYear: state.year + yearsAhead));
  }

  String chapterPin() {
    final f = state.flags;
    if (f.contains('chapter_prologue')) return 'Prologue · The rain is still deciding.';
    if (f.contains('quiet_pier_looked') && !f.contains('quiet_pier_crate_done') && !f.contains('quiet_pier_done')) {
      return 'Chapter · The Quiet Pier';
    }
    if (f.contains('crow_ledger') || f.contains('crowe_secret')) return 'Chapter · The Crow Ledger';
    if (f.contains('glassridge_lead') || f.contains('heist_planned')) return 'Chapter · Glassridge';
    if (f.contains('da_file') || f.contains('vale_file')) return 'Chapter · Crown weather';
    if (warPhase != null) return 'Chapter · War season';
    if (state.inPrison) return 'Chapter · The corridor';
    if (f.contains('empire_ready')) return 'Chapter · The name on the skyline';
    if (state.age >= 48) return 'Chapter · Late weather';
    if (state.age >= 32) return 'Chapter · Midlife books';
    return 'Chapter · Early years in Ravenport';
  }

  List<(String, bool)> empireChecks() {
    return [
      ('Three fronts', state.businesses.length >= 3),
      ('Three streets', state.territories.where((t) => t.controller == 'player').length >= 3),
      ('Third generation', state.generation >= 3),
      ('Adult heir', eligibleHeirs().isNotEmpty),
    ];
  }

  String lifeArt() {
    if (state.inPrison) return 'prison';
    if (state.phase == 'ending' || state.awaitingHeir) return 'funeral';
    if (warPhase != null) return 'docks';
    if (state.stats.heat >= 60) return 'crime_night';
    final held = state.territories.where((t) => t.controller == 'player').toList();
    if (held.isNotEmpty) {
      held.sort((a, b) => b.influence.compareTo(a.influence));
      return held.first.id;
    }
    return 'skyline';
  }

  String lifeStill() => Art.lifeStill(lifeArt());

  int quietStreak() => _flagInt('quiet_streak_');

  int _flagInt(String prefix) {
    for (final f in state.flags) {
      if (f.startsWith(prefix)) {
        return int.tryParse(f.substring(prefix.length)) ?? 0;
      }
    }
    return 0;
  }

  void _setFlagInt(String prefix, int n) {
    state.flags.removeWhere((f) => f.startsWith(prefix));
    if (n > 0) state.flags.add('$prefix$n');
  }

  void _tickHonestClimb() {
    var n = _flagInt('honest_streak_') + 1;
    _setFlagInt('honest_streak_', n);
    if (n == 5 && !state.flags.contains('honest_rung_1')) {
      state.flags.add('honest_rung_1');
      _queueOnce('promotion_shift', yearsAhead: 1);
      state.log('Five honest years. A quieter door opened.', category: 'life');
    } else if (n == 10 && !state.flags.contains('honest_rung_2')) {
      state.flags.add('honest_rung_2');
      _queueOnce('promotion_shift_2', yearsAhead: 1);
      state.log('Ten honest years. Daylight started to look like a living.', category: 'life');
    }
  }

  int _sitCount(String id, int years) {
    var n = 0;
    for (var y = state.year - years; y <= state.year; y++) {
      if (state.flags.contains('sat_who_${y}_$id')) n++;
    }
    return n;
  }

  String? heirLean(Person p) {
    if (!p.isAlive) return null;
    if (p.lifePath == 'legal') return 'daylight';
    if (p.lifePath == 'rival') return 'other crest';
    if (state.flags.contains('lean_legal_${p.id}')) return 'leans daylight';
    if (state.flags.contains('lean_family_${p.id}')) return 'leans the table';
    if (p.relation == 'child' && p.adultIn(state.year) && p.lifePath == 'family') return 'the table';
    return null;
  }

  String houseWeather(RivalFamily r) {
    return switch (r.id) {
      'calderas' => 'buys the year with manners',
      'rooke' => 'breaks a door and calls it weather',
      'vex' => 'traces a name through glass',
      'marrow' => 'asks for blood like rent',
      _ => 'is moving',
    };
  }

  String houseTakeVerb(RivalFamily r) {
    return switch (r.id) {
      'calderas' => 'bought',
      'rooke' => 'broke into',
      'vex' => 'filed a claim on',
      'marrow' => 'bled',
      _ => 'took',
    };
  }

  String musicBed() {
    if (state.inPrison) return 'prison';
    if (warPhase != null || state.stats.heat >= 55) return 'war';
    return 'docks';
  }

  Person? eventFace(EventDef ev) {
    final id = ev.id.toLowerCase();
    Person? take(String pid) {
      final p = state.people[pid];
      return p == null || !p.isAlive ? null : p;
    }

    if (id.contains('vale') || id.contains('prosecutor') || id.contains('detective') || ev.art == 'prosecutor') {
      return take('p_foil');
    }
    if (id.contains('crowe') || id.contains('mentor') || id.contains('crow_')) return take('p_mentor');
    if (id.contains('cass') || id.contains('caldera')) return take('p_cass');
    if (id.contains('mira') || (id.contains('harbor') && ev.category == 'family')) return take('p_mira');
    if (id.contains('ben') || (id.contains('glassridge') && ev.category == 'family')) return take('p_ben');
    if (ev.category == 'crew' && state.crew.isNotEmpty) {
      return take(state.crew.first.personId);
    }
    if (ev.category == 'family') {
      final spouse = _spouse();
      if (spouse != null) return spouse;
      final kid = state.people.values.where((p) => p.relation == 'child' && p.isAlive).toList();
      if (kid.isNotEmpty) return kid.first;
      return take('p_mira') ?? take('p_ben');
    }
    if (ev.category == 'rival') return take('p_cass') ?? take('p_foil');
    if (ev.category == 'police') return take('p_foil');
    return null;
  }

  bool get yearEventPending =>
      state.currentEventId == null &&
      !state.awaitingHeir &&
      state.phase != 'ending' &&
      state.eventsThisYear < 1;

  bool get extraBeatAvailable {
    if (state.currentEventId != null || state.awaitingHeir || state.phase == 'ending') return false;
    if (state.eventsThisYear < 1) return false;
    if (state.inPrison || state.flags.contains('chapter_prologue')) return false;
    final hot = warPhase != null || state.stats.heat >= 55 || midlifePinch;
    if (!hot || state.eventsThisYear >= 2) return false;
    return catalog.events.any(eventEligible);
  }

  bool get midlifePinch {
    if (state.age < 32 || state.age > 48) return false;
    if (warPhase != null || state.stats.heat >= 45) return true;
    return state.people.values.any((p) {
      if (p.relation != 'child' || !p.isAlive) return false;
      final age = p.ageIn(state.year);
      return age >= 12 && age <= 18;
    });
  }

  bool get yearVerbRequired => !state.flags.contains('chapter_prologue');

  bool get streetMoveThisYear => state.flags.contains('street_year_${state.year}');

  bool get yearVerbUsed => state.activityUsed || streetMoveThisYear;

  bool get empireUsed => state.flags.contains('empire_year_${state.year}');

  bool get canAgeUp =>
      state.currentEventId == null &&
      !state.awaitingHeir &&
      state.phase != 'ending' &&
      state.eventsThisYear >= 1 &&
      (!yearVerbRequired || yearVerbUsed) &&
      !extraBeatAvailable;

  String? yearVerbBlock(String kind) {
    if (!yearVerbUsed) return null;
    if (kind == 'street' && streetMoveThisYear) return 'You already spent the year\'s street.';
    if (kind == 'job' && state.activityUsed && !streetMoveThisYear) {
      return 'You already spent the year\'s move.';
    }
    return 'You already spent the year\'s move.';
  }

  String? empireBlock() {
    if (empireUsed) return 'The books already moved this year.';
    return null;
  }

  void _spendEmpire() {
    state.flags.add('empire_year_${state.year}');
  }

  void _spendYearVerb(String kind) {
    if (kind == 'street') {
      state.flags.add('street_year_${state.year}');
      state.activityUsed = true;
    } else if (kind == 'job') {
      state.activityUsed = true;
    }
  }

  bool get guidedStart =>
      state.generation == 1 && state.year <= WorldContent.startYear + 2;

  String? suggestedChoiceId(EventDef event) {
    final views = choicesFor(event).where((c) => c.enabled).toList();
    if (views.isEmpty) return null;
    ChoiceView best = views.first;
    var bestScore = -99999;
    for (final v in views) {
      var score = 0;
      for (final o in v.choice.outcomes) {
        score += o.isHarsh ? -o.weight : o.weight;
      }
      if (score > bestScore) {
        bestScore = score;
        best = v;
      }
    }
    return best.choice.id;
  }

  String? simpleSideId(String verb) {
    switch (verb) {
      case 'earn':
        return state.inPrison ? 'prison_work' : 'side_hustle';
      case 'risk':
        return state.inPrison ? 'prison_politics' : 'petty_theft';
      case 'family':
        return state.inPrison ? 'prison_study' : 'family_time';
      case 'cool':
        return 'lay_low';
      default:
        return null;
    }
  }

  ResolveResult? continueYear() {
    if (state.awaitingHeir) return null;
    if (state.phase == 'ending') return null;
    if (state.phase == 'summary') {
      state.phase = 'playing';
      state.lastYearLog = [];
      return null;
    }
    if (state.currentEventId != null) return null;
    if (state.eventsThisYear < 1) {
      final e = drawEvent();
      if (e != null) return null;
      state.eventsThisYear = 1;
    }
    if (!canAgeUp) return null;
    ageUp();
    return null;
  }

  ResolveResult choose(String choiceId, {bool retry = false}) {
    lastUnlocks = [];
    final event = currentEvent();
    if (event == null) {
      return ResolveResult(
        event: EventDef(id: 'none', title: '', body: ''),
        outcome: OutcomeDef(title: 'Nothing', body: 'Nothing happens.'),
        skipped: true,
      );
    }
    if (retry) {
      if (state.snapshotJson != null) {
        final ads = state.adsRemoved;
        final restored = GameState.fromJson(jsonDecode(state.snapshotJson!) as Map<String, dynamic>);
        restored.adsRemoved = ads;
        restored.retryUsed = true;
        state = restored;
        rng = SeededRng(state.seed + state.year * 17 + 99);
      }
    } else {
      state.snapshotJson = jsonEncode(state.toJson()..['snapshotJson'] = null);
      state.retryUsed = false;
    }

    final views = choicesFor(event);
    final view = views.firstWhere(
      (c) => c.choice.id == choiceId && c.enabled,
      orElse: () => views.firstWhere((c) => c.enabled, orElse: () => views.first),
    );
    final choice = view.choice;
    var outcomes = List<OutcomeDef>.of(choice.outcomes);
    if (outcomes.isEmpty) {
      outcomes = [OutcomeDef(title: 'The night moves on', body: 'Nothing sticks.', log: 'Let it pass.')];
    }
    if (retry) {
      // Bias away from the harshest result.
      outcomes = outcomes.map((o) {
        final w = o.isHarsh ? max(1, o.weight ~/ 4) : o.weight + 40;
        return OutcomeDef(
          id: o.id,
          weight: w,
          title: o.title,
          body: o.body,
          log: o.log,
          stats: o.stats,
          addFlags: o.addFlags,
          removeFlags: o.removeFlags,
          arrest: o.arrest,
          setPrisonYears: o.setPrisonYears,
          injury: o.injury,
          death: o.death,
          lifeSentence: o.lifeSentence,
          spawnCrew: o.spawnCrew,
          marry: o.marry,
          divorce: o.divorce,
          spawnChildChance: o.spawnChildChance,
          crewLoyaltyDelta: o.crewLoyaltyDelta,
          betrayCrew: o.betrayCrew,
          rivalDelta: o.rivalDelta,
          queueEvent: o.queueEvent,
          grantTrait: o.grantTrait,
          unlockAchievement: o.unlockAchievement,
          forceHeir: o.forceHeir,
          retire: o.retire,
          businessGain: o.businessGain,
          territoryGain: o.territoryGain,
        );
      }).toList();
    }
    final outcome = rng.weighted(outcomes, (o) {
      var w = max(1, o.weight);
      if (player.traits.contains('Cunning') && (outcomeLooksClean(o))) w += 12;
      if (player.traits.contains('Reckless') && o.isHarsh) w += 8;
      if (player.traits.contains('Patient') && !o.isHarsh) w += 8;
      return w;
    });
    _noteSpecialChoice(event, choice);
    _stingYield(event, choice);
    _applyOutcome(event, choice, outcome);
    return ResolveResult(event: event, outcome: outcome);
  }

  void _noteSpecialChoice(EventDef event, ChoiceDef choice) {
    if (event.id.startsWith('war_')) {
      state.flags.removeWhere((f) => f.startsWith('war_choice_'));
      state.flags.add('war_choice_${choice.id}');
    }
    if (event.id == 'adult_child_question') {
      state.flags.removeWhere((f) => f.startsWith('kid_wish_') && f != 'kid_wish_applied');
      Person? kid;
      final kids = state.people.values.where((p) => p.relation == 'child' && p.isAlive).toList()
        ..sort((a, b) => b.ageIn(state.year).compareTo(a.ageIn(state.year)));
      if (kids.isNotEmpty) kid = kids.first;
      void stamp(String kind) {
        state.flags.add('kid_wish_$kind');
        if (kid != null) state.flags.add('kid_wish_${kid.id}_$kind');
      }

      if (choice.id == 'legal') stamp('legal');
      if (choice.id == 'family') stamp('family');
      if (choice.id == 'warn') stamp('warn');
    }
    if ((event.id == 'detective_card' || event.id == 'gen2_old_heat' || event.id == 'gen3_vale_desk') && choice.id == 'lawyer') {
      state.lawyerQuality = min(100, state.lawyerQuality + 25);
    }
  }

  void _stingYield(EventDef event, ChoiceDef choice) {
    const yieldIds = {'walk', 'pass', 'yield', 'hide', 'ignore'};
    if (!yieldIds.contains(choice.id)) return;
    if (event.id.startsWith('act_')) return;
    final hot = hottestRival();
    if (hot != null) hot.hostility = min(100, hot.hostility + 4);
    state.stats.reputation = max(0, state.stats.reputation - 2);
    var n = yieldCount();
    state.flags.removeWhere((f) => f.startsWith('yield_count_'));
    state.flags.add('yield_count_${n + 1}');
    if (state.eventsThisYear >= 1) {
      final held = state.territories.where((t) => t.controller == 'player').toList();
      if (held.isNotEmpty) {
        final t = rng.pick(held);
        t.influence = max(0, t.influence - 8);
      }
    }
  }

  bool outcomeLooksClean(OutcomeDef o) => !o.arrest && !o.death && !o.injury && !o.lifeSentence;

  void _applyOutcome(EventDef event, ChoiceDef choice, OutcomeDef o) {
    state.stats.applyMap(o.stats);
    if (state.stats.money < 0) {
      state.debt += -state.stats.money;
      state.stats.money = 0;
      state.flags.add('in_debt');
    } else if (state.debt > 0 && state.stats.money > 0) {
      final pay = min(state.debt, state.stats.money);
      state.debt -= pay;
      state.stats.money -= pay;
      if (state.debt == 0) state.flags.remove('in_debt');
    }
    for (final f in o.addFlags) {
      state.flags.add(f);
    }
    for (final f in o.removeFlags) {
      state.flags.remove(f);
    }
    if (o.log.isNotEmpty) state.log(o.log, category: event.category);
    if (o.grantTrait != null && !player.traits.contains(o.grantTrait)) {
      player.traits.add(o.grantTrait!);
    }
    _reactNpcs(o);
    if (o.unlockAchievement != null) unlock(o.unlockAchievement!);
    for (final e in o.rivalDelta.entries) {
      final r = state.rivals.cast<RivalFamily?>().firstWhere((x) => x!.id == e.key, orElse: () => null);
      if (r != null) r.hostility = (r.hostility + e.value).clamp(0, 100);
    }
    if (o.crewLoyaltyDelta != 0) {
      for (final c in state.crew) {
        c.loyalty = (c.loyalty + o.crewLoyaltyDelta).clamp(0, 100);
      }
    }
    if (o.spawnCrew) _recruitCrew();
    if (o.marry) _marry();
    if (o.divorce) _divorce();
    if (o.spawnChildChance > 0 && rng.chance(o.spawnChildChance)) _birthChild();
    if (o.betrayCrew) _betrayCrew();
    if (o.businessGain != null) _gainBusiness(o.businessGain!);
    if (o.territoryGain != null) _gainTerritory(o.territoryGain!);
    if (o.queueEvent != null) {
      final qid = '${o.queueEvent!['eventId']}';
      final ahead = (o.queueEvent!['yearsAhead'] as num?)?.toInt() ?? 1;
      state.pending.add(PendingEvent(eventId: qid, triggerYear: state.year + ahead));
    }
    if (o.injury) {
      state.stats.health = max(1, state.stats.health - (8 + rng.nextInt(10)));
      state.stats.stress = min(100, state.stats.stress + 8);
    }
    if (event.id == 'act_court') {
      bumpBond('p_mira', 12);
      bumpBond('p_ben', 10);
    }
    var enterPrison = false;
    if (o.arrest || o.setPrisonYears != null) {
      var years = o.setPrisonYears ?? (1 + rng.nextInt(3));
      years = sentenceAfterCounsel(years);
      if (years <= 0) {
        state.log('Counsel kept the door from closing.', category: 'police');
        state.stats.heat = max(0, state.stats.heat - 6);
      } else {
        _enterPrison(years);
        enterPrison = true;
      }
    }
    if (o.lifeSentence) {
      _enterPrison(99);
      _beginHeir('life sentence');
    }
    if (o.death) {
      _killPlayer(o.log.isEmpty ? 'Died in Ravenport night.' : o.log);
    }
    if (o.retire) {
      _beginHeir('retired');
    }
    if (o.forceHeir && !state.awaitingHeir) {
      _beginHeir('stepped aside');
    }

    if (event.id == 'act_lawyer' && choice.id == 'go') {
      state.lawyerQuality = min(100, state.lawyerQuality + 25);
    }
    if (event.id == 'act_family_time' && choice.id == 'go') {
      for (final p in state.people.values.where((p) => p.isAlive && p.id != player.id && _isFamily(p))) {
        p.loyaltyToFamily = min(100, p.loyaltyToFamily + 6);
        p.bond = min(100, p.bond + 8);
      }
    }
    state.seenEvents.add(event.id);
    state.cooldowns[event.id] = state.year + max(1, event.cooldownYears);
    state.recentEventIds.add(event.id);
    if (state.recentEventIds.length > 8) {
      state.recentEventIds.removeAt(0);
    }
    state.lastEventId = event.id;
    state.lastChoiceId = choice.id;
    state.lastFailed = o.isHarsh;
    state.currentEventId = null;
    if (!event.id.startsWith('act_')) {
      state.eventsThisYear += 1;
    } else if (choice.id != 'skip') {
      state.activityUsed = true;
      const risk = {
        'act_petty_theft',
        'act_smuggle',
        'act_robbery',
        'act_cyber',
        'act_prison_politics',
      };
      if (risk.contains(event.id)) {
        state.flags.add('risk_job_${state.year}');
        state.flags.removeWhere((f) => f.startsWith('honest_streak_'));
        if (event.id == 'act_cyber') {
          final n = _flagInt('cyber_count_') + 1;
          _setFlagInt('cyber_count_', n);
          if (n > 1) {
            state.stats.heat = min(100, state.stats.heat + 3 * (n - 1));
            state.log('The glass remembers previous ledgers.', category: 'crime');
          }
        }
      } else {
        state.flags.add('quiet_job_${state.year}');
        if (event.id == 'act_lay_low') {
          state.flags.add('hid_year_${state.year}');
        }
        if (event.id == 'act_side_hustle') {
          _tickHonestClimb();
          if (state.flags.contains('honest_rung_2')) {
            state.stats.money += 160;
          } else if (state.flags.contains('honest_rung_1')) {
            state.stats.money += 80;
          }
        }
        if (event.id == 'act_manage') {
          for (final b in state.businesses) {
            b.quality = min(100, b.quality + 8);
            b.cover = min(24, b.cover + 2);
          }
        }
      }
    }
    if (state.stats.health <= 0 && player.isAlive) {
      _killPlayer('The body gave out.');
    }
    _peaks();
    _checkAchievements();
    if (!state.awaitingHeir && state.phase != 'ending') state.phase = 'playing';
    if (enterPrison) state.generationBreakPending = true;
    _recomputeAssets();
  }

  void _peaks() {
    final wealth = state.stats.money + state.stats.assets;
    if (wealth > state.peakWealth) state.peakWealth = wealth;
    if (state.stats.reputation > state.peakReputation) {
      state.peakReputation = state.stats.reputation;
    }
  }

  void _recomputeAssets() {
    var v = 0;
    for (final b in state.businesses) {
      v += b.value;
    }
    for (final t in state.territories.where((t) => t.controller == 'player')) {
      v += t.income * 8;
    }
    state.stats.assets = v;
  }

  void _enterPrison(int years) {
    state.inPrison = true;
    state.prisonYearsLeft = max(state.prisonYearsLeft, years);
    player.lifePath = 'imprisoned';
    state.flags.add('inside');
    state.log('The city filed you under iron and fluorescent light.', category: 'police');
    unlock('first_score');
  }

  void _killPlayer(String cause) {
    player.isAlive = false;
    player.deathYear = state.year;
    player.deathCause = cause;
    player.lifePath = 'deceased';
    if (!state.flags.contains('chapter_prologue') && !_nameEarnedContinue) {
      _beginGameOver('forgotten');
      return;
    }
    _beginHeir('died');
  }

  bool get _nameEarnedContinue {
    if (state.generation >= 2) return true;
    if (state.flags.contains('name_on_board')) return true;
    if (state.flags.contains('did_first_score')) return true;
    if (state.businesses.isNotEmpty) return true;
    if (state.crew.isNotEmpty) return true;
    if (state.territories.any((t) => t.controller == 'player')) return true;
    return false;
  }

  bool get _emptyCityBoard =>
      state.businesses.isEmpty &&
      state.crew.isEmpty &&
      !state.territories.any((t) => t.controller == 'player');

  int yieldCount() {
    for (final f in state.flags) {
      if (f.startsWith('yield_count_')) {
        return int.tryParse(f.substring('yield_count_'.length)) ?? 0;
      }
    }
    return 0;
  }

  void _beginGameOver(String id) {
    if (state.phase == 'ending' && state.endingId != null) return;
    _recordLegacy('forgotten');
    state.endingId = id;
    state.heirReason = 'forgotten';
    state.awaitingHeir = false;
    state.currentEventId = null;
    state.generationBreakPending = false;
    state.phase = 'ending';
    if (player.isAlive) player.lifePath = 'forgotten';
    state.log('The city closed the file. Nobody sits the chair.', category: 'legacy');
  }

  void _beginHeir(String reason) {
    if (state.awaitingHeir || state.phase == 'ending') return;
    if (!state.flags.contains('chapter_prologue') && !_nameEarnedContinue) {
      _beginGameOver('forgotten');
      return;
    }
    _recordLegacy(reason);
    _assignEnding(reason);
    state.heirReason = reason;
    state.currentEventId = null;
    state.generationBreakPending = true;
    if (eligibleHeirs().isEmpty) {
      if (state.flags.contains('chapter_prologue')) {
        final g = NameBank.gender(rng);
        final cousin = Person(
          id: 'p_cousin_${state.year}',
          firstName: NameBank.first(rng, g),
          lastName: state.dynastyName,
          gender: g,
          birthYear: state.year - (18 + rng.nextInt(8)),
          traits: [rng.pick(WorldContent.traits), rng.pick(WorldContent.traits)],
          relation: 'cousin',
          lifePath: 'family',
          loyaltyToFamily: 35 + rng.nextInt(25),
        );
        cousin.personalStats = _statsForHeir(cousin);
        _stampPortrait(cousin);
        state.people[cousin.id] = cousin;
        state.flags.add('thin_blood');
        state.log('A thin-blood cousin surfaced when the chair went empty.', category: 'family');
        state.awaitingHeir = true;
        state.phase = 'ending';
        return;
      }
      state.endingId = 'bloodline_ends';
      state.awaitingHeir = false;
      state.phase = 'ending';
      return;
    }
    state.awaitingHeir = true;
    state.phase = 'ending';
  }

  void _assignEnding(String reason) {
    if (state.endingId != null) return;
    if (reason == 'life sentence') {
      state.endingId = 'life_inside';
    } else if (reason == 'retired') {
      if (state.flags.contains('empire_ready')) {
        state.endingId = 'empire';
      } else if (state.flags.contains('legitimate_turn')) {
        state.endingId = 'gone_straight';
      } else {
        state.endingId = 'retired_quiet';
      }
    } else if (state.age >= 70 || (player.deathCause ?? '').toLowerCase().contains('old')) {
      state.endingId = 'died_old';
    } else {
      state.endingId = 'died_street';
    }
  }

  void dismissEnding() {
    if (state.awaitingHeir && eligibleHeirs().isNotEmpty) {
      state.phase = 'heir';
      return;
    }
    state.phase = 'ending';
  }

  void _recordLegacy(String fate) {
    final epitaph = switch (fate) {
      'forgotten' => 'The city closed the file. Nobody sat the chair.',
      'retired' => 'Stepped back while the city was still listening.',
      'life sentence' => 'The state took the remaining years.',
      'died' => player.deathCause ?? 'Ended under Ravenport rain.',
      _ => 'The chair changed hands.',
    };
    state.hall.add(
      LegacyRecord(
        personId: player.id,
        name: player.name,
        startYear: state.leaderStartYear,
        endYear: state.year,
        startAge: state.leaderStartAge,
        endAge: state.age,
        fate: fate,
        epitaph: epitaph,
        peakWealth: state.peakWealth,
        peakReputation: state.peakReputation,
        generation: state.generation,
        notable: List.of(state.notableThisLife),
      ),
    );
    unlock('end_any');
  }

  void selectHeir(String personId) {
    final heir = state.people[personId];
    if (heir == null || !heir.isAlive) return;
    // Inheritance
    final old = player;
    old.relation = old.relation == 'self' ? 'parent' : old.relation;
    if (old.isAlive && state.heirReason == 'retired') {
      old.lifePath = 'legal';
      old.relation = 'parent';
    }
    heir.relation = 'self';
    heir.lifePath = 'family';
    if (heir.portraitKey == 'child' || heir.ageIn(state.year) >= 16) {
      heir.portraitKey = '';
      _stampPortrait(heir);
    }
    state.playerId = heir.id;
    state.generation += 1;
    state.leaderStartYear = state.year;
    state.leaderStartAge = heir.ageIn(state.year);
    state.awaitingHeir = false;
    state.heirReason = null;
    state.inPrison = false;
    state.prisonYearsLeft = 0;
    state.eventsThisYear = 0;
    state.activityUsed = false;
    state.currentEventId = null;
    state.phase = 'playing';
    state.notableThisLife = [];
    state.peakWealth = state.stats.money + state.stats.assets;
    state.endingId = null;
    state.flags.remove('inside');
    state.flags.remove('new_blood');
    // Personal flags drop; family flags stay.
    const personal = {
      'courted',
      'spouse_conflict',
      'prison_rep',
      'appealed',
      'lawyered',
      'turned_state',
      'widow_year',
    };
    state.flags.removeAll(personal);
    // Reputation and heat carry as family memory.
    state.stats.reputation = ((state.stats.reputation * 0.7).round() + (heir.loyaltyToFamily ~/ 10)).clamp(0, 100);
    state.stats.heat = (state.stats.heat * 0.5).round().clamp(0, 100);
    final hs = heir.personalStats ?? _statsForHeir(heir);
    var crimeYears = 0;
    for (final f in state.flags) {
      if (f.startsWith('risk_job_')) crimeYears++;
    }
    state.stats.health = hs.health;
    state.stats.intelligence = min(100, hs.intelligence + (heir.lifePath == 'legal' ? 8 : 0));
    state.stats.charisma = hs.charisma;
    state.stats.nerve = min(100, hs.nerve + min(14, crimeYears));
    state.stats.loyalty = min(100, hs.loyalty + (heir.lifePath == 'family' ? 6 : 0));
    state.stats.stress = 18;
    // Crew tests the new blood.
    state.crew.removeWhere((c) {
      c.loyalty -= 12 + rng.nextInt(14);
      if (c.loyalty < 20 && rng.chance(55)) {
        final p = state.people[c.personId];
        if (p != null) p.lifePath = 'unknown';
        return true;
      }
      return false;
    });
    for (final r in state.rivals) {
      r.hostility = min(100, r.hostility + 4 + rng.nextInt(6));
    }
    final hot = hottestRival();
    if (hot != null) {
      if (hot.hostility >= 40) {
        hot.hostility = min(100, hot.hostility + 14);
        if (hot.hostility >= 52 && warPhase == null) {
          _setWar('threat', hot);
          _queueOnce('war_threat_card');
        }
      } else {
        hot.hostility = min(100, hot.hostility + 8);
      }
    }
    if (state.generation == 2) {
      _queueOnce('gen2_chair_test');
    } else if (state.generation >= 3) {
      _queueOnce('gen3_chair_test');
    }
    state.log(
      '${heir.name} took the chair after ${old.firstName}. The city tested the new blood immediately.',
      category: 'family',
    );
    unlock('heir_rise');
    if (state.generation >= 3) unlock('generation_three');
    _checkAchievements();
    _recomputeAssets();
    _setYearBeats();
  }

  Stats _statsForHeir(Person heir) {
    int t(String name, int yes, int no) => heir.traits.contains(name) ? yes : no;
    return Stats(
      health: 70 + rng.nextInt(12),
      intelligence: 40 + rng.nextInt(18) + t('Cunning', 8, 0) + t('Patient', 4, 0),
      charisma: 40 + rng.nextInt(16) + t('Charming', 10, 0),
      nerve: 38 + rng.nextInt(18) + t('Reckless', 8, 0) + t('Violent', 6, 0),
      loyalty: 36 + rng.nextInt(16) + t('Loyal', 12, 0) + t('Compassionate', 6, 0),
      reputation: 10 + state.stats.reputation ~/ 5,
      heat: 8,
      stress: 14 + t('Paranoid', 10, 0),
      money: 0,
    );
  }

  void _stampPortrait(Person p) {
    final used = state.people.values
        .where((e) => e.id != p.id)
        .map((e) => e.portraitKey)
        .where((k) => k.isNotEmpty)
        .toSet();
    Art.claimKey(p, used, year: state.year);
  }

  void _recruitCrew({String? role}) {
    final g = NameBank.gender(rng);
    final p = Person(
      id: 'crew_${state.year}_${rng.nextInt(9999)}',
      firstName: NameBank.first(rng, g),
      lastName: NameBank.last(rng),
      gender: g,
      birthYear: state.year - (22 + rng.nextInt(18)),
      traits: [rng.pick(WorldContent.traits)],
      relation: 'crew',
      lifePath: 'family',
      loyaltyToFamily: 40 + rng.nextInt(35),
    );
    state.people[p.id] = p;
    _stampPortrait(p);
    state.crew.add(
      CrewMember(
        personId: p.id,
        role: role ?? _neededRole(),
        skill: 35 + rng.nextInt(40),
        loyalty: 45 + rng.nextInt(30) + (player.traits.contains('Loyal') ? 10 : 0),
        cut: 8 + rng.nextInt(8),
      ),
    );
    state.flags.add('has_crew');
    state.flags.add('name_on_board');
    state.log('${p.name} signed on as ${state.crew.last.role}.', category: 'crew');
    if (state.crew.length >= 3) unlock('crew_of_three');
  }

  void _marry() {
    if (_spouse() != null) return;
    Person? p;
    final named = state.people.values.where((x) {
      if (!x.isAlive || x.id == player.id || x.spouseId != null) return false;
      if (x.relation == 'spouse' || x.relation == 'child' || x.relation == 'parent' || x.relation == 'mentor') {
        return false;
      }
      if (x.relation == 'crew') return false;
      return x.bond >= 32 && (x.relation == 'acquaintance' || x.id == 'p_mira' || x.id == 'p_ben' || x.relation == 'foil');
    }).toList()
      ..sort((a, b) => b.bond.compareTo(a.bond));
    if (named.isNotEmpty) {
      p = named.first;
      p.relation = 'spouse';
      p.spouseId = player.id;
      p.lifePath = p.lifePath == 'rival' ? 'family' : p.lifePath;
      p.bond = min(100, p.bond + 20);
      p.loyaltyToFamily = min(100, p.loyaltyToFamily + 15);
    } else {
      final g = player.gender == 'woman' ? 'man' : (player.gender == 'man' ? 'woman' : NameBank.gender(rng));
      p = Person(
        id: 'spouse_${state.year}',
        firstName: NameBank.first(rng, g),
        lastName: rng.chance(40) ? state.dynastyName : NameBank.last(rng),
        gender: g,
        birthYear: player.birthYear + rng.nextInt(7) - 3,
        traits: [rng.pick(WorldContent.traits), rng.pick(WorldContent.traits)],
        relation: 'spouse',
        spouseId: player.id,
        lifePath: rng.chance(35) ? 'legal' : 'family',
        loyaltyToFamily: 50 + rng.nextInt(30),
        bond: 60,
      );
      state.people[p.id] = p;
      _stampPortrait(p);
    }
    player.spouseId = p.id;
    state.flags.add('married');
    state.log('Married ${p.name} under Ravenport rain.', category: 'family');
    unlock('married');
  }

  void _divorce() {
    final s = _spouse();
    if (s == null) return;
    s.spouseId = null;
    s.bond = 10;
    s.relation = 'inlaw';
    player.spouseId = null;
    state.flags.remove('married');
    state.flags.add('spouse_conflict');
    state.log('The marriage ended. The city kept copies.', category: 'family');
  }

  void _birthChild() {
    final g = NameBank.gender(rng);
    final child = Person(
      id: 'child_${state.year}_${rng.nextInt(9999)}',
      firstName: NameBank.first(rng, g),
      lastName: state.dynastyName,
      gender: g,
      birthYear: state.year,
      traits: [],
      relation: 'child',
      parentId: player.id,
      otherParentId: player.spouseId,
      lifePath: 'unknown',
      loyaltyToFamily: 60,
    );
    state.people[child.id] = child;
    _stampPortrait(child);
    state.childrenBorn += 1;
    state.flags.add('has_heir_child');
    state.log('${child.firstName} was born into the ${state.dynastyName} name.', category: 'family');
    unlock('parent');
  }

  void _betrayCrew() {
    if (state.crew.isEmpty) return;
    state.crew.sort((a, b) {
      final ascore = a.loyalty - (a.assignedBizId == null ? 12 : 0) + a.cut;
      final bscore = b.loyalty - (b.assignedBizId == null ? 12 : 0) + b.cut;
      return ascore.compareTo(bscore);
    });
    final c = state.crew.first;
    final p = state.people[c.personId];
    final steal = min(state.stats.money, 400 + rng.nextInt(900));
    state.stats.money -= steal;
    state.crew.remove(c);
    if (p != null) {
      p.lifePath = 'rival';
      p.rivalFamilyId = rng.pick(state.rivals).id;
    }
    state.flags.add('betrayed_once');
    state.stats.heat += 6;
    state.log('${p?.name ?? 'A hand'} walked with a cut of the books.', category: 'crew');
  }

  void _gainBusiness(String type) {
    if (state.businesses.any((b) => b.type == type)) {
      final b = state.businesses.firstWhere((e) => e.type == type);
      b.quality = min(100, b.quality + 8);
      b.value += 2000;
      b.yearlyIncome += 250;
      return;
    }
    final meta = WorldContent.businessMeta[type];
    if (meta == null) return;
    final b = Business(
      id: 'biz_${type}_${state.year}',
      name: meta[0] as String,
      type: type,
      districtId: meta[4] as String,
      value: meta[1] as int,
      yearlyIncome: meta[2] as int,
      cover: max(2, (meta[3] as int) ~/ 2),
      legalFront: true,
      quality: 22,
    );
    state.businesses.add(b);
    state.flags.add('name_on_board');
    state.log('Opened ${b.name}.', category: 'business');
    if (type == 'club') state.flags.add('club_open');
    if (type == 'shipping') state.flags.add('shipping_front');
    if (state.businesses.length >= 3) unlock('tycoon');
  }

  void _gainTerritory(String id) {
    final t = state.territories.cast<Territory?>().firstWhere((e) => e!.id == id, orElse: () => null);
    if (t == null) return;
    final prev = t.controller;
    t.controller = 'player';
    t.influence = max(t.influence, 50);
    state.flags.add('name_on_board');
    if (prev != null && prev != 'player') {
      final r = state.rivals.cast<RivalFamily?>().firstWhere((e) => e!.id == prev, orElse: () => null);
      if (r != null) {
        r.hostility = min(100, r.hostility + 12);
        r.territories.remove(id);
        r.power = max(5, r.power - 6);
      }
    }
    state.log('The ${state.dynastyName} name holds ${t.name}.', category: 'rival');
    if (id == 'docks') {
      state.flags.add('turf_docks');
      unlock('docks_king');
    }
    if (id == 'ironyard') state.flags.add('turf_ironyard');
  }

  List<ActivityDef> activities() {
    final list = <ActivityDef>[
      ActivityDef(
        id: 'lay_low',
        name: 'Lay low',
        description: 'Skip the loud rooms. Let heat and nerves cool under ordinary weather.',
        category: 'life',
        art: 'home',
        freeWorldOnly: false,
        outcomes: [
          OutcomeDef(
            id: 'quiet',
            weight: 100,
            title: 'A quiet year',
            body: 'You pay rent, walk side streets, and let your name go unprinted.',
            log: 'Laid low.',
            stats: {'heat': -8, 'stress': -10, 'health': 3, 'money': -120},
            addFlags: ['laid_low'],
          ),
        ],
      ),
      ActivityDef(
        id: 'petty_theft',
        name: 'Street lift',
        description: 'A small Ravenport lift. Fast money, thin loyalty, and a story the docks tell badly.',
        category: 'crime',
        art: 'street',
        outcomes: [
          OutcomeDef(
            id: 'ok',
            weight: 62,
            title: 'Pockets heavier',
            body: 'You are gone before the argument starts. The take is small and clean enough.',
            log: 'Pulled a street lift.',
            stats: {'money': 420, 'heat': 6, 'nerve': 3, 'reputation': 1, 'stress': 3},
            addFlags: ['thief', 'did_first_score'],
          ),
          OutcomeDef(
            id: 'cut',
            weight: 23,
            title: 'A bad corner',
            body: 'Someone bigger wanted the same night. You leave a little blood on the brick.',
            log: 'A street lift went ugly.',
            stats: {'money': 80, 'heat': 10, 'health': -12, 'stress': 8},
            injury: true,
            addFlags: ['thief'],
          ),
          OutcomeDef(
            id: 'busted',
            weight: 15,
            title: 'Cuffs in the rain',
            body: 'A patrol cuts the block. Fiction ends at the precinct desk.',
            log: 'Arrested after a street lift.',
            stats: {'heat': 12, 'reputation': -2, 'stress': 10, 'money': -50},
            arrest: true,
            setPrisonYears: 1,
          ),
        ],
      ),
      ActivityDef(
        id: 'smuggle',
        name: 'Night run',
        description: 'Move sealed crates along the water while the city looks the other way.',
        category: 'crime',
        art: 'docks',
        requires: RequireDef(minStats: {'nerve': 28}),
        outcomes: [
          OutcomeDef(
            id: 'ok',
            weight: 58,
            title: 'The pier stays dark',
            body: 'The crates change hands. Nobody writes a poem about it.',
            log: 'Finished a night run on the water.',
            stats: {'money': 1100, 'heat': 12, 'nerve': 3, 'reputation': 3},
            addFlags: ['smuggler', 'docks_interest', 'did_first_score'],
          ),
          OutcomeDef(
            id: 'wet',
            weight: 27,
            title: 'A torn schedule',
            body: 'A late cutter spoils the timing. You dump the loud part and keep your name.',
            log: 'A night run went half-wrong.',
            stats: {'money': 200, 'heat': 14, 'stress': 9, 'nerve': 1},
            addFlags: ['smuggler'],
          ),
          OutcomeDef(
            id: 'net',
            weight: 15,
            title: 'Harbor lights, wrong kind',
            body: 'Uniforms find the boat. The story becomes a booking number.',
            log: 'Caught on a night run.',
            stats: {'heat': 18, 'reputation': -4, 'money': -300},
            arrest: true,
            setPrisonYears: 2,
          ),
        ],
      ),
      ActivityDef(
        id: 'robbery',
        name: 'Hard take',
        description: 'Walk into a room that does not want you and leave with what it was holding.',
        category: 'crime',
        art: 'heist',
        requires: RequireDef(minStats: {'nerve': 40}, minCrew: 1),
        outcomes: [
          OutcomeDef(
            id: 'ok',
            weight: 50,
            title: 'Loud and paid',
            body: 'The crew holds. The take is ugly money with a short memory.',
            log: 'Hit a hard take with the crew.',
            stats: {'money': 1600, 'heat': 20, 'reputation': 6, 'nerve': 4, 'stress': 10},
            addFlags: ['robber', 'made_name'],
            crewLoyaltyDelta: 4,
          ),
          OutcomeDef(
            id: 'hurt',
            weight: 28,
            title: 'Someone bleeds',
            body: 'The room fights back. You leave heavier and worse.',
            log: 'A hard take left someone hurt.',
            stats: {'money': 900, 'heat': 22, 'health': -18, 'stress': 14, 'reputation': 2},
            injury: true,
            addFlags: ['robber'],
          ),
          OutcomeDef(
            id: 'cage',
            weight: 16,
            title: 'The alarm was earlier',
            body: 'Sirens eat the block. A lawyer will have opinions.',
            log: 'Busted after a hard take.',
            stats: {'heat': 24, 'reputation': -6, 'money': -400},
            arrest: true,
            setPrisonYears: 3,
          ),
          OutcomeDef(
            id: 'dead',
            weight: 6,
            title: 'The room wins',
            body: 'Ravenport does not always send you home.',
            log: 'Died on a hard take.',
            stats: {'health': -100},
            death: true,
          ),
        ],
      ),
      ActivityDef(
        id: 'cyber',
        name: 'Quiet ledger',
        description: 'A white-collar lift through screens and stolen passwords — fiction, not a manual.',
        category: 'crime',
        art: 'office',
        requires: RequireDef(minStats: {'intelligence': 42}),
            outcomes: [
          OutcomeDef(
            id: 'ok',
            weight: 58,
            title: 'Numbers walk',
            body: 'A sleepy account wakes up poorer. You were never in the building.',
            log: 'Lifted a quiet ledger.',
            stats: {'money': 1200, 'heat': 14, 'intelligence': 3, 'reputation': 2},
            addFlags: ['cyber_debut', 'did_first_score'],
            rivalDelta: {'vex': 4},
          ),
          OutcomeDef(
            id: 'trace',
            weight: 30,
            title: 'A breadcrumb',
            body: 'House Vex or a bored analyst notices the pattern. Heat without handcuffs — for now.',
            log: 'A quiet ledger left a trace.',
            stats: {'money': 200, 'heat': 22, 'stress': 8, 'intelligence': 1},
            addFlags: ['cyber_debut', 'da_file'],
          ),
          OutcomeDef(
            id: 'busted',
            weight: 12,
            title: 'The glass remembered',
            body: 'A login that should have been weather becomes a booking number.',
            log: 'A quiet ledger ended at a desk.',
            stats: {'heat': 18, 'reputation': -3, 'stress': 10, 'money': -120},
            arrest: true,
            setPrisonYears: 1,
            addFlags: ['cyber_debut', 'da_file'],
          ),
        ],
      ),
      ActivityDef(
        id: 'turf',
        name: 'Press a block',
        description: 'Walk a neighborhood like it already knows your surname.',
        category: 'crime',
        art: 'street',
        requires: RequireDef(minCrew: 1, minStats: {'reputation': 12}),
        outcomes: [
          OutcomeDef(
            id: 'ok',
            weight: 55,
            title: 'The block nods',
            body: 'A corner that used to belong to rumor now belongs to you on paper nobody files.',
            log: 'Pressed a block and held it.',
            stats: {'reputation': 5, 'heat': 8, 'nerve': 2, 'money': 700},
            territoryGain: 'old_quarter',
            rivalDelta: {'rooke': 6},
          ),
          OutcomeDef(
            id: 'pushback',
            weight: 45,
            title: 'Someone pushes back',
            body: 'A rival crew paints over your warning. The street stays contested.',
            log: 'A turf press met resistance.',
            stats: {'heat': 12, 'stress': 7, 'health': -6, 'reputation': 1},
            rivalDelta: {'rooke': 10},
          ),
        ],
      ),
      ActivityDef(
        id: 'heist_prep',
        name: 'Study a house',
        description: 'Spend the year learning a building\'s habits. The job, if it comes, is still a story.',
        category: 'crime',
        art: 'skyline',
        requires: RequireDef(minStats: {'intelligence': 35, 'nerve': 30}),
        outcomes: [
          OutcomeDef(
            id: 'ok',
            weight: 100,
            title: 'Habits on paper',
            body: 'You know when the lights go off on the hill. Knowing is not the same as walking in.',
            log: 'Mapped a house on the hill.',
            stats: {'intelligence': 3, 'stress': 4, 'heat': 3},
            addFlags: ['heist_planned', 'glassridge_lead'],
            queueEvent: {'eventId': 'glassridge_tip', 'yearsAhead': 0},
          ),
        ],
      ),
      ActivityDef(
        id: 'court',
        name: 'Walk the rooms',
        description: 'Dinners, clubs, and names. Ravenport marries people who show up twice.',
        category: 'family',
        art: 'club',
        freeWorldOnly: true,
        outcomes: [
          OutcomeDef(
            id: 'spark',
            weight: 70,
            title: 'A second drink',
            body: 'Someone laughs at the right time. The city allows a maybe.',
            log: 'Courted someone in Harbor Lights.',
            stats: {'charisma': 3, 'stress': -4, 'money': -180},
            addFlags: ['courted'],
            marry: false,
            spawnChildChance: 0,
          ),
          OutcomeDef(
            id: 'vows',
            weight: 30,
            title: 'A private yes',
            body: 'The year ends with a ring that is not a metaphor.',
            log: 'The walk through the rooms ended in vows.',
            stats: {'charisma': 4, 'loyalty': 4, 'stress': -6, 'money': -600},
            addFlags: ['courted', 'married'],
            marry: true,
          ),
        ],
      ),
      ActivityDef(
        id: 'family_time',
        name: 'Sit with family',
        description: 'Dinner, a phone call, showing up. People remember.',
        category: 'family',
        art: 'family',
        outcomes: [
          OutcomeDef(
            id: 'ok',
            weight: 100,
            title: 'The table holds',
            body: 'Nobody solves the city. Someone passes the bread anyway.',
            log: 'Spent the year close to family.',
            stats: {'loyalty': 6, 'stress': -10, 'charisma': 2, 'health': 2},
            addFlags: ['loyal_crew'],
          ),
        ],
      ),
      ActivityDef(
        id: 'train_mind',
        name: 'Read the city',
        description: 'Ledgers, law, and the way Ravenport lies in print.',
        category: 'life',
        art: 'office',
        freeWorldOnly: false,
        outcomes: [
          OutcomeDef(
            id: 'ok',
            weight: 100,
            title: 'Sharper',
            body: 'You come out of the year harder to fool.',
            log: 'Studied.',
            stats: {'intelligence': 5, 'stress': 3, 'money': -80},
          ),
        ],
      ),
      ActivityDef(
        id: 'train_body',
        name: 'Keep the body',
        description: 'Gyms, long walks, and not dying of the job\'s weather.',
        category: 'life',
        art: 'home',
        freeWorldOnly: false,
        outcomes: [
          OutcomeDef(
            id: 'ok',
            weight: 100,
            title: 'Blood moves',
            body: 'Health is a kind of money you cannot launder.',
            log: 'Trained the body.',
            stats: {'health': 8, 'stress': -6, 'nerve': 2},
          ),
        ],
      ),
      ActivityDef(
        id: 'side_hustle',
        name: 'Honest hours',
        description: 'Diner shifts, warehouse days, anything with a time clock.',
        category: 'life',
        art: 'street',
        outcomes: [
          OutcomeDef(
            id: 'ok',
            weight: 72,
            title: 'Paycheck weather',
            body: 'It is not a skyline. It is groceries.',
            log: 'Worked honest hours.',
            stats: {'money': 360, 'stress': 6, 'heat': -3, 'reputation': -1},
            addFlags: ['legitimate_turn'],
          ),
          OutcomeDef(
            id: 'cut',
            weight: 28,
            title: 'The shift was cut',
            body: 'They sent people home early. Rent does not care.',
            log: 'Honest hours came up short.',
            stats: {'money': 90, 'stress': 8, 'heat': -1},
            addFlags: ['legitimate_turn'],
          ),
        ],
      ),
      ActivityDef(
        id: 'lawyer',
        name: 'Retain counsel',
        description: 'Pay someone who speaks fluent courthouse.',
        category: 'police',
        art: 'court',
        freeWorldOnly: false,
        requires: RequireDef(minMoney: 1200),
        outcomes: [
          OutcomeDef(
            id: 'ok',
            weight: 100,
            title: 'A better voice',
            body: 'The lawyer does not like you. They like the retainer.',
            log: 'Retained a lawyer.',
            stats: {'money': -1800, 'heat': -6, 'stress': -4},
            addFlags: ['lawyered'],
          ),
        ],
      ),
      ActivityDef(
        id: 'manage',
        name: 'Walk the books',
        description: 'Visit the fronts. Fire a thief. Raise a cover.',
        category: 'business',
        art: 'office',
        requires: RequireDef(hasBusiness: true),
        outcomes: [
          OutcomeDef(
            id: 'ok',
            weight: 100,
            title: 'Ink and keys',
            body: 'Cover thickens. Quality ticks. The take still comes from the front, not from this walk.',
            log: 'Walked the books. Cover and quality, not a paycheck.',
            stats: {'heat': -3, 'intelligence': 1},
          ),
        ],
      ),
      ActivityDef(
        id: 'retire',
        name: 'Leave the chair',
        description: 'If an adult child or kin can sit, you can walk into weather that is only weather.',
        category: 'life',
        art: 'home',
        minAge: 55,
        requires: RequireDef(minChildrenAdult: 0),
        outcomes: [
          OutcomeDef(
            id: 'ok',
            weight: 100,
            title: 'The hat stays on the peg',
            body: 'You name a successor and step into a quieter rain.',
            log: 'Retired from the chair.',
            retire: true,
            addFlags: ['legitimate_turn'],
          ),
        ],
      ),
      ActivityDef(
        id: 'prison_work',
        name: 'Take the work detail',
        description: 'Kitchen, laundry, silence. Time moves if you let it.',
        category: 'prison',
        art: 'prison',
        prisonOnly: true,
        freeWorldOnly: false,
        outcomes: [
          OutcomeDef(
            id: 'ok',
            weight: 70,
            title: 'The hours behave',
            body: 'You keep your head down and your name small.',
            log: 'Worked a prison detail.',
            stats: {'stress': -4, 'loyalty': 1, 'money': 40},
            addFlags: ['prison_rep'],
          ),
          OutcomeDef(
            id: 'bruise',
            weight: 30,
            title: 'A lesson in the steam',
            body: 'Someone wanted the easy station. You leave the kitchen heavier.',
            log: 'The work detail turned ugly.',
            stats: {'health': -8, 'stress': 6, 'money': 10},
            injury: true,
            addFlags: ['prison_rep'],
          ),
        ],
      ),
      ActivityDef(
        id: 'prison_study',
        name: 'Use the library cart',
        description: 'Law, letters, and the long arithmetic of appeals.',
        category: 'prison',
        art: 'prison',
        prisonOnly: true,
        freeWorldOnly: false,
        outcomes: [
          OutcomeDef(
            id: 'ok',
            weight: 68,
            title: 'Pages',
            body: 'You learn the shape of the door even if it stays shut.',
            log: 'Studied inside.',
            stats: {'intelligence': 4, 'stress': -2},
            addFlags: ['appealed'],
          ),
          OutcomeDef(
            id: 'miss',
            weight: 32,
            title: 'The cart skipped you',
            body: 'The books went to another table. You sit with the same year.',
            log: 'The library cart passed you by.',
            stats: {'stress': 4, 'intelligence': 1},
          ),
        ],
      ),
      ActivityDef(
        id: 'prison_politics',
        name: 'Pick a table',
        description: 'Every yard has governments. You can sit with one or none.',
        category: 'prison',
        art: 'prison',
        prisonOnly: true,
        freeWorldOnly: false,
        outcomes: [
          OutcomeDef(
            id: 'ok',
            weight: 70,
            title: 'A useful silence',
            body: 'The right nod at the right table. You eat. You keep your face.',
            log: 'Found a prison table.',
            stats: {'nerve': 2, 'reputation': 2, 'heat': -2},
            addFlags: ['prison_rep'],
          ),
          OutcomeDef(
            id: 'hurt',
            weight: 30,
            title: 'The wrong table',
            body: 'A lesson with bruises. You will sit elsewhere.',
            log: 'Prison politics went bad.',
            stats: {'health': -10, 'stress': 8, 'nerve': 1},
            injury: true,
          ),
        ],
      ),
    ];

    return list.where((a) {
      if (state.age < a.minAge) return false;
      if (a.prisonOnly && !state.inPrison) return false;
      if (a.freeWorldOnly && state.inPrison) return false;
      if (a.id == 'retire' && eligibleHeirs().isEmpty) return false;
      if (a.id == 'court' && _spouse() != null) return false;
      if (a.id == 'robbery' && !_hasRole(['driver', 'lookout'])) return false;
      if (a.id == 'cyber' && !_hasRole(['hacker']) && state.stats.intelligence < 55) return false;
      if (a.id == 'smuggle' && state.crew.isNotEmpty && !_hasRole(['driver', 'lookout', 'muscle'])) {
        return false;
      }
      return _unmetReason(a.requires) == null || a.id == 'retire';
    }).toList();
  }

  bool openActivity(String id) {
    if (yearVerbUsed) return false;
    if (state.currentEventId != null) return false;
    final acts = activities();
    final a = acts.cast<ActivityDef?>().firstWhere((e) => e!.id == id, orElse: () => null);
    if (a == null) return false;
    final fake = catalog.activityAsEvent(a);
    catalog.byId[fake.id] = fake;
    state.currentEventId = fake.id;
    state.phase = 'event';
    state.retryUsed = false;
    return true;
  }

  ResolveResult doActivity(String id) {
    if (yearVerbUsed) {
      return ResolveResult(
        event: EventDef(id: 'none', title: '', body: ''),
        outcome: OutcomeDef(title: 'Not now', body: 'You already spent the year\'s move.'),
        skipped: true,
      );
    }
    final acts = activities();
    final a = acts.cast<ActivityDef?>().firstWhere((e) => e!.id == id, orElse: () => null);
    if (a == null) {
      return ResolveResult(
        event: EventDef(id: 'none', title: '', body: ''),
        outcome: OutcomeDef(title: 'Not now', body: 'That door is closed this year.'),
        skipped: true,
      );
    }
    final fake = catalog.activityAsEvent(a);
    state.currentEventId = fake.id;
    // Temporarily register
    catalog.byId[fake.id] = fake;
    final result = choose('go');
    catalog.byId.remove(fake.id);
    return result;
  }

  static const hireCost = 300;
  static const bonusCost = 180;
  static const investCost = 350;
  static const pressCost = 700;
  static const coolCost = 220;
  static const giftCost = 150;
  static const frontCost = 800;
  static const tributeCost = 400;

  static String? unaffordable(int have, int cost) {
    if (have >= cost) return null;
    return 'Need \$${cost - have} more';
  }

  static String choiceHint(ChoiceDef ch) {
    var pay = false, cost = false, heat = false, risk = false, calm = false, bond = false;
    for (final o in ch.outcomes) {
      final m = o.stats['money'] ?? 0;
      final h = o.stats['heat'] ?? 0;
      if (m > 0) pay = true;
      if (m < 0) cost = true;
      if (h > 0) heat = true;
      if (o.isHarsh || o.arrest || o.injury || o.death) risk = true;
      if ((o.stats['stress'] ?? 0) < 0) calm = true;
      if ((o.stats['loyalty'] ?? 0) > 0 || o.marry || o.spawnChildChance > 0) bond = true;
    }
    return [
      if (pay) 'pay',
      if (cost) 'costs',
      if (heat) 'heat',
      if (risk) 'risk',
      if (calm) 'calm',
      if (bond) 'bond',
    ].join(' · ');
  }

  String hireStreetRole() {
    final have = state.crew.map((c) => c.role).toSet();
    if (!have.contains('enforcer')) return 'enforcer';
    if (!have.contains('muscle')) return 'muscle';
    return 'lookout';
  }

  String hireBooksRole() {
    final have = state.crew.map((c) => c.role).toSet();
    if (!have.contains('accountant')) return 'accountant';
    if (!have.contains('hacker')) return 'hacker';
    return 'driver';
  }

  String? hireHand([String? role]) {
    if (state.inPrison) return 'You cannot hire from inside.';
    if (state.crew.length >= 5) return 'Five names is a full book.';
    final books = empireBlock();
    if (books != null) return books;
    if (state.stats.money < hireCost) return 'Need \$$hireCost to hire.';
    state.stats.money -= hireCost;
    _recruitCrew(role: role ?? _neededRole());
    _spendEmpire();
    return null;
  }

  String? payBonus(String personId) {
    final m = _crewOf(personId);
    if (m == null) return 'They already walked.';
    final books = empireBlock();
    if (books != null) return books;
    if (state.stats.money < bonusCost) return 'Need \$$bonusCost.';
    state.stats.money -= bonusCost;
    m.loyalty = min(100, m.loyalty + 12);
    _spendEmpire();
    state.log('Paid a quiet bonus to ${state.people[personId]?.firstName ?? 'a hand'}.', category: 'crew');
    return null;
  }

  String? bumpCut(String personId) {
    final m = _crewOf(personId);
    if (m == null) return 'They already walked.';
    if (m.cut >= 24) return 'Their cut is already fat.';
    m.cut = min(24, m.cut + 2);
    m.loyalty = min(100, m.loyalty + 6);
    state.log('Raised a cut. Loyalty follows money.', category: 'crew');
    return null;
  }

  String? letGo(String personId) {
    final m = _crewOf(personId);
    if (m == null) return 'Already gone.';
    state.crew.remove(m);
    final p = state.people[personId];
    if (p != null) p.lifePath = 'unknown';
    if (state.crew.isEmpty) state.flags.remove('has_crew');
    state.log('${p?.name ?? 'A hand'} was let go.', category: 'crew');
    return null;
  }

  List<String> availableFrontTypes() {
    final used = state.businesses.map((b) => b.type).toSet();
    return WorldContent.businessMeta.keys.where((k) => !used.contains(k)).toList();
  }

  String? buyFrontReason() {
    if (state.inPrison) return 'You cannot open a front from inside.';
    if (availableFrontTypes().isEmpty) return 'Every front is already open.';
    final books = empireBlock();
    if (books != null) return books;
    return unaffordable(state.stats.money, frontCost);
  }

  String? buyFront([String? type]) {
    if (state.inPrison) return 'You cannot open a front from inside.';
    final types = availableFrontTypes();
    if (types.isEmpty) return 'Every front is already open.';
    final books = empireBlock();
    if (books != null) return books;
    if (state.stats.money < frontCost) return 'Need \$$frontCost to open a front.';
    final pick = (type != null && types.contains(type)) ? type : types.first;
    state.stats.money -= frontCost;
    _gainBusiness(pick);
    _spendEmpire();
    return null;
  }

  String? investFront(String bizId) {
    final b = state.businesses.cast<Business?>().firstWhere((e) => e!.id == bizId, orElse: () => null);
    if (b == null) return 'That front is gone.';
    final books = empireBlock();
    if (books != null) return books;
    if (b.quality >= 100) return 'That front is as good as the rain allows.';
    if (state.stats.money < investCost) return 'Need \$$investCost to invest.';
    state.stats.money -= investCost;
    final fat = b.quality >= 80;
    b.yearlyIncome += fat ? 80 : 180;
    b.value += fat ? 400 : 900;
    b.quality = min(100, b.quality + (fat ? 2 : 6));
    _spendEmpire();
    state.log('Poured cash into ${b.name}.', category: 'business');
    _recomputeAssets();
    return null;
  }

  String? pressTurf(String id) {
    if (state.inPrison) return 'You cannot press turf from inside.';
    final blocked = yearVerbBlock('street');
    if (blocked != null) return blocked;
    if (state.crew.isEmpty) return 'Need at least one hand.';
    if (state.stats.money < pressCost) return 'Need \$$pressCost to press a street.';
    final t = state.territories.cast<Territory?>().firstWhere((e) => e!.id == id, orElse: () => null);
    if (t == null) return 'No such street.';
    if (t.controller == 'player') return 'You already hold it.';
    state.stats.money -= pressCost;
    state.stats.heat = min(100, state.stats.heat + 8);
    _spendYearVerb('street');
    lastPressResult = null;
    if (t.controller != null && t.controller != 'player') {
      final r = state.rivals.cast<RivalFamily?>().firstWhere((e) => e!.id == t.controller, orElse: () => null);
      if (r != null) {
        final skill = state.crew.isEmpty
            ? 0
            : state.crew.fold<int>(0, (n, c) => n + c.skill) ~/ state.crew.length;
        var bonus = state.stats.nerve ~/ 4;
        if (_hasRole(['muscle', 'enforcer'])) bonus += 10;
        if (r.personality == 'aggressive') bonus -= 8;
        if (r.personality == 'calculating') bonus -= 4;
        if (r.personality == 'opportunistic') bonus += 2;
        final roll = skill ~/ 3 + bonus + rng.nextInt(50);
        final dc = 36 + r.power ~/ 2;
        r.hostility = min(100, r.hostility + 6);
        if (roll < dc) {
          state.stats.health = max(1, state.stats.health - 6);
          state.stats.stress = min(100, state.stats.stress + 6);
          lastPressResult = '${r.name} held ${t.name}. The press failed.';
          state.log(lastPressResult!, category: 'rival');
          return null;
        }
      }
    }
    _gainTerritory(id);
    lastPressResult = 'The ${state.dynastyName} name holds ${t.name}.';
    return null;
  }

  String? coolTurf(String id) {
    final blocked = yearVerbBlock('street');
    if (blocked != null) return blocked;
    final t = state.territories.cast<Territory?>().firstWhere((e) => e!.id == id, orElse: () => null);
    if (t == null) return 'No such street.';
    if (t.controller != 'player') return 'You do not hold it.';
    if (state.stats.money < coolCost) return 'Need \$$coolCost to cool it.';
    state.stats.money -= coolCost;
    t.heat = max(0, t.heat - 8);
    state.stats.heat = max(0, state.stats.heat - 4);
    _spendYearVerb('street');
    state.log('${t.name} went quieter for a night.', category: 'rival');
    return null;
  }

  String? squeezeTurf(String id) {
    final blocked = yearVerbBlock('street');
    if (blocked != null) return blocked;
    final t = state.territories.cast<Territory?>().firstWhere((e) => e!.id == id, orElse: () => null);
    if (t == null) return 'No such street.';
    if (t.controller != 'player') return 'You do not hold it.';
    t.income += 90;
    t.heat = min(40, t.heat + 10);
    state.stats.heat = min(100, state.stats.heat + 6);
    state.stats.money += 80;
    _spendYearVerb('street');
    lastPressResult = '${t.name} was squeezed. Louder take. Louder heat.';
    state.log(lastPressResult!, category: 'rival');
    return null;
  }

  String? quietTurf(String id) {
    final blocked = yearVerbBlock('street');
    if (blocked != null) return blocked;
    final t = state.territories.cast<Territory?>().firstWhere((e) => e!.id == id, orElse: () => null);
    if (t == null) return 'No such street.';
    if (t.controller != 'player') return 'You do not hold it.';
    t.income = max(180, t.income - 70);
    t.heat = max(0, t.heat - 10);
    t.influence = min(100, t.influence + 4);
    state.stats.heat = max(0, state.stats.heat - 6);
    _spendYearVerb('street');
    lastPressResult = '${t.name} went quiet. Less take. The crest sits.';
    state.log(lastPressResult!, category: 'rival');
    return null;
  }

  String? tributeTurf(String id) {
    final blocked = yearVerbBlock('street');
    if (blocked != null) return blocked;
    final t = state.territories.cast<Territory?>().firstWhere((e) => e!.id == id, orElse: () => null);
    if (t == null) return 'No such street.';
    if (t.controller != 'player') return 'You do not hold it.';
    if (state.stats.money < tributeCost) return 'Need \$$tributeCost to pay tribute.';
    final r = hottestRival();
    if (r == null) return 'No house to pay.';
    state.stats.money -= tributeCost;
    r.hostility = max(0, r.hostility - 10);
    t.heat = max(0, t.heat - 4);
    _spendYearVerb('street');
    lastPressResult = 'Tribute walked to ${r.name}. ${t.name} bought a quieter week.';
    state.log(lastPressResult!, category: 'rival');
    return null;
  }

  bool get satThisYear => state.flags.contains('sat_year_${state.year}');
  bool get giftedThisYear => state.flags.contains('gift_year_${state.year}');

  String? satPersonId() {
    final prefix = 'sat_who_${state.year}_';
    for (final f in state.flags) {
      if (f.startsWith(prefix)) return f.substring(prefix.length);
    }
    return null;
  }

  String? giftedPersonId() {
    final prefix = 'gift_who_${state.year}_';
    for (final f in state.flags) {
      if (f.startsWith(prefix)) return f.substring(prefix.length);
    }
    return null;
  }

  Person? satPerson() {
    final id = satPersonId();
    return id == null ? null : state.people[id];
  }

  Person? giftedPerson() {
    final id = giftedPersonId();
    return id == null ? null : state.people[id];
  }

  String familyCapBlurb() {
    final sit = satThisYear
        ? 'Sat with ${satPerson()?.firstName ?? 'someone'} this year.'
        : 'Sit with one person this year.';
    final gift = giftedThisYear
        ? 'Gifted ${giftedPerson()?.firstName ?? 'someone'} this year.'
        : 'Gift one person this year.';
    return '$sit $gift Separate yearly caps.';
  }

  OutcomeDef sitScene(Person p) {
    final flags = state.flags;
    final line = switch (p.id) {
      'p_mentor' => flags.contains('will_burn_crowe')
          ? 'He still poured the coffee. You both pretended the ferry name was weather.'
          : (flags.contains('sat_ever_p_mentor')
              ? 'The second hour is quieter. Crowe still talks around the job.'
              : 'Crowe talked around the job and still said everything.'),
      'p_foil' => flags.contains('lied_to_vale')
          ? 'She let the lie sit between the cups. The photograph stayed in her coat.'
          : (flags.contains('vale_respect')
              ? 'Vale did not take out a notebook. That is a kind of mercy.'
              : 'Vale let the silence work. You both pretended it was coffee.'),
      'p_cass' => flags.contains('cass_notice')
          ? 'Cass smiled like the gold card had already been opened.'
          : 'Cass smiled like a contract. The gold caught the rain.',
      'p_mira' => flags.contains('courted')
          ? 'She ordered the second drink before you sat down. Harbor Lights already knew the tab.'
          : (flags.contains('sat_ever_p_mira')
              ? 'The booth was the same. Mira did not ask what the year cost.'
              : 'Harbor Lights after midnight. She remembered the second drink.'),
      'p_ben' => flags.contains('courted')
          ? 'Bennett talked like a surname was a lease you could still sign.'
          : (flags.contains('sat_ever_p_ben')
              ? 'He still wanted daylight. He waited to see if you had brought any.'
              : 'Bennett wanted a daylight surname and waited to see if yours would do.'),
      _ => switch (p.relation) {
          'sibling' => 'You split a bottle like you used to steal streetlights.',
          'mentor' => 'Crowe talked around the job and still said everything.',
          'foil' => 'Vale let the silence work. You both pretended it was coffee.',
          'spouse' => 'The table held. For an hour the city was someone else\'s.',
          'child' => 'They asked a question you answered like a person, not a boss.',
          _ => 'Rain on the glass. Two cups. No ledger between you.',
        },
    };
    return OutcomeDef(
      id: 'sit',
      title: 'Sat with ${p.firstName}',
      body: '$line Bond ${p.bond}. The year has one quiet hour, and you spent it.',
      log: 'Sat with ${p.firstName}.',
      stats: {'stress': -5, 'loyalty': 2},
    );
  }

  String? sitWith(String personId) {
    final p = state.people[personId];
    if (p == null || !p.isAlive || p.id == player.id) return 'No one to sit with.';
    if (satThisYear) return 'You already sat with someone this year.';
    state.flags.add('sat_year_${state.year}');
    state.flags.add('sat_who_${state.year}_$personId');
    state.flags.add('sat_ever_$personId');
    p.bond = min(100, p.bond + 10);
    p.loyaltyToFamily = min(100, p.loyaltyToFamily + 6);
    if (_sitCount(personId, 5) >= 3) {
      if (p.id == 'p_foil' || p.lifePath == 'legal') {
        state.flags.add('lean_legal_$personId');
        state.flags.remove('lean_family_$personId');
      } else {
        state.flags.add('lean_family_$personId');
        state.flags.remove('lean_legal_$personId');
      }
    }
    if (p.lifePath == 'rival' && p.bond >= 45) {
      p.lifePath = 'family';
      p.rivalFamilyId = null;
      state.log('${p.firstName} came back to the table after enough quiet hours.', category: 'family');
    }
    state.stats.stress = max(0, state.stats.stress - 5);
    state.stats.loyalty = min(100, state.stats.loyalty + 2);
    state.log('Sat with ${p.firstName}. The year felt less sharp.', category: 'family');
    return null;
  }

  String? giftPerson(String personId) {
    final p = state.people[personId];
    if (p == null || !p.isAlive || p.id == player.id) return 'No one to gift.';
    if (giftedThisYear) return 'You already gifted someone this year.';
    if (state.stats.money < giftCost) return GameEngine.unaffordable(state.stats.money, giftCost) ?? 'Need \$$giftCost.';
    state.stats.money -= giftCost;
    state.flags.add('gift_year_${state.year}');
    state.flags.add('gift_who_${state.year}_$personId');
    p.bond = min(100, p.bond + 12);
    p.loyaltyToFamily = min(100, p.loyaltyToFamily + 6);
    state.log('A small gift for ${p.firstName}.', category: 'family');
    return null;
  }

  String? assignCrew(String personId, [String? bizId]) {
    final m = _crewOf(personId);
    if (m == null) return 'They already walked.';
    if (state.businesses.isEmpty) return 'No front to assign.';
    if (bizId != null) {
      if (bizId.isEmpty) {
        m.assignedBizId = null;
        state.log('${state.people[personId]?.firstName ?? 'A hand'} is off the shop floor.', category: 'crew');
        return null;
      }
      final named = state.businesses.cast<Business?>().firstWhere((e) => e!.id == bizId, orElse: () => null);
      if (named == null) return 'No front by that name.';
      m.assignedBizId = named.id;
      state.log('${state.people[personId]?.firstName ?? 'A hand'} watches ${named.name}.', category: 'crew');
      return null;
    }
    final ids = <String?>[null, ...state.businesses.map((b) => b.id)];
    final i = ids.indexOf(m.assignedBizId);
    m.assignedBizId = ids[(i + 1) % ids.length];
    final b = state.businesses.cast<Business?>().firstWhere((e) => e!.id == m.assignedBizId, orElse: () => null);
    state.log(
      b == null ? '${state.people[personId]?.firstName ?? 'A hand'} is off the shop floor.' : '${state.people[personId]?.firstName ?? 'A hand'} watches ${b.name}.',
      category: 'crew',
    );
    return null;
  }

  String ambition() {
    if (state.inPrison) return 'Finish the stretch. The city will wait.';
    if (midlifePinch) {
      return pressureLine();
    }
    if (!state.flags.contains('chapter_prologue') && _emptyCityBoard && quietStreak() >= 3) {
      return 'One more quiet year and Ravenport files you under weather. Press a street.';
    }
    if (quietStreak() >= 3) return 'Three quiet years. Press a street or the houses keep the map.';
    if (quietStreak() >= 1 && !state.territories.any((t) => t.controller == 'player')) {
      return 'Honest hours fed you. They also fed the houses. Press a street.';
    }
    final war = warLine();
    if (war != null) return war;
    if (state.crew.isEmpty && state.stats.money < hireCost) return 'Earn enough to hire a hand.';
    if (state.crew.isEmpty) return 'Hire a hand on Empire.';
    if (!satThisYear && state.year > WorldContent.startYear) return 'Sit with one person on Family.';
    if (state.businesses.isEmpty) {
      return 'Open a front on Empire when you can stand \$$frontCost, or play a year for a key.';
    }
    if (state.crew.any((m) => m.assignedBizId == null) && state.businesses.isNotEmpty) {
      return 'Assign a hand to a front on Empire.';
    }
    if (!state.territories.any((t) => t.controller == 'player')) return 'Press a street on City.';
    if (state.stats.heat > 55) return 'Cool the city. Heat is loud.';
    final thin = state.people.values.where((p) => p.isAlive && p.id != player.id && p.bond < 28).toList();
    if (thin.isNotEmpty) return 'Sit with ${thin.first.firstName}. The bond is thin.';
    final hot = hottestRival();
    if (hot != null && hot.hostility >= 45) return '${hot.name} ${houseWeather(hot)}. Watch City.';
    if (state.stats.money < 1500) return 'Keep the books green this year.';
    return 'Hold the name. The rain is watching.';
  }

  String pressureLine() {
    if (state.inPrison) return 'The corridor is the only weather that counts.';
    if (!state.flags.contains('chapter_prologue') && _emptyCityBoard && (quietStreak() >= 2 || yieldCount() >= 3)) {
      return 'No street, no front, no crew. Quiet years now close the file — Game Over, not a dynasty.';
    }
    if (quietStreak() >= 1) {
      return 'A quiet job left the map moving. Press, cool, or take a risk — or a house keeps eating streets.';
    }
    if (warPhase != null) {
      return 'The war is the year\'s invoice. Stand on the card, or a street walks.';
    }
    if (state.stats.heat >= 60) {
      return 'Heat is loud. Cool a street or keep counsel — ignore it and Vale finds the year.';
    }
    if (state.crew.isEmpty) {
      return 'No hands on the book. Hire, or a house will invoice the empty year.';
    }
    final hotTurf = state.territories.where((t) => t.controller == 'player' && t.heat >= 16);
    if (hotTurf.isNotEmpty) {
      return '${hotTurf.first.name} is running hot. Cool it or the crest slips.';
    }
    if (state.businesses.isEmpty && !state.territories.any((t) => t.controller == 'player')) {
      return 'No front, no street. Ignore that and the year bills you for being small.';
    }
    final thin = state.people.values
        .where((p) => p.isAlive && p.id != player.id && _isFamily(p) && p.bond < 28)
        .toList();
    if (thin.isNotEmpty) return '${thin.first.firstName} is drifting. Sit, or the name thins.';
    final hot = hottestRival();
    if (hot != null && hot.hostility >= 45) {
      return '${hot.name} ${houseWeather(hot)}. A war season is weather you can still spend.';
    }
    if (state.stats.money < 400) return 'The books are thin. Honest hours or a louder night.';
    return 'Hold the name. The rain is watching.';
  }

  String? pressureId() {
    if (state.inPrison || state.flags.contains('chapter_prologue')) return null;
    if (warPhase != null) return null;
    if (state.stats.heat >= 60) return 'heat';
    if (state.crew.isEmpty) return 'crew';
    if (state.territories.any((t) => t.controller == 'player' && t.heat >= 16)) return 'turf_heat';
    if (state.businesses.isEmpty && !state.territories.any((t) => t.controller == 'player')) {
      return 'hold';
    }
    final thin = state.people.values
        .where((p) => p.isAlive && p.id != player.id && _isFamily(p) && p.bond < 28)
        .toList();
    if (thin.isNotEmpty) return 'family_${thin.first.id}';
    return null;
  }

  String inheritBlurb() {
    final fronts = state.businesses.length;
    final streets = state.territories.where((t) => t.controller == 'player').length;
    final heirs = eligibleHeirs();
    final next = heirs.isEmpty ? 'No heir yet. A sibling, cousin, or child can take the chair.' : '${heirs.first.name} is first in line.';
    return 'The name keeps cash, $fronts front${fronts == 1 ? '' : 's'}, and $streets street${streets == 1 ? '' : 's'}. Heat and reputation fade. Crew may walk. $next';
  }

  RivalFamily? hottestRival() {
    if (state.rivals.isEmpty) return null;
    return state.rivals.reduce((a, b) => a.hostility >= b.hostility ? a : b);
  }

  String? get warPhase {
    if (state.flags.contains('war_phase_threat')) return 'threat';
    if (state.flags.contains('war_phase_escalate')) return 'escalate';
    if (state.flags.contains('war_phase_resolve')) return 'resolve';
    return null;
  }

  RivalFamily? warRival() {
    for (final f in state.flags) {
      if (f.startsWith('war_rival_')) {
        final id = f.substring('war_rival_'.length);
        return state.rivals.cast<RivalFamily?>().firstWhere((e) => e!.id == id, orElse: () => null);
      }
    }
    return null;
  }

  int? _warCoolUntil() {
    for (final f in state.flags) {
      if (f.startsWith('war_cool_until_')) {
        return int.tryParse(f.substring('war_cool_until_'.length));
      }
    }
    return null;
  }

  void _setWar(String phase, RivalFamily r) {
    state.flags.removeWhere((f) => f.startsWith('war_phase_') || f.startsWith('war_rival_'));
    state.flags.add('war_phase_$phase');
    state.flags.add('war_rival_${r.id}');
  }

  void _clearWar() {
    state.flags.removeWhere((f) => f.startsWith('war_phase_') || f.startsWith('war_rival_'));
  }

  String? warLine() {
    final phase = warPhase;
    if (phase == null) return null;
    final name = warRival()?.name ?? hottestRival()?.name ?? 'A rival house';
    final marked = warTarget()?.name;
    final stake = marked ?? 'the docks';
    return switch (phase) {
      'threat' => '$name marked $stake. War season.',
      'escalate' => '$name is taking $stake. The war is hot.',
      'resolve' => 'The war with $name is breaking over $stake.',
      _ => '$name has not forgotten you.',
    };
  }

  Territory? warTarget() {
    for (final f in state.flags) {
      if (f.startsWith('war_target_')) {
        final id = f.substring('war_target_'.length);
        return state.territories.cast<Territory?>().firstWhere((e) => e!.id == id, orElse: () => null);
      }
    }
    return null;
  }

  void _markWarStreet(RivalFamily r, List<String> logs) {
    state.flags.removeWhere((f) => f.startsWith('war_target_'));
    final mine = state.territories.where((t) => t.controller == 'player').toList();
    final open = state.territories.where((t) => t.controller == null).toList();
    final pick = mine.isNotEmpty ? rng.pick(mine) : (open.isNotEmpty ? rng.pick(open) : null);
    if (pick == null) return;
    state.flags.add('war_target_${pick.id}');
    logs.add('${r.name} marked ${pick.name}. ${r.name} ${houseWeather(r)}.');
  }

  String cityPressure() {
    final war = warLine();
    if (war != null) return war;
    if (state.rivals.isEmpty) return 'No houses on the board.';
    final hot = hottestRival();
    if (hot == null) return 'No houses on the board.';
    final streets = hot.territories.length;
    if (hot.hostility < 20) return 'The houses are quiet tonight.';
    return '${hot.name} ${houseWeather(hot)}. $streets street${streets == 1 ? '' : 's'} on their book.';
  }

  String? _warChoice() {
    for (final f in state.flags) {
      if (f.startsWith('war_choice_')) return f.substring('war_choice_'.length);
    }
    return null;
  }

  void _clearWarChoice() {
    state.flags.removeWhere((f) => f.startsWith('war_choice_'));
  }

  void _tryTakeBack(RivalFamily rival, List<String> logs, {bool guaranteed = false}) {
    final stolen = state.territories.where((t) => t.controller == rival.id).toList();
    if (stolen.isEmpty) return;
    if (!guaranteed && !_hasRole(['muscle', 'enforcer']) && !rng.chance(45 + state.stats.nerve ~/ 4)) {
      logs.add('You pressed back. ${rival.name} kept the corner.');
      return;
    }
    final t = rng.pick(stolen);
    t.controller = 'player';
    t.influence = max(t.influence, 48);
    rival.territories.remove(t.id);
    rival.hostility = min(100, rival.hostility + 8);
    logs.add('You took ${t.name} back from ${rival.name}.');
  }

  void tickWarSeason(List<String> logs) {
    if (state.inPrison) return;
    final phase = warPhase;
    final rival = warRival() ?? hottestRival();
    if (rival == null) return;

    if (phase == null) {
      final coolUntil = _warCoolUntil();
      if (coolUntil != null && state.year < coolUntil) return;
      if (coolUntil != null && state.year >= coolUntil) {
        state.flags.removeWhere((f) => f.startsWith('war_cool_until_'));
      }
      final extra = rival.personality == 'aggressive'
          ? 10
          : (rival.personality == 'opportunistic' ? 4 : 0);
      if (rival.hostility >= (70 - extra) || (rival.hostility >= (52 - extra) && state.year % 3 == 0)) {
        _setWar('threat', rival);
        rival.hostility = min(100, rival.hostility + 8);
        state.stats.heat = min(100, state.stats.heat + 3);
        logs.add('${rival.name} sent a warning. War season opens.');
        _markWarStreet(rival, logs);
        _queueOnce('war_threat_card');
      }
      return;
    }

    if (phase == 'threat') {
      _setWar('escalate', rival);
      final choice = _warChoice();
      var pinchBase = rival.personality == 'calculating' ? 260 : 180;
      var takeChance = rival.personality == 'calculating' ? 30 : (rival.personality == 'aggressive' ? 70 : 55);
      if (choice == 'stand') {
        takeChance = max(10, takeChance - 25);
      } else if (choice == 'pay') {
        pinchBase = 0;
        takeChance = max(8, takeChance - 18);
      } else if (choice == 'hide') {
        takeChance = min(90, takeChance + 20);
      } else if (choice == null) {
        if (rival.personality == 'calculating') {
          pinchBase = 300;
          takeChance = 22;
        } else if (rival.personality == 'aggressive') {
          takeChance = 78;
        }
      }
      final pinch = pinchBase == 0 ? 0 : min(state.stats.money, pinchBase + rng.nextInt(80));
      state.stats.money -= pinch;
      state.stats.heat = min(100, state.stats.heat + 6);
      rival.hostility = min(100, rival.hostility + 10);
      final mine = state.territories.where((t) => t.controller == 'player').toList();
      final marked = warTarget();
      if (mine.isNotEmpty && rng.chance(takeChance)) {
        final t = (marked != null && marked.controller == 'player') ? marked : rng.pick(mine);
        t.controller = rival.id;
        t.influence = 35;
        if (!rival.territories.contains(t.id)) rival.territories.add(t.id);
        logs.add('${rival.name} ${houseTakeVerb(rival)} ${t.name}. The war is hot.');
      } else if (pinch > 0) {
        logs.add('${rival.name} pressed the year. \$$pinch walked. Heat climbed.');
      } else {
        logs.add('${rival.name} pressed the year. You had already paid for weather.');
      }
      _queueOnce('war_escalate_card');
      _clearWarChoice();
      return;
    }

    if (phase == 'escalate') {
      _setWar('resolve', rival);
      final choice = _warChoice();
      if (choice == 'fight') {
        _tryTakeBack(rival, logs);
      } else if (choice == 'buy') {
        _tryTakeBack(rival, logs, guaranteed: true);
      } else if (choice == 'yield') {
        rival.hostility = max(0, rival.hostility - 6);
        final t = warTarget();
        if (t != null && t.controller == 'player') {
          t.controller = rival.id;
          t.influence = 35;
          if (!rival.territories.contains(t.id)) rival.territories.add(t.id);
          logs.add('You yielded ${t.name}. ${rival.name} kept the map.');
        } else {
          logs.add('You yielded the hot night. ${rival.name} kept the map.');
        }
      } else if (rival.hostility >= 80 && rng.chance(30)) {
        state.stats.heat = min(100, state.stats.heat + 4);
        logs.add('The war with ${rival.name} broke ugly.');
      } else {
        rival.hostility = max(0, rival.hostility - 22);
        state.stats.heat = max(0, state.stats.heat - 5);
        state.stats.reputation = min(100, state.stats.reputation + 3);
        logs.add('The war with ${rival.name} cooled. Streets remember who stood.');
      }
      _queueOnce('war_resolve_card');
      _clearWarChoice();
      return;
    }

    if (phase == 'resolve') {
      final choice = _warChoice();
      if (choice == 'truce') {
        rival.hostility = max(0, rival.hostility - 10);
      } else if (choice == 'tooth') {
        rival.hostility = min(100, rival.hostility + 6);
      }
      _clearWar();
      _clearWarChoice();
      state.flags.removeWhere((f) => f.startsWith('war_cool_until_') || f.startsWith('war_target_'));
      state.flags.add('war_cool_until_${state.year + 1}');
      logs.add('War season closed. The houses count their dead quietly.');
    }
  }

  void debugStartWar([String id = 'rooke']) {
    final r = state.rivals.firstWhere((e) => e.id == id, orElse: () => state.rivals.first);
    r.hostility = max(r.hostility, 70);
    _setWar('threat', r);
    state.stats.heat = min(100, state.stats.heat + 3);
    _markWarStreet(r, []);
  }

  CrewMember? _crewOf(String personId) {
    return state.crew.cast<CrewMember?>().firstWhere((e) => e!.personId == personId, orElse: () => null);
  }

  void debugKill([String cause = 'Fell in a test night']) => _killPlayer(cause);
  void debugBirth() => _birthChild();
  void debugPrison(int years) => _enterPrison(years);
  void debugBusiness(String type) => _gainBusiness(type);
  void debugMarry() => _marry();
  void debugTerritory(String id) => _gainTerritory(id);

  void ageUp() {
    if (state.phase == 'ending') return;
    lastUnlocks = [];
    final logs = <String>[];
    void note(String s) {
      logs.add(s);
      state.log(s);
    }

    _resolveIgnoredPressure(logs);

    // Quiet honest years donate the map. Must run before the year rolls.
    _quietCityBite(logs);

    // Prison tick
    if (state.inPrison) {
      state.prisonYearsLeft -= 1;
      state.stats.stress = min(100, state.stats.stress + 2);
      state.stats.heat = max(0, state.stats.heat - 6);
      if (player.traits.contains('Patient')) state.stats.intelligence = min(100, state.stats.intelligence + 1);
      if (state.prisonYearsLeft <= 0) {
        state.inPrison = false;
        state.flags.remove('inside');
        player.lifePath = 'family';
        note('The gate opened. Ravenport had not missed you kindly.');
        unlock('prison_out');
      } else if (state.prisonYearsLeft >= 25) {
        _beginHeir('life sentence');
        state.lastYearLog = logs;
        state.lastSummary = logs.join(' ');
        return;
      }
    }

    state.year += 1;
    state.yearsSinceInterstitial += 1;
    state.eventsThisYear = 0;
    state.activityUsed = false;

    // Economy
    if (!state.inPrison) {
      var income = 0;
      for (final b in state.businesses) {
        final hands = state.crew.where((c) => c.assignedBizId == b.id && !c.imprisoned).toList();
        final watch = hands.fold<int>(0, (n, c) {
          var add = 40 + c.skill ~/ 2;
          if (c.role == 'accountant') add += 40;
          if (c.role == 'enforcer') add += 12;
          if (c.role == 'lookout') add += 8;
          return n + add;
        });
        var pay = (b.yearlyIncome * (0.7 + b.quality / 200)).round() + watch;
        if (hands.isEmpty) {
          pay = (pay * 0.5).round();
          b.quality = max(0, b.quality - 4);
          logs.add('${b.name} ran without a hand. Half the take. Cover thinned.');
        } else {
          logs.add('${hands.length} hand${hands.length == 1 ? '' : 's'} watched ${b.name} (+$watch).');
          for (final c in hands) {
            c.loyalty = min(100, c.loyalty + 1);
          }
        }
        income += pay;
        state.stats.heat = max(0, state.stats.heat - (b.cover ~/ 4) - hands.length - (hands.any((c) => c.role == 'enforcer') ? 2 : 0));
      }
      for (final t in state.territories.where((t) => t.controller == 'player')) {
        income += t.income;
        state.stats.heat += t.heat ~/ 8;
      }
      // crew cuts
      var cuts = 0;
      for (final c in state.crew) {
        cuts += (income * c.cut / 100).round();
      }
      income -= cuts;
      state.stats.money += income;
      if (income > 0) {
        logs.add('The books brought \$$income after cuts.');
      } else {
        logs.add('The books were quiet. No take this year.');
      }
      // living costs
      final live = 320 + state.age * 2 + (state.businesses.length * 80);
      state.stats.money -= live;
      logs.add('Rent and bread took \$$live.');
    } else {
      logs.add('Inside. The year still counted.');
    }

    if (state.stats.money < 0) {
      final stacked = state.flags.contains('in_debt');
      state.debt += -state.stats.money;
      state.stats.money = 0;
      state.flags.add('in_debt');
      logs.add('The year ended in debt.');
      _queueOnce('debt_collector', yearsAhead: 1);
      if (stacked) {
        logs.add('Debt stacked. The year grew teeth.');
        final r = hottestRival();
        if (r != null) r.hostility = min(100, r.hostility + 8);
      }
    }

    // Heat / stress / health drift
    if (state.inPrison) {
      // Prison tick already cooled heat.
    } else {
      final lastRisk = state.flags.contains('risk_job_${state.year - 1}');
      var residue = 0;
      for (var y = state.year - 1; y >= state.year - 3; y--) {
        if (state.flags.contains('risk_job_$y')) residue += 2;
      }
      if (lastRisk) {
        state.stats.heat = min(100, state.stats.heat + residue);
        if (residue > 0) logs.add('Last year\'s risk left residue in the rain.');
      } else {
        state.stats.heat = max(0, state.stats.heat - 1 + residue);
      }
    }
    if (player.traits.contains('Paranoid')) state.stats.stress = min(100, state.stats.stress + 2);
    if (player.traits.contains('Compassionate')) state.stats.loyalty = min(100, state.stats.loyalty + 1);
    if (state.stats.stress > 70) {
      state.stats.health = max(0, state.stats.health - 4);
      logs.add('Stress chewed the year.');
    } else {
      state.stats.stress = max(0, state.stats.stress - 3);
    }
    if (state.age > 50) state.stats.health = max(0, state.stats.health - ((state.age - 50) ~/ 8));

    if (!state.inPrison && state.stats.heat >= 80) {
      _queueOnce('detective_card', yearsAhead: 1);
      logs.add('Heat loud enough for a detective card.');
    } else if (!state.inPrison && state.stats.heat >= 60) {
      _queueOnce('patrol_stop', yearsAhead: 1);
    }

    _ageFamily(logs);
    _tickCrew(logs);
    _tickHeldStreets(logs);
    _tickRivals(logs);
    tickWarSeason(logs);
    _maybeRandomBirth(logs);
    _peaks();
    _recomputeAssets();
    if (state.age == 52) {
      player.portraitKey = '';
      _stampPortrait(player);
    }
    _checkAchievements();

    // Death by age / health
    if (player.isAlive && state.stats.health <= 0) {
      _killPlayer('The body gave out.');
      note('Health reached the end of its rope.');
    } else if (player.isAlive && state.age >= 62) {
      final chance = (state.age - 62) * 1.6 + (100 - state.stats.health) * 0.15;
      if (rng.chance(chance)) {
        _killPlayer('Died in the quiet of old weather.');
        note('Age closed the ledger.');
      }
    }

    if (state.age >= 70) unlock('old_boss');
    if (state.stats.money + state.stats.assets >= 50000 && state.stats.heat < 15) {
      unlock('low_heat_rich');
    }
    if (state.flags.contains('legitimate_turn')) unlock('legit');
    if (state.flags.contains('glassridge_done')) unlock('heist');
    if (state.flags.contains('did_first_score')) unlock('first_score');

    _checkGameOver(logs);
    _checkEndings();
    _setYearBeats();

    state.lastYearLog = logs;
    state.yearHeadline = _yearHeadline(logs);
    state.lastSummary = state.yearHeadline;
    _stampPressure();
    if (!state.awaitingHeir && state.phase != 'ending') {
      state.phase = 'playing';
    }
  }

  String _yearHeadline(List<String> logs) {
    if (state.inPrison) {
      return '${state.year}. Inside. The corridor keeps its own calendar.';
    }
    if (state.flags.contains('docks_fire_done') && logs.any((l) => l.contains('Fire') || l.contains('fire'))) {
      return '${state.year}. Pier 9 burned the color of old gold.';
    }
    if (state.flags.contains('chapter_prologue')) {
      return '${state.year}. Prologue weather. Age ${state.age}. The rain is still deciding.';
    }
    if (state.stats.heat >= 60) {
      return '${state.year}. Heat like a held breath. Vale is somewhere in it.';
    }
    if (state.stats.money >= 25000 && state.stats.heat < 20) {
      return '${state.year}. Quiet money. The rain sounds expensive.';
    }
    if (state.people.values.any((p) => p.relation == 'child' && p.isAlive)) {
      return '${state.year}. The name has a future. Age ${state.age}.';
    }
    if (logs.isNotEmpty) {
      return '${state.year}. ${logs.first}';
    }
    return '${state.year}. Another year in Ravenport. The rain kept its appointment.';
  }

  void _ageFamily(List<String> logs) {
    for (final p in state.people.values.where((p) => p.isAlive && p.id != player.id)) {
      final age = p.ageIn(state.year);
      if (p.relation == 'child') {
        if (age == 12 && p.traits.isEmpty) {
          final pool = [...player.traits, rng.pick(WorldContent.traits)];
          if (_satRecently(p.id, 3) && player.traits.isNotEmpty) {
            p.traits.add(player.traits.first);
            logs.add('${p.firstName} took after you — ${p.traits.first.toLowerCase()} — at twelve.');
          } else {
            p.traits.add(rng.pick(pool));
            logs.add('${p.firstName} showed a ${p.traits.first.toLowerCase()} streak at twelve.');
          }
        }
        if (age == 16 && p.traits.length < 2) {
          var extra = _satRecently(p.id, 4) && player.traits.length > 1
              ? player.traits[1]
              : rng.pick(WorldContent.traits);
          while (p.traits.contains(extra)) {
            extra = rng.pick(WorldContent.traits);
          }
          p.traits.add(extra);
          logs.add('${p.firstName} grew into a ${extra.toLowerCase()} sixteenth year.');
        }
        if (age == 18) {
          _adultPath(p, logs);
        }
      }
      // NPC aging deaths
      if (age > 74 && rng.chance((age - 74) * 2)) {
        p.isAlive = false;
        p.deathYear = state.year;
        p.deathCause = 'Age';
        p.lifePath = 'deceased';
        logs.add('${p.name} died of ordinary years.');
        if (p.id == player.spouseId) {
          player.spouseId = null;
          state.flags.remove('married');
          state.flags.add('widow_year');
        }
      }
    }
  }

  void _adultPath(Person p, List<String> logs) {
    p.personalStats = _statsForHeir(p);
    final sit = _satRecently(p.id, 8) ? 14 : 0;
    final locked = _sitCount(p.id, 5) >= 3 || state.flags.contains('lean_family_${p.id}');
    var loyal = p.loyaltyToFamily + (player.traits.contains('Loyal') ? 10 : 0) + sit + (p.bond ~/ 8);
    if (locked) loyal += 28;
    var legalPull = p.traits.contains('Compassionate') || p.traits.contains('Patient') ? 20 : 0;
    var rivalPull = p.traits.contains('Greedy') || p.traits.contains('Ambitious') ? 12 : 0;
    bool wished(String kind) {
      if (state.flags.contains('kid_wish_${p.id}_$kind')) return true;
      final personal = state.flags.any((f) => f.startsWith('kid_wish_${p.id}_'));
      if (personal) return false;
      return state.flags.contains('kid_wish_$kind');
    }

    if (wished('legal')) legalPull += 40;
    if (wished('family')) loyal += 22;
    if (wished('warn')) {
      legalPull += 12;
      rivalPull = max(0, rivalPull - 8);
    }
    if (wished('legal') || wished('family') || wished('warn')) {
      state.flags.add('kid_wish_applied');
    }
    final roll = rng.nextInt(100);
    if (wished('legal') && loyal < 70 && !locked) {
      p.lifePath = 'legal';
      state.flags.add('kid_legal');
      logs.add('${p.firstName} came of age on the daylight path you named.');
      state.pending.add(PendingEvent(eventId: 'family_fracture_seed', triggerYear: state.year));
      return;
    }
    if (wished('family') && loyal >= 40) {
      p.lifePath = 'family';
      logs.add('${p.firstName} came of age hungry for the family table you offered.');
      state.flags.add('has_heir_child');
      return;
    }
    if ((p.traits.contains('Reckless') && roll > 80) || loyal >= 72) {
      p.lifePath = 'family';
      logs.add('${p.firstName} came of age hungry for the family table.');
      state.flags.add('has_heir_child');
    } else if (roll + legalPull > 70 && loyal < 55) {
      p.lifePath = 'legal';
      state.flags.add('kid_legal');
      logs.add('${p.firstName} came of age and chose daylight work.');
      state.pending.add(PendingEvent(eventId: 'family_fracture_seed', triggerYear: state.year));
    } else if (roll < 12 + rivalPull && loyal < 45) {
      p.lifePath = 'rival';
      p.rivalFamilyId = rng.pick(state.rivals).id;
      state.flags.add('kid_rival');
      state.flags.add('family_rift');
      logs.add('${p.firstName} came of age under another crest.');
    } else {
      p.lifePath = 'family';
      state.flags.add('has_heir_child');
      logs.add('${p.firstName} stayed inside the name.');
    }
  }

  void _tickCrew(List<String> logs) {
    state.crew.removeWhere((c) {
      final p = state.people[c.personId];
      var drift = player.traits.contains('Loyal') ? 2 : -1;
      if (player.traits.contains('Greedy')) drift -= 2;
      c.loyalty = (c.loyalty + drift - (state.stats.stress > 60 ? 2 : 0)).clamp(0, 100);
      if (c.assignedBizId == null && c.loyalty < 50 && rng.chance(12)) {
        state.flags.add('sold_story');
        state.stats.heat = min(100, state.stats.heat + 6);
        state.stats.money = max(0, state.stats.money - 400);
        logs.add('${p?.name ?? 'A hand'} sold a story. An idle name still costs.');
      }
      if (c.loyalty < 28 && rng.chance(18 + (player.traits.contains('Paranoid') ? -8 : 0))) {
        if (p != null) {
          p.lifePath = 'rival';
          logs.add('${p.name} sold a story to another table.');
        }
        state.flags.add('betrayed_once');
        state.stats.heat += 5;
        state.stats.money = max(0, state.stats.money - 600);
        return true;
      }
      return false;
    });
    if (state.crew.isEmpty) state.flags.remove('has_crew');
    if (state.crew.length >= 3) state.flags.add('loyal_crew');
  }

  void bumpBond(String id, int d) {
    final p = state.people[id];
    if (p == null) return;
    p.bond = (p.bond + d).clamp(-100, 100);
  }

  void _reactNpcs(OutcomeDef o) {
    final f = o.addFlags.toSet();
    if (f.contains('mentor_crowe') || f.contains('first_loyalty') || f.contains('crowe_secret')) {
      bumpBond('p_mentor', 10);
    }
    if (f.contains('will_burn_crowe') || f.contains('crowe_cold')) bumpBond('p_mentor', -18);
    if (f.contains('vale_file')) bumpBond('p_foil', 6);
    if (f.contains('lied_to_vale')) bumpBond('p_foil', -8);
    if (f.contains('vale_respect')) bumpBond('p_foil', 12);
    if (f.contains('cass_notice')) bumpBond('p_cass', 8);
    if (f.contains('courted')) {
      bumpBond('p_mira', 8);
      bumpBond('p_ben', 6);
    }
    if (f.contains('prologue_done')) {
      bumpBond('p_mira', 4);
      bumpBond('p_ben', 3);
    }
  }

  void _stampPressure() {
    state.flags.removeWhere((f) => f.startsWith('pressure_now_'));
    final id = pressureId();
    if (id != null) state.flags.add('pressure_now_$id');
  }

  void _clearQuietStreak() {
    state.flags.removeWhere((f) => f.startsWith('quiet_streak_'));
  }

  void _quietCityBite(List<String> logs) {
    if (state.inPrison || state.flags.contains('chapter_prologue')) return;
    if (state.year <= WorldContent.startYear + 2) return;
    if (state.flags.contains('street_year_${state.year}') || state.flags.contains('risk_job_${state.year}')) {
      _clearQuietStreak();
      return;
    }
    if (!state.flags.contains('quiet_job_${state.year}') && !state.activityUsed) return;

    var streak = quietStreak();
    _clearQuietStreak();
    streak += 1;
    state.flags.add('quiet_streak_$streak');

    final hot = hottestRival();
    if (hot != null) {
      hot.hostility = min(100, hot.hostility + 6 + (streak >= 3 ? 8 : 0));
    }

    final hid = state.flags.contains('hid_year_${state.year}');
    final how = hid ? 'while you laid low' : 'while you clocked in';

    final open = state.territories.where((t) => t.controller == null).toList();
    if (open.isNotEmpty && hot != null) {
      final t = rng.pick(open);
      t.controller = hot.id;
      t.influence = 40;
      if (!hot.territories.contains(t.id)) hot.territories.add(t.id);
      hot.power = min(100, hot.power + 3);
      logs.add('${hot.name} ${houseTakeVerb(hot)} ${t.name} $how. The city did not wait.');
    } else if (hot != null) {
      final held = state.territories.where((t) => t.controller == 'player').toList();
      if (held.isNotEmpty) {
        final t = rng.pick(held);
        t.influence = max(0, t.influence - 18);
        logs.add('${hot.name} pressed ${t.name} $how.');
        if (t.influence <= 0) {
          t.controller = hot.id;
          t.influence = 35;
          if (!hot.territories.contains(t.id)) hot.territories.add(t.id);
          logs.add('${t.name} slipped. Hiding does not hold a street.');
        }
      } else {
        logs.add('No street, no fight. ${hot.name} ${houseWeather(hot)} $how.');
      }
    }

    final sepi = state.businesses.where((b) {
      return !state.crew.any((c) => c.assignedBizId == b.id && !c.imprisoned);
    }).toList();
    if (sepi.isNotEmpty && hot != null && rng.chance(25)) {
      final b = rng.pick(sepi);
      b.quality = max(0, b.quality - 20);
      if (b.quality < 15) {
        for (final c in state.crew) {
          if (c.assignedBizId == b.id) c.assignedBizId = null;
        }
        state.businesses.remove(b);
        logs.add('${hot.name} razed ${b.name} $how. An empty front does not keep.');
      } else {
        logs.add('${hot.name} raided ${b.name} $how. Quality bled.');
      }
    }

    if (streak == 2 && _emptyCityBoard) {
      _queueOnce('forgotten_weather', yearsAhead: 1);
    }
    if (streak == 3 && _emptyCityBoard) {
      _queueOnce('empty_name', yearsAhead: 1);
    }

    if (streak >= 3 && hot != null) {
      logs.add('Three quiet years. The houses stopped asking.');
      _queueOnce(_rivalEvent(hot.id), yearsAhead: 1);
    }
  }

  void _resolveIgnoredPressure(List<String> logs) {
    String? id;
    for (final f in state.flags) {
      if (f.startsWith('pressure_now_')) {
        id = f.substring('pressure_now_'.length);
        break;
      }
    }
    state.flags.removeWhere((f) => f.startsWith('pressure_now_'));
    if (id == null || state.inPrison) return;
    if (id.startsWith('family_') || id == 'family') {
      final pid = id.startsWith('family_') ? id.substring('family_'.length) : null;
      if (pid != null && state.flags.contains('sat_who_${state.year}_$pid')) return;
      Person? thin;
      final named = pid == null ? null : state.people[pid];
      if (named != null && named.isAlive && named.bond < 28) {
        thin = named;
      } else {
        final rest = state.people.values
            .where((p) => p.isAlive && p.id != player.id && _isFamily(p) && p.bond < 28)
            .toList();
        if (rest.isNotEmpty) thin = rest.first;
      }
      if (thin != null) {
        thin.bond = max(0, thin.bond - 6);
        thin.loyaltyToFamily = max(0, thin.loyaltyToFamily - 8);
        logs.add('${thin.firstName} drifted while you let the year pass.');
      }
      return;
    }
    switch (id) {
      case 'crew':
        if (state.crew.isEmpty) {
          final r = hottestRival();
          if (r != null) r.hostility = min(100, r.hostility + 8);
          state.stats.money = max(0, state.stats.money - 90);
          logs.add('No hands on the book. A house invoiced the empty year.');
          _queueOnce('patrol_stop', yearsAhead: 1);
        }
      case 'heat':
        if (state.stats.heat >= 55) {
          logs.add('You left the heat on. Vale found the year.');
          _queueOnce('detective_card', yearsAhead: 1);
        }
      case 'hold':
        if (state.businesses.isEmpty && !state.territories.any((t) => t.controller == 'player')) {
          state.stats.money = max(0, state.stats.money - 120);
          final r = hottestRival();
          if (r != null) r.hostility = min(100, r.hostility + 6);
          logs.add('No front, no street. The year billed you for being small.');
        }
      case 'turf_heat':
        if (state.territories.any((t) => t.controller == 'player' && t.heat >= 16)) {
          logs.add('A street you ignored kept cooking.');
        }
    }
  }

  void _tickHeldStreets(List<String> logs) {
    if (state.inPrison) return;
    final guarded = _hasRole(['enforcer', 'muscle']);
    for (final t in state.territories.where((t) => t.controller == 'player')) {
      if (!guarded) {
        t.heat = min(100, t.heat + 2);
      } else {
        t.heat = max(0, t.heat - 1);
      }
      if (t.heat >= 16) {
        t.influence = max(0, t.influence - 8);
        logs.add('${t.name} ran hot. Influence thinned.');
        if (t.influence <= 0) {
          final r = hottestRival();
          if (r != null && rng.chance(40)) {
            t.controller = r.id;
            t.influence = 35;
            if (!r.territories.contains(t.id)) r.territories.add(t.id);
            r.hostility = min(100, r.hostility + 4);
            logs.add('${t.name} slipped to ${r.name}. Cool it next time.');
          }
        }
      }
    }
  }

  void _tickRivals(List<String> logs) {
    for (final r in state.rivals) {
      r.power = (r.power + rng.nextInt(4) - (r.hostility > 70 ? 1 : 0)).clamp(5, 100);
      r.wealth += r.power * (20 + rng.nextInt(30));
      r.heat = (r.heat + rng.nextInt(5) - 2).clamp(0, 100);
      if (rng.chance(12)) {
        logs.add(switch (r.id) {
          'calderas' => 'The Calderas sent a gift that felt like a measurement.',
          'rooke' => 'Rooke paint showed up on a wall you thought was yours.',
          'vex' => 'House Vex forwarded a merger you did not ask for.',
          'marrow' => 'The Kin kept Harbor Lights open an hour later than the law.',
          _ => '${r.name} moved a piece while you slept.',
        });
        r.hostility = min(100, r.hostility + 1);
      }
      // Independent growth: try to take an uncontrolled district.
      if (rng.chance(18 + (r.personality == 'aggressive' ? 10 : 0))) {
        final open = state.territories.where((t) => t.controller == null).toList();
        if (open.isNotEmpty) {
          final t = rng.pick(open);
          t.controller = r.id;
          t.influence = 40;
          r.territories.add(t.id);
          r.power += 3;
          logs.add('${r.name} took ${t.name} while you were busy.');
        } else if (rng.chance(25)) {
          final playerT = state.territories.where((t) => t.controller == 'player').toList();
          if (playerT.isNotEmpty) {
            final t = rng.pick(playerT);
            t.influence = max(0, t.influence - 12);
            r.hostility = min(100, r.hostility + 4);
            logs.add('${r.name} tested ${t.name}.');
            if (t.influence <= 0 && rng.chance(40)) {
              t.controller = r.id;
              r.territories.add(t.id);
              logs.add('${t.name} slipped to ${r.name}.');
            }
          }
        }
      }
      if (r.hostility > 55 && rng.chance(12) && !state.inPrison) {
        state.pending.add(PendingEvent(eventId: _rivalEvent(r.id), triggerYear: state.year + 1));
      }
      if (r.power < 10) unlock('rival_broke');
    }
  }

  String _rivalEvent(String id) {
    const map = {
      'calderas': 'caldera_invitation',
      'rooke': 'rooke_cardroom',
      'vex': 'vex_boardroom',
      'marrow': 'marrow_afterhours',
    };
    return map[id] ?? 'caldera_invitation';
  }

  void _maybeRandomBirth(List<String> logs) {
    final s = _spouse();
    if (s == null || !s.isAlive || state.inPrison) return;
    if (state.age < 20 || state.age > 46) return;
    if (state.childrenBorn >= 4) return;
    final chance = player.traits.contains('Loyal') ? 16 : 10;
    if (rng.chance(chance)) {
      _birthChild();
      logs.add('The family added a name.');
    }
  }

  void unlock(String id) {
    if (state.achievements.contains(id)) return;
    final def = WorldContent.achievements().cast<AchievementDef?>().firstWhere((a) => a!.id == id, orElse: () => null);
    if (def != null) {
      state.achievements.add(id);
      state.notableThisLife.add(id);
      lastUnlocks.add(def.title);
    }
  }

  void _checkAchievements() {
    if (state.flags.contains('did_first_score')) unlock('first_score');
    if (state.crew.length >= 3) unlock('crew_of_three');
    if (state.flags.contains('married')) unlock('married');
    if (state.people.values.any((p) => p.relation == 'child')) unlock('parent');
    if (state.businesses.length >= 3) unlock('tycoon');
    if (state.territories.any((t) => t.id == 'docks' && t.controller == 'player')) {
      unlock('docks_king');
    }
  }

  void _checkGameOver(List<String> logs) {
    if (state.phase == 'ending' || state.awaitingHeir) return;
    if (state.flags.contains('chapter_prologue') || state.inPrison) return;
    if (!_emptyCityBoard) return;
    final neglected = quietStreak() >= 4 || yieldCount() >= 5;
    if (!neglected) return;
    logs.add('The city closed the file. Nobody sits the chair.');
    _beginGameOver('forgotten');
  }

  void _checkEndings() {
    if (state.phase == 'ending') return;
    if (state.generation >= 3 &&
        state.businesses.length >= 3 &&
        state.territories.where((t) => t.controller == 'player').length >= 3) {
      // not auto-end — available as a recorded ending if they retire
      state.flags.add('empire_ready');
    }
  }

  void _applyTraitStatNudge() {
    if (player.traits.contains('Violent')) state.stats.nerve = min(100, state.stats.nerve + 4);
    if (player.traits.contains('Greedy')) state.stats.money += 120;
    if (player.traits.contains('Ambitious')) state.stats.reputation += 4;
  }

  String? endingTitle() {
    if (state.endingId == null) return null;
    return WorldContent.endings[state.endingId]?.first;
  }
}

extension GameLog on GameState {
  void log(String text, {String category = 'life'}) {
    if (text.trim().isEmpty) return;
    timeline.add(
      TimelineEntry(
        year: year,
        age: people[playerId]?.ageIn(year) ?? 0,
        leader: people[playerId]?.name ?? dynastyName,
        text: text,
        category: category,
      ),
    );
    if (timeline.length > 400) {
      timeline.removeRange(0, timeline.length - 400);
    }
  }
}
