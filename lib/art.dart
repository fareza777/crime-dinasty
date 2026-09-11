import 'models/game_models.dart';

/// Asset paths for the neo-noir art pack.
class Art {
  static const splash = 'assets/images/splash.png';
  static const openingStill = 'assets/images/opening_still.png';
  static const logoPlate = 'assets/images/logo_plate.png';
  static const cover = 'assets/images/cover.png';
  static const titlePoster = 'assets/images/title_poster.png';
  static const eventPanel = 'assets/images/events/panel_rain.png';
  static const hall = 'assets/images/hall.png';
  static const emptyChair = 'assets/images/empty_chair.png';
  static const crew = 'assets/images/crew.png';
  static const dossier = 'assets/images/dossier_frame.png';
  static const yearBanner = 'assets/images/year_banner.png';

  static const panel = 'assets/images/chrome/panel.png';
  static const btnPrimary = 'assets/images/chrome/btn_primary.png';
  static const btnDanger = 'assets/images/chrome/btn_danger.png';
  static const btnGhost = 'assets/images/chrome/btn_ghost.png';
  static const choice = 'assets/images/chrome/choice.png';

  static const navLife = 'assets/icons/life.png';
  static const navFamily = 'assets/icons/family.png';
  static const navCity = 'assets/icons/city.png';
  static const navEmpire = 'assets/icons/empire.png';
  static const navMore = 'assets/icons/more.png';

  static const icoActivities = 'assets/icons/activities.png';
  static const icoBusiness = 'assets/icons/business.png';
  static const icoRelations = 'assets/icons/relationships.png';
  static const icoCourt = 'assets/icons/court.png';
  static const icoLegacy = 'assets/icons/legacy.png';
  static const icoSettings = 'assets/icons/settings.png';
  static const tipCompass = 'assets/icons/tip_compass.png';

  static String header(String key) => 'assets/images/headers/$key.png';

  static String empty(String key) => 'assets/images/empty_$key.png';

  static String activityTile(String key) => 'assets/images/activities/$key.png';

  static String businessFront(String type) {
    const known = {'club', 'shipping', 'laundry', 'construction', 'restaurant', 'garage'};
    final key = known.contains(type) ? type : 'club';
    return 'assets/images/fronts/$key.png';
  }

  static const portraitKeys = <String>[
    'player_man',
    'player_woman',
    'player_nb',
    'sibling',
    'mentor',
    'vale',
    'cass',
    'mira',
    'ben',
    'matriarch',
    'enforcer',
    'child',
    'spouse_man',
    'spouse_woman',
    'vex',
    'nessa',
    'parent_man',
    'crew_woman',
    'teen_girl',
    'cousin',
  ];

  static const agedPortraitKeys = <String>[
    'player_man_old',
    'player_woman_old',
    'player_nb_old',
  ];

  static String agedKeyFor(Person p) {
    if (p.gender == 'woman') return 'player_woman_old';
    if (p.gender == 'nonbinary') return 'player_nb_old';
    return 'player_man_old';
  }

  static String portrait(String key) {
    final known = [...portraitKeys, ...agedPortraitKeys];
    final k = known.contains(key) ? key : 'player_man';
    return 'assets/images/portraits/$k.png';
  }

