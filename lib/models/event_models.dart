class EventDef {
  final String id;
  final String title;
  final String body;
  final String category;
  final List<String> tags;
  final int weight;
  final bool once;
  final int cooldownYears;
  final String? chain;
  final int chainStage;
  final int minAge;
  final int maxAge;
  final String art;
  final RequireDef requires;
  final List<ChoiceDef> choices;

  EventDef({
    required this.id,
    required this.title,
    required this.body,
    this.category = 'life',
    List<String>? tags,
    this.weight = 10,
    this.once = false,
    this.cooldownYears = 3,
    this.chain,
    this.chainStage = 0,
    this.minAge = 16,
    this.maxAge = 99,
    this.art = 'street',
    RequireDef? requires,
    List<ChoiceDef>? choices,
  })  : tags = tags ?? [],
        requires = requires ?? RequireDef(),
        choices = choices ?? [];

  factory EventDef.fromJson(Map<String, dynamic> j) => EventDef(
        id: j['id'] as String,
        title: j['title'] as String? ?? 'Untitled',
        body: j['body'] as String? ?? '',
        category: j['category'] as String? ?? 'life',
        tags: (j['tags'] as List?)?.map((e) => '$e').toList() ?? [],
        weight: (j['weight'] as num?)?.toInt() ?? 10,
        once: j['once'] as bool? ?? false,
        cooldownYears: (j['cooldownYears'] as num?)?.toInt() ?? 3,
        chain: j['chain'] as String?,
        chainStage: (j['chainStage'] as num?)?.toInt() ?? 0,
        minAge: (j['minAge'] as num?)?.toInt() ?? 16,
        maxAge: (j['maxAge'] as num?)?.toInt() ?? 99,
        art: j['art'] as String? ?? 'street',
        requires: j['requires'] is Map
            ? RequireDef.fromJson(Map<String, dynamic>.from(j['requires'] as Map))
            : RequireDef(),
        choices: (j['choices'] as List?)
                ?.map((e) => ChoiceDef.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
      );
}

class RequireDef {
  final List<String> allFlags;
  final List<String> anyFlags;
  final List<String> noneFlags;
  final Map<String, int> minStats;
  final Map<String, int> maxStats;
  final int minMoney;
  final int minCrew;
  final bool? hasSpouse;
  final bool? hasChildren;
  final bool? inPrison;
  final int minChildrenAdult;
  final bool? hasBusiness;
  final bool? hasTerritory;
  final int minHeat;
  final int minReputation;
  final List<String> traitsAny;
  final List<String> traitsNone;
  final int minGeneration;
  final int minAge;
  final int maxAge;

  RequireDef({
    List<String>? allFlags,
    List<String>? anyFlags,
    List<String>? noneFlags,
    Map<String, int>? minStats,
    Map<String, int>? maxStats,
    this.minMoney = 0,
    this.minCrew = 0,
    this.hasSpouse,
    this.hasChildren,
    this.inPrison,
    this.minChildrenAdult = 0,
    this.hasBusiness,
    this.hasTerritory,
    this.minHeat = 0,
    this.minReputation = 0,
    List<String>? traitsAny,
    List<String>? traitsNone,
    this.minGeneration = 1,
    this.minAge = 0,
    this.maxAge = 200,
  })  : allFlags = allFlags ?? [],
        anyFlags = anyFlags ?? [],
        noneFlags = noneFlags ?? [],
        minStats = minStats ?? {},
        maxStats = maxStats ?? {},
        traitsAny = traitsAny ?? [],
        traitsNone = traitsNone ?? [];

  factory RequireDef.fromJson(Map<String, dynamic> j) => RequireDef(
        allFlags: (j['allFlags'] as List?)?.map((e) => '$e').toList() ?? [],
        anyFlags: (j['anyFlags'] as List?)?.map((e) => '$e').toList() ?? [],
        noneFlags: (j['noneFlags'] as List?)?.map((e) => '$e').toList() ?? [],
        minStats: _intMap(j['minStats']),
        maxStats: _intMap(j['maxStats']),
        minMoney: (j['minMoney'] as num?)?.toInt() ?? 0,
        minCrew: (j['minCrew'] as num?)?.toInt() ?? 0,
        hasSpouse: j['hasSpouse'] as bool?,
        hasChildren: j['hasChildren'] as bool?,
        inPrison: j['inPrison'] as bool?,
        minChildrenAdult: (j['minChildrenAdult'] as num?)?.toInt() ?? 0,
        hasBusiness: j['hasBusiness'] as bool?,
        hasTerritory: j['hasTerritory'] as bool?,
        minHeat: (j['minHeat'] as num?)?.toInt() ?? 0,
        minReputation: (j['minReputation'] as num?)?.toInt() ?? 0,
        traitsAny: (j['traitsAny'] as List?)?.map((e) => '$e').toList() ?? [],
        traitsNone: (j['traitsNone'] as List?)?.map((e) => '$e').toList() ?? [],
        minGeneration: (j['minGeneration'] as num?)?.toInt() ?? 1,
        minAge: (j['minAge'] as num?)?.toInt() ?? 0,
        maxAge: (j['maxAge'] as num?)?.toInt() ?? 200,
      );
}

class ChoiceDef {
  final String id;
  final String text;
  final bool hideIfUnmet;
  final RequireDef requires;
  final List<OutcomeDef> outcomes;

  ChoiceDef({
    required this.id,
    required this.text,
    this.hideIfUnmet = false,
    RequireDef? requires,
    List<OutcomeDef>? outcomes,
  })  : requires = requires ?? RequireDef(),
        outcomes = outcomes ?? [];

  factory ChoiceDef.fromJson(Map<String, dynamic> j) => ChoiceDef(
        id: j['id'] as String? ?? 'a',
        text: j['text'] as String? ?? 'Continue',
        hideIfUnmet: j['hideIfUnmet'] as bool? ?? false,
        requires: j['requires'] is Map
            ? RequireDef.fromJson(Map<String, dynamic>.from(j['requires'] as Map))
            : RequireDef(),
        outcomes: (j['outcomes'] as List?)
                ?.map((e) => OutcomeDef.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList() ??
            [],
      );
}

class OutcomeDef {
  final String id;
  final int weight;
  final String title;
  final String body;
  final String log;
  final Map<String, int> stats;
  final List<String> addFlags;
  final List<String> removeFlags;
  final bool arrest;
  final int? setPrisonYears;
  final bool injury;
  final bool death;
  final bool lifeSentence;
  final bool spawnCrew;
  final bool marry;
  final bool divorce;
  final int spawnChildChance;
  final int crewLoyaltyDelta;
  final bool betrayCrew;
  final Map<String, int> rivalDelta;
  final Map<String, dynamic>? queueEvent;
  final String? grantTrait;
  final String? unlockAchievement;
  final bool forceHeir;
  final bool retire;
  final String? businessGain;
  final String? territoryGain;

  OutcomeDef({
    this.id = 'ok',
    this.weight = 100,
    this.title = '',
    this.body = '',
    this.log = '',
    Map<String, int>? stats,
    List<String>? addFlags,
    List<String>? removeFlags,
    this.arrest = false,
    this.setPrisonYears,
    this.injury = false,
    this.death = false,
    this.lifeSentence = false,
    this.spawnCrew = false,
    this.marry = false,
    this.divorce = false,
    this.spawnChildChance = 0,
    this.crewLoyaltyDelta = 0,
    this.betrayCrew = false,
    Map<String, int>? rivalDelta,
    this.queueEvent,
    this.grantTrait,
    this.unlockAchievement,
    this.forceHeir = false,
    this.retire = false,
    this.businessGain,
    this.territoryGain,
  })  : stats = stats ?? {},
        addFlags = addFlags ?? [],
        removeFlags = removeFlags ?? [],
        rivalDelta = rivalDelta ?? {};

  factory OutcomeDef.fromJson(Map<String, dynamic> j) => OutcomeDef(
        id: j['id'] as String? ?? 'ok',
        weight: (j['weight'] as num?)?.toInt() ?? 100,
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        log: j['log'] as String? ?? '',
        stats: _intMap(j['stats']),
        addFlags: (j['addFlags'] as List?)?.map((e) => '$e').toList() ?? [],
        removeFlags: (j['removeFlags'] as List?)?.map((e) => '$e').toList() ?? [],
        arrest: j['arrest'] as bool? ?? false,
        setPrisonYears: (j['setPrisonYears'] as num?)?.toInt(),
        injury: j['injury'] as bool? ?? false,
        death: j['death'] as bool? ?? false,
        lifeSentence: j['lifeSentence'] as bool? ?? false,
        spawnCrew: j['spawnCrew'] as bool? ?? false,
        marry: j['marry'] as bool? ?? false,
        divorce: j['divorce'] as bool? ?? false,
        spawnChildChance: (j['spawnChildChance'] as num?)?.toInt() ?? 0,
        crewLoyaltyDelta: (j['crewLoyaltyDelta'] as num?)?.toInt() ?? 0,
        betrayCrew: j['betrayCrew'] as bool? ?? false,
        rivalDelta: _intMap(j['rivalDelta']),
        queueEvent: j['queueEvent'] is Map
            ? Map<String, dynamic>.from(j['queueEvent'] as Map)
            : null,
        grantTrait: j['grantTrait'] as String?,
        unlockAchievement: j['unlockAchievement'] as String?,
        forceHeir: j['forceHeir'] as bool? ?? false,
        retire: j['retire'] as bool? ?? false,
        businessGain: j['businessGain'] as String?,
        territoryGain: j['territoryGain'] as String?,
      );

  bool get isHarsh =>
      death ||
      lifeSentence ||
      arrest ||
      injury ||
      (stats['health'] ?? 0) <= -15 ||
      (stats['money'] ?? 0) <= -800;
}

class ActivityDef {
  final String id;
  final String name;
  final String description;
  final String category;
  final String art;
  final int minAge;
  final bool prisonOnly;
  final bool freeWorldOnly;
  final RequireDef requires;
  final List<OutcomeDef> outcomes;

  ActivityDef({
    required this.id,
    required this.name,
    required this.description,
    this.category = 'life',
    this.art = 'street',
    this.minAge = 18,
    this.prisonOnly = false,
    this.freeWorldOnly = true,
    RequireDef? requires,
    required this.outcomes,
  }) : requires = requires ?? RequireDef();
}

Map<String, int> _intMap(dynamic v) {
  if (v is! Map) return {};
  return {
    for (final e in v.entries) '${e.key}': (e.value as num?)?.toInt() ?? 0,
  };
}
