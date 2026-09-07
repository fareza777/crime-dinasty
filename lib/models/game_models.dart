import 'dart:math';

class Stats {
  int health;
  int intelligence;
  int charisma;
  int nerve;
  int loyalty;
  int reputation;
  int heat;
  int stress;
  int money;
  int assets;

  Stats({
    this.health = 72,
    this.intelligence = 42,
    this.charisma = 42,
    this.nerve = 40,
    this.loyalty = 48,
    this.reputation = 8,
    this.heat = 4,
    this.stress = 12,
    this.money = 420,
    this.assets = 0,
  });

  factory Stats.fromJson(Map<String, dynamic> j) => Stats(
        health: (j['health'] as num?)?.toInt() ?? 72,
        intelligence: (j['intelligence'] as num?)?.toInt() ?? 42,
        charisma: (j['charisma'] as num?)?.toInt() ?? 42,
        nerve: (j['nerve'] as num?)?.toInt() ?? 40,
        loyalty: (j['loyalty'] as num?)?.toInt() ?? 48,
        reputation: (j['reputation'] as num?)?.toInt() ?? 8,
        heat: (j['heat'] as num?)?.toInt() ?? 4,
        stress: (j['stress'] as num?)?.toInt() ?? 12,
        money: (j['money'] as num?)?.toInt() ?? 0,
        assets: (j['assets'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'health': health,
        'intelligence': intelligence,
        'charisma': charisma,
        'nerve': nerve,
        'loyalty': loyalty,
        'reputation': reputation,
        'heat': heat,
        'stress': stress,
        'money': money,
        'assets': assets,
      };

  int get(String key) {
    switch (key) {
      case 'health':
        return health;
      case 'intelligence':
        return intelligence;
      case 'charisma':
        return charisma;
      case 'nerve':
        return nerve;
      case 'loyalty':
        return loyalty;
      case 'reputation':
        return reputation;
      case 'heat':
        return heat;
      case 'stress':
        return stress;
      case 'money':
        return money;
      case 'assets':
        return assets;
      default:
        return 0;
    }
  }

  void add(String key, int delta) {
    if (delta == 0) return;
    switch (key) {
      case 'health':
        health = _clampStat(health + delta);
        break;
      case 'intelligence':
        intelligence = _clampStat(intelligence + delta);
        break;
      case 'charisma':
        charisma = _clampStat(charisma + delta);
        break;
      case 'nerve':
        nerve = _clampStat(nerve + delta);
        break;
      case 'loyalty':
        loyalty = _clampStat(loyalty + delta);
        break;
      case 'reputation':
        reputation = _clampStat(reputation + delta);
        break;
      case 'heat':
        heat = _clampStat(heat + delta);
        break;
      case 'stress':
        stress = _clampStat(stress + delta);
        break;
      case 'money':
        money += delta;
        break;
      case 'assets':
        assets = max(0, assets + delta);
        break;
    }
  }

  void applyMap(Map<String, dynamic>? m) {
    if (m == null) return;
    for (final e in m.entries) {
      add(e.key, (e.value as num?)?.toInt() ?? 0);
    }
  }

  static int _clampStat(int v) => v.clamp(0, 100);

  Stats copy() => Stats.fromJson(toJson());
}

class Person {
  String id;
  String firstName;
  String lastName;
  String gender; // man, woman, nonbinary
  int birthYear;
  int? deathYear;
  String? deathCause;
  List<String> traits;
  String relation; // self, spouse, child, sibling, parent, cousin, inlaw, crew
  String? parentId;
  String? otherParentId;
  String? spouseId;
  int loyaltyToFamily;
  int ambition;
  String lifePath; // family, legal, rival, unknown, imprisoned, deceased
  String? rivalFamilyId;
  bool isAlive;
  int portraitSeed;
  String portraitKey;
  Stats? personalStats;
  int bond; // with current player, -100..100

  Person({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.birthYear,
    this.deathYear,
    this.deathCause,
    List<String>? traits,
    this.relation = 'child',
    this.parentId,
    this.otherParentId,
    this.spouseId,
    this.loyaltyToFamily = 55,
    this.ambition = 40,
    this.lifePath = 'unknown',
    this.rivalFamilyId,
    this.isAlive = true,
    int? portraitSeed,
    this.portraitKey = '',
    this.personalStats,
    this.bond = 40,
  })  : traits = traits ?? [],
        portraitSeed = portraitSeed ?? id.hashCode;

  String get name => '$firstName $lastName';

  int ageIn(int year) => year - birthYear;

  bool adultIn(int year) => ageIn(year) >= 18 && isAlive;

  factory Person.fromJson(Map<String, dynamic> j) => Person(
        id: j['id'] as String,
        firstName: j['firstName'] as String? ?? 'Unknown',
        lastName: j['lastName'] as String? ?? '',
        gender: j['gender'] as String? ?? 'nonbinary',
        birthYear: (j['birthYear'] as num?)?.toInt() ?? 1980,
        deathYear: (j['deathYear'] as num?)?.toInt(),
        deathCause: j['deathCause'] as String?,
        traits: (j['traits'] as List?)?.map((e) => '$e').toList() ?? [],
        relation: j['relation'] as String? ?? 'child',
        parentId: j['parentId'] as String?,
        otherParentId: j['otherParentId'] as String?,
        spouseId: j['spouseId'] as String?,
        loyaltyToFamily: (j['loyaltyToFamily'] as num?)?.toInt() ?? 55,
        ambition: (j['ambition'] as num?)?.toInt() ?? 40,
        lifePath: j['lifePath'] as String? ?? 'unknown',
        rivalFamilyId: j['rivalFamilyId'] as String?,
        isAlive: j['isAlive'] as bool? ?? true,
        portraitSeed: (j['portraitSeed'] as num?)?.toInt(),
        portraitKey: j['portraitKey'] as String? ?? '',
        personalStats: j['personalStats'] is Map
            ? Stats.fromJson(Map<String, dynamic>.from(j['personalStats'] as Map))
            : null,
        bond: (j['bond'] as num?)?.toInt() ?? 40,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender,
        'birthYear': birthYear,
        'deathYear': deathYear,
        'deathCause': deathCause,
        'traits': traits,
        'relation': relation,
        'parentId': parentId,
        'otherParentId': otherParentId,
        'spouseId': spouseId,
        'loyaltyToFamily': loyaltyToFamily,
        'ambition': ambition,
        'lifePath': lifePath,
        'rivalFamilyId': rivalFamilyId,
        'isAlive': isAlive,
        'portraitSeed': portraitSeed,
        'portraitKey': portraitKey,
        'personalStats': personalStats?.toJson(),
        'bond': bond,
      };
}

class CrewMember {
  String personId;
  String role;
  int skill;
  int loyalty;
  int cut;
  bool imprisoned;
  String? assignedBizId;

  CrewMember({
    required this.personId,
    required this.role,
    this.skill = 40,
    this.loyalty = 55,
    this.cut = 10,
    this.imprisoned = false,
    this.assignedBizId,
  });

  factory CrewMember.fromJson(Map<String, dynamic> j) => CrewMember(
        personId: j['personId'] as String,
        role: j['role'] as String? ?? 'hand',
        skill: (j['skill'] as num?)?.toInt() ?? 40,
        loyalty: (j['loyalty'] as num?)?.toInt() ?? 55,
        cut: (j['cut'] as num?)?.toInt() ?? 10,
        imprisoned: j['imprisoned'] as bool? ?? false,
        assignedBizId: j['assignedBizId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'personId': personId,
        'role': role,
        'skill': skill,
        'loyalty': loyalty,
        'cut': cut,
        'imprisoned': imprisoned,
        'assignedBizId': assignedBizId,
      };
}

class RivalFamily {
  String id;
  String name;
  String bossName;
  int power;
  int wealth;
  int heat;
  int hostility;
  List<String> territories;
  int generation;
  String personality;

  RivalFamily({
    required this.id,
    required this.name,
    required this.bossName,
    this.power = 30,
    this.wealth = 8000,
    this.heat = 10,
    this.hostility = 15,
    List<String>? territories,
    this.generation = 2,
    this.personality = 'calculating',
  }) : territories = territories ?? [];

  factory RivalFamily.fromJson(Map<String, dynamic> j) => RivalFamily(
        id: j['id'] as String,
        name: j['name'] as String,
        bossName: j['bossName'] as String? ?? 'Unknown',
        power: (j['power'] as num?)?.toInt() ?? 30,
        wealth: (j['wealth'] as num?)?.toInt() ?? 0,
        heat: (j['heat'] as num?)?.toInt() ?? 0,
        hostility: (j['hostility'] as num?)?.toInt() ?? 0,
        territories: (j['territories'] as List?)?.map((e) => '$e').toList() ?? [],
        generation: (j['generation'] as num?)?.toInt() ?? 1,
        personality: j['personality'] as String? ?? 'calculating',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bossName': bossName,
        'power': power,
        'wealth': wealth,
        'heat': heat,
        'hostility': hostility,
        'territories': territories,
        'generation': generation,
        'personality': personality,
      };
}

class Business {
  String id;
  String name;
  String type;
  String districtId;
  int value;
  int yearlyIncome;
  int cover;
  bool legalFront;
  int quality;

  Business({
    required this.id,
    required this.name,
    required this.type,
    required this.districtId,
    this.value = 8000,
    this.yearlyIncome = 1200,
    this.cover = 4,
    this.legalFront = true,
    this.quality = 40,
  });

  factory Business.fromJson(Map<String, dynamic> j) => Business(
        id: j['id'] as String,
        name: j['name'] as String,
        type: j['type'] as String,
        districtId: j['districtId'] as String? ?? 'midtown',
        value: (j['value'] as num?)?.toInt() ?? 0,
        yearlyIncome: (j['yearlyIncome'] as num?)?.toInt() ?? 0,
        cover: (j['cover'] as num?)?.toInt() ?? 0,
        legalFront: j['legalFront'] as bool? ?? true,
        quality: (j['quality'] as num?)?.toInt() ?? 40,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'districtId': districtId,
        'value': value,
        'yearlyIncome': yearlyIncome,
        'cover': cover,
        'legalFront': legalFront,
        'quality': quality,
      };
}

class Territory {
  String id;
  String name;
  String blurb;
  String? controller;
  int income;
  int heat;
  int influence;

  Territory({
    required this.id,
    required this.name,
    required this.blurb,
    this.controller,
    this.income = 400,
    this.heat = 8,
    this.influence = 0,
  });

  factory Territory.fromJson(Map<String, dynamic> j) => Territory(
        id: j['id'] as String,
        name: j['name'] as String,
        blurb: j['blurb'] as String? ?? '',
        controller: j['controller'] as String?,
        income: (j['income'] as num?)?.toInt() ?? 0,
        heat: (j['heat'] as num?)?.toInt() ?? 0,
        influence: (j['influence'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'blurb': blurb,
        'controller': controller,
        'income': income,
        'heat': heat,
        'influence': influence,
      };
}

class TimelineEntry {
  int year;
  int age;
  String leader;
  String text;
  String category;

  TimelineEntry({
    required this.year,
    required this.age,
    required this.leader,
    required this.text,
    this.category = 'life',
  });

  factory TimelineEntry.fromJson(Map<String, dynamic> j) => TimelineEntry(
        year: (j['year'] as num).toInt(),
        age: (j['age'] as num?)?.toInt() ?? 0,
        leader: j['leader'] as String? ?? '',
        text: j['text'] as String? ?? '',
        category: j['category'] as String? ?? 'life',
      );

  Map<String, dynamic> toJson() => {
        'year': year,
        'age': age,
        'leader': leader,
        'text': text,
        'category': category,
      };
}

class LegacyRecord {
  String personId;
  String name;
  int startYear;
  int endYear;
  int startAge;
  int endAge;
  String fate;
  String epitaph;
  int peakWealth;
  int peakReputation;
  int generation;
  List<String> notable;

  LegacyRecord({
    required this.personId,
    required this.name,
    required this.startYear,
    required this.endYear,
    required this.startAge,
    required this.endAge,
    required this.fate,
    required this.epitaph,
    this.peakWealth = 0,
    this.peakReputation = 0,
    this.generation = 1,
    List<String>? notable,
  }) : notable = notable ?? [];

  factory LegacyRecord.fromJson(Map<String, dynamic> j) => LegacyRecord(
        personId: j['personId'] as String,
        name: j['name'] as String,
        startYear: (j['startYear'] as num).toInt(),
        endYear: (j['endYear'] as num).toInt(),
        startAge: (j['startAge'] as num?)?.toInt() ?? 0,
        endAge: (j['endAge'] as num?)?.toInt() ?? 0,
        fate: j['fate'] as String? ?? 'ended',
        epitaph: j['epitaph'] as String? ?? '',
        peakWealth: (j['peakWealth'] as num?)?.toInt() ?? 0,
        peakReputation: (j['peakReputation'] as num?)?.toInt() ?? 0,
        generation: (j['generation'] as num?)?.toInt() ?? 1,
        notable: (j['notable'] as List?)?.map((e) => '$e').toList() ?? [],
      );

  Map<String, dynamic> toJson() => {
        'personId': personId,
        'name': name,
        'startYear': startYear,
        'endYear': endYear,
        'startAge': startAge,
        'endAge': endAge,
        'fate': fate,
        'epitaph': epitaph,
        'peakWealth': peakWealth,
        'peakReputation': peakReputation,
        'generation': generation,
        'notable': notable,
      };
}

class PendingEvent {
  String eventId;
  int triggerYear;
  Map<String, dynamic> payload;

  PendingEvent({
    required this.eventId,
    required this.triggerYear,
    Map<String, dynamic>? payload,
  }) : payload = payload ?? {};

  factory PendingEvent.fromJson(Map<String, dynamic> j) => PendingEvent(
        eventId: j['eventId'] as String,
        triggerYear: (j['triggerYear'] as num).toInt(),
        payload: j['payload'] is Map
            ? Map<String, dynamic>.from(j['payload'] as Map)
            : {},
      );

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'triggerYear': triggerYear,
        'payload': payload,
      };
}

class GameState {
  int version;
  int year;
  int generation;
  int leaderStartYear;
  int leaderStartAge;
  String playerId;
  String dynastyName;
  String cityName;
  Stats stats;
  Map<String, Person> people;
  List<CrewMember> crew;
  List<RivalFamily> rivals;
  List<Business> businesses;
  List<Territory> territories;
  List<TimelineEntry> timeline;
  List<LegacyRecord> hall;
  List<PendingEvent> pending;
  Set<String> flags;
  Set<String> seenEvents;
  Map<String, int> cooldowns;
  List<String> achievements;
  String? currentEventId;
  String? lastEventId;
  String? lastChoiceId;
  bool lastFailed;
  bool retryUsed;
  String? snapshotJson;
  bool inPrison;
  int prisonYearsLeft;
  bool awaitingHeir;
  String? heirReason;
  String phase; // title, playing, event, summary, heir, ending
  int seed;
  int rngState;
  int eventsThisYear;
  int eventTarget;
  bool activityUsed;
  bool adsRemoved;
  int yearsSinceInterstitial;
  String? endingId;
  int lawyerQuality;
  int peakWealth;
  int peakReputation;
  int debt;
  List<String> notableThisLife;
  bool tutorialDone;
  String? lastSummary;
  List<String> lastYearLog;
  int childrenBorn;
  bool generationBreakPending;
  String yearHeadline;
  List<String> recentEventIds;

  GameState({
    this.version = 1,
    this.year = 1998,
    this.generation = 1,
    this.leaderStartYear = 1998,
    this.leaderStartAge = 18,
    required this.playerId,
    this.dynastyName = 'Hart',
    this.cityName = 'Ravenport',
    Stats? stats,
    Map<String, Person>? people,
    List<CrewMember>? crew,
    List<RivalFamily>? rivals,
    List<Business>? businesses,
    List<Territory>? territories,
    List<TimelineEntry>? timeline,
    List<LegacyRecord>? hall,
    List<PendingEvent>? pending,
    Set<String>? flags,
    Set<String>? seenEvents,
    Map<String, int>? cooldowns,
    List<String>? achievements,
    this.currentEventId,
    this.lastEventId,
    this.lastChoiceId,
    this.lastFailed = false,
    this.retryUsed = false,
    this.snapshotJson,
    this.inPrison = false,
    this.prisonYearsLeft = 0,
    this.awaitingHeir = false,
    this.heirReason,
    this.phase = 'playing',
    this.seed = 1,
    this.rngState = 1,
    this.eventsThisYear = 0,
    this.eventTarget = 1,
    this.activityUsed = false,
    this.adsRemoved = false,
    this.yearsSinceInterstitial = 99,
    this.endingId,
    this.lawyerQuality = 0,
    this.peakWealth = 0,
    this.peakReputation = 0,
    this.debt = 0,
    List<String>? notableThisLife,
    this.tutorialDone = false,
    this.lastSummary,
    List<String>? lastYearLog,
    this.childrenBorn = 0,
    this.generationBreakPending = false,
    this.yearHeadline = '',
    List<String>? recentEventIds,
  })  : stats = stats ?? Stats(),
        people = people ?? {},
        crew = crew ?? [],
        rivals = rivals ?? [],
        businesses = businesses ?? [],
        territories = territories ?? [],
        timeline = timeline ?? [],
        hall = hall ?? [],
        pending = pending ?? [],
        flags = flags ?? {},
        seenEvents = seenEvents ?? {},
        cooldowns = cooldowns ?? {},
        achievements = achievements ?? [],
        notableThisLife = notableThisLife ?? [],
        lastYearLog = lastYearLog ?? [],
        recentEventIds = recentEventIds ?? [];

  Person get player => people[playerId]!;

  int get age => player.ageIn(year);

  factory GameState.fromJson(Map<String, dynamic> j) {
    final people = <String, Person>{};
    final rawPeople = j['people'];
    if (rawPeople is Map) {
      for (final e in rawPeople.entries) {
        people['${e.key}'] = Person.fromJson(Map<String, dynamic>.from(e.value as Map));
      }
    }
    return GameState(
      version: (j['version'] as num?)?.toInt() ?? 1,
      year: (j['year'] as num?)?.toInt() ?? 1998,
      generation: (j['generation'] as num?)?.toInt() ?? 1,
      leaderStartYear: (j['leaderStartYear'] as num?)?.toInt() ?? 1998,
      leaderStartAge: (j['leaderStartAge'] as num?)?.toInt() ?? 18,
      playerId: j['playerId'] as String,
      dynastyName: j['dynastyName'] as String? ?? 'Hart',
      cityName: j['cityName'] as String? ?? 'Ravenport',
      stats: j['stats'] is Map ? Stats.fromJson(Map<String, dynamic>.from(j['stats'] as Map)) : Stats(),
      people: people,
      crew: (j['crew'] as List?)
              ?.map((e) => CrewMember.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      rivals: (j['rivals'] as List?)
              ?.map((e) => RivalFamily.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      businesses: (j['businesses'] as List?)
              ?.map((e) => Business.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      territories: (j['territories'] as List?)
              ?.map((e) => Territory.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      timeline: (j['timeline'] as List?)
              ?.map((e) => TimelineEntry.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      hall: (j['hall'] as List?)
              ?.map((e) => LegacyRecord.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      pending: (j['pending'] as List?)
              ?.map((e) => PendingEvent.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      flags: (j['flags'] as List?)?.map((e) => '$e').toSet() ?? {},
      seenEvents: (j['seenEvents'] as List?)?.map((e) => '$e').toSet() ?? {},
      cooldowns: {
        if (j['cooldowns'] is Map)
          for (final e in (j['cooldowns'] as Map).entries) '${e.key}': (e.value as num).toInt(),
      },
      achievements: (j['achievements'] as List?)?.map((e) => '$e').toList() ?? [],
      currentEventId: j['currentEventId'] as String?,
      lastEventId: j['lastEventId'] as String?,
      lastChoiceId: j['lastChoiceId'] as String?,
      lastFailed: j['lastFailed'] as bool? ?? false,
      retryUsed: j['retryUsed'] as bool? ?? false,
      snapshotJson: j['snapshotJson'] as String?,
      inPrison: j['inPrison'] as bool? ?? false,
      prisonYearsLeft: (j['prisonYearsLeft'] as num?)?.toInt() ?? 0,
      awaitingHeir: j['awaitingHeir'] as bool? ?? false,
      heirReason: j['heirReason'] as String?,
      phase: j['phase'] as String? ?? 'playing',
      seed: (j['seed'] as num?)?.toInt() ?? 1,
      rngState: (j['rngState'] as num?)?.toInt() ?? 1,
      eventsThisYear: (j['eventsThisYear'] as num?)?.toInt() ?? 0,
      eventTarget: (j['eventTarget'] as num?)?.toInt() ?? 1,
      activityUsed: j['activityUsed'] as bool? ?? false,
      adsRemoved: j['adsRemoved'] as bool? ?? false,
      yearsSinceInterstitial: (j['yearsSinceInterstitial'] as num?)?.toInt() ?? 99,
      endingId: j['endingId'] as String?,
      lawyerQuality: (j['lawyerQuality'] as num?)?.toInt() ?? 0,
      peakWealth: (j['peakWealth'] as num?)?.toInt() ?? 0,
      peakReputation: (j['peakReputation'] as num?)?.toInt() ?? 0,
      debt: (j['debt'] as num?)?.toInt() ?? 0,
      notableThisLife: (j['notableThisLife'] as List?)?.map((e) => '$e').toList() ?? [],
      tutorialDone: j['tutorialDone'] as bool? ?? false,
      lastSummary: j['lastSummary'] as String?,
      lastYearLog: (j['lastYearLog'] as List?)?.map((e) => '$e').toList() ?? [],
      childrenBorn: (j['childrenBorn'] as num?)?.toInt() ?? 0,
      generationBreakPending: j['generationBreakPending'] as bool? ?? false,
      yearHeadline: j['yearHeadline'] as String? ?? '',
      recentEventIds: (j['recentEventIds'] as List?)?.map((e) => '$e').toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'year': year,
        'generation': generation,
        'leaderStartYear': leaderStartYear,
        'leaderStartAge': leaderStartAge,
        'playerId': playerId,
        'dynastyName': dynastyName,
        'cityName': cityName,
        'stats': stats.toJson(),
        'people': {for (final e in people.entries) e.key: e.value.toJson()},
        'crew': crew.map((e) => e.toJson()).toList(),
        'rivals': rivals.map((e) => e.toJson()).toList(),
        'businesses': businesses.map((e) => e.toJson()).toList(),
        'territories': territories.map((e) => e.toJson()).toList(),
        'timeline': timeline.map((e) => e.toJson()).toList(),
        'hall': hall.map((e) => e.toJson()).toList(),
        'pending': pending.map((e) => e.toJson()).toList(),
        'flags': flags.toList(),
        'seenEvents': seenEvents.toList(),
        'cooldowns': cooldowns,
        'achievements': achievements,
        'currentEventId': currentEventId,
        'lastEventId': lastEventId,
        'lastChoiceId': lastChoiceId,
        'lastFailed': lastFailed,
        'retryUsed': retryUsed,
        'snapshotJson': snapshotJson,
        'inPrison': inPrison,
        'prisonYearsLeft': prisonYearsLeft,
        'awaitingHeir': awaitingHeir,
        'heirReason': heirReason,
        'phase': phase,
        'seed': seed,
        'rngState': rngState,
        'eventsThisYear': eventsThisYear,
        'eventTarget': eventTarget,
        'activityUsed': activityUsed,
        'adsRemoved': adsRemoved,
        'yearsSinceInterstitial': yearsSinceInterstitial,
        'endingId': endingId,
        'lawyerQuality': lawyerQuality,
        'peakWealth': peakWealth,
        'peakReputation': peakReputation,
        'debt': debt,
        'notableThisLife': notableThisLife,
        'tutorialDone': tutorialDone,
        'lastSummary': lastSummary,
        'lastYearLog': lastYearLog,
        'childrenBorn': childrenBorn,
        'generationBreakPending': generationBreakPending,
        'yearHeadline': yearHeadline,
        'recentEventIds': recentEventIds,
      };

  GameState deepCopy() => GameState.fromJson(toJson());
}