  /// Ordered unique-face preferences so Family Tree never clones one head.
  static List<String> preferredKeys(Person p, {int year = 1998}) {
    switch (p.id) {
      case 'p_founder':
      case 'p_player':
        break;
      case 'p_mentor':
        return const ['mentor', 'parent_man', 'enforcer'];
      case 'p_foil':
        return const ['vale', 'nessa', 'matriarch'];
      case 'p_cass':
        return const ['cass', 'player_nb', 'vex'];
      case 'p_mira':
        return const ['mira', 'spouse_woman', 'teen_girl'];
      case 'p_ben':
        return const ['ben', 'spouse_man', 'player_man'];
    }

    final age = p.ageIn(year);
    if (p.relation == 'self') {
      if (age >= 52) {
        if (p.gender == 'woman') return const ['player_woman_old', 'matriarch', 'nessa', 'player_woman'];
        if (p.gender == 'nonbinary') return const ['player_nb_old', 'vex', 'player_nb', 'cass'];
        return const ['player_man_old', 'parent_man', 'mentor', 'player_man'];
      }
      if (p.gender == 'woman') return const ['player_woman', 'spouse_woman', 'mira', 'cass'];
      if (p.gender == 'nonbinary') return const ['player_nb', 'cass', 'vex', 'cousin'];
      return const ['player_man', 'spouse_man', 'ben', 'sibling'];
    }
    if (p.relation == 'spouse') {
      if (p.gender == 'man') return const ['spouse_man', 'ben', 'player_man', 'parent_man'];
      if (p.gender == 'nonbinary') return const ['player_nb', 'vex', 'cass', 'cousin'];
      return const ['spouse_woman', 'mira', 'matriarch', 'player_woman'];
    }
    if (p.relation == 'sibling') {
      if (age < 13) return const ['child', 'teen_girl', 'cousin'];
      if (p.gender == 'woman') return const ['teen_girl', 'mira', 'player_woman'];
      if (p.gender == 'nonbinary') return const ['cousin', 'player_nb', 'cass'];
      return const ['sibling', 'cousin', 'player_man'];
    }
    if (p.relation == 'child') {
      if (age < 12) return const ['child', 'teen_girl', 'cousin'];
      if (p.gender == 'woman') return const ['teen_girl', 'player_woman', 'mira'];
      if (p.gender == 'nonbinary') return const ['cousin', 'player_nb', 'cass'];
      return const ['sibling', 'player_man', 'cousin'];
    }
    if (p.relation == 'parent') {
      if (p.gender == 'woman') return const ['matriarch', 'nessa', 'vale'];
      return const ['parent_man', 'mentor', 'enforcer'];
    }
    if (p.relation == 'mentor') return const ['mentor', 'parent_man'];
    if (p.relation == 'foil') return const ['vale', 'nessa'];
    if (p.relation == 'rival_heir' || p.lifePath == 'rival' || p.rivalFamilyId != null) {
      if (p.rivalFamilyId == 'calderas') return const ['matriarch', 'cass', 'vex'];
      if (p.rivalFamilyId == 'rooke') return const ['enforcer', 'parent_man', 'crew_woman'];
      if (p.rivalFamilyId == 'vex') return const ['vex', 'player_nb', 'ben'];
      if (p.rivalFamilyId == 'marrow') return const ['nessa', 'crew_woman', 'matriarch'];
      return const ['cass', 'vex', 'enforcer', 'nessa'];
    }
    if (p.relation == 'crew') {
      if (p.gender == 'woman') return const ['crew_woman', 'nessa', 'mira'];
      if (p.gender == 'nonbinary') return const ['vex', 'cass', 'cousin'];
      return const ['enforcer', 'cousin', 'parent_man', 'ben'];
    }
    if (p.relation == 'cousin' || p.relation == 'inlaw') {
      return const ['cousin', 'teen_girl', 'spouse_man', 'crew_woman'];
    }
    if (p.gender == 'woman') return const ['mira', 'spouse_woman', 'teen_girl', 'vale'];
    if (p.gender == 'nonbinary') return const ['player_nb', 'cass', 'vex', 'cousin'];
    return const ['ben', 'spouse_man', 'sibling', 'player_man'];
  }

  static String portraitKeyFor(Person p, {int year = 1998}) {
    if (p.relation == 'self' && p.ageIn(year) >= 52) return agedKeyFor(p);
    if (p.portraitKey.isNotEmpty && portraitKeys.contains(p.portraitKey)) {
      return p.portraitKey;
    }
    return preferredKeys(p, year: year).first;
  }

  static String portraitFor(Person p, {int year = 1998}) => portrait(portraitKeyFor(p, year: year));

  static String claimKey(Person p, Set<String> used, {int year = 1998}) {
    final prefs = preferredKeys(p, year: year);
    var key = prefs.firstWhere((k) => !used.contains(k), orElse: () => '');
    if (key.isEmpty) {
      key = portraitKeys.firstWhere((k) => !used.contains(k), orElse: () => prefs.first);
    }
    used.add(key);
    p.portraitKey = key;
    return key;
  }

  static String stat(String key) {
    const map = {
      'health': 'assets/icons/stat_health.png',
      'intelligence': 'assets/icons/stat_int.png',
      'charisma': 'assets/icons/stat_cha.png',
      'nerve': 'assets/icons/stat_nerve.png',
      'loyalty': 'assets/icons/stat_loyalty.png',
      'reputation': 'assets/icons/stat_rep.png',
      'heat': 'assets/icons/stat_heat.png',
      'stress': 'assets/icons/stat_stress.png',
      'money': 'assets/icons/stat_cash.png',
      'hp': 'assets/icons/stat_health.png',
      'int': 'assets/icons/stat_int.png',
      'cha': 'assets/icons/stat_cha.png',
      'nrv': 'assets/icons/stat_nerve.png',
      'loy': 'assets/icons/stat_loyalty.png',
      'rep': 'assets/icons/stat_rep.png',
      'str': 'assets/icons/stat_stress.png',
      'cash': 'assets/icons/stat_cash.png',
    };
    return map[key.toLowerCase()] ?? 'assets/icons/stat_rep.png';
  }

  static const districtIds = {
    'docks',
    'glassridge',
    'harbor_lights',
    'ironyard',
    'midtown',
    'old_quarter',
    'the_flats',
    'westmere',
  };

  static String district(String id) => 'assets/images/districts/$id.png';

  static String crest(String id) => 'assets/images/crests/$id.png';

  static String lifeStill(String key) => districtIds.contains(key) ? district(key) : event(key);

  static String event(String key) {
    const aliases = {
      'crime': 'crime_night',
      'family': 'family_dinner',
      'rival': 'betrayal',
    };
    if (key == 'legacy') return emptyChair;
    if (key == 'laundry') return businessFront('laundry');
    final file = aliases[key] ?? key;
    return 'assets/images/events/$file.png';
  }

  static String portraitChip(int seed) {
    const fallback = ['player_man', 'vale', 'mentor', 'matriarch', 'enforcer'];
    return portrait(fallback[seed.abs() % fallback.length]);
  }
}
