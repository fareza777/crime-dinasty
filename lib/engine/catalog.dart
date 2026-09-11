import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../models/event_models.dart';
import '../models/game_models.dart';

class EventCatalog {
  EventCatalog(this.events);

  final List<EventDef> events;
  late final Map<String, EventDef> byId = {for (final e in events) e.id: e};

  EventDef? operator [](String id) => byId[id];

  static Future<EventCatalog> loadFromAssets() async {
    final raw = await rootBundle.loadString('assets/events/manifest.json');
    final files = (jsonDecode(raw) as List).map((e) => '$e').toList();
    final all = <EventDef>[];
    for (final f in files) {
      final txt = await rootBundle.loadString('assets/events/$f');
      final list = jsonDecode(txt) as List;
      for (final item in list) {
        all.add(EventDef.fromJson(Map<String, dynamic>.from(item as Map)));
      }
    }
    return EventCatalog(all);
  }

  static EventCatalog fromDecoded(List<dynamic> filesJson) {
    final all = <EventDef>[];
    for (final item in filesJson) {
      all.add(EventDef.fromJson(Map<String, dynamic>.from(item as Map)));
    }
    return EventCatalog(all);
  }

  EventDef activityAsEvent(ActivityDef a) => EventDef(
        id: 'act_${a.id}',
        title: a.name,
        body: a.description,
        category: a.category,
        art: a.art,
        minAge: a.minAge,
        choices: [
          ChoiceDef(id: 'go', text: a.name, outcomes: a.outcomes),
          ChoiceDef(
            id: 'skip',
            text: 'Never mind',
            outcomes: [
              OutcomeDef(id: 'skip', title: 'You hold still', body: 'The year waits.', log: ''),
            ],
          ),
        ],
      );
}

class SeededRng {
  SeededRng(int seed) : _rng = Random(seed);

  final Random _rng;

  int nextInt(int max) => _rng.nextInt(max);

  double nextDouble() => _rng.nextDouble();

  bool chance(num percent) => _rng.nextDouble() * 100 < percent;

  T pick<T>(List<T> items) => items[_rng.nextInt(items.length)];

  T weighted<T>(List<T> items, int Function(T) w) {
    var total = 0;
    final weights = <int>[];
    for (final i in items) {
      final v = max(0, w(i));
      weights.add(v);
      total += v;
    }
    if (total <= 0) return pick(items);
    var roll = _rng.nextInt(total);
    for (var i = 0; i < items.length; i++) {
      roll -= weights[i];
      if (roll < 0) return items[i];
    }
    return items.last;
  }
}

class WorldContent {
  static const city = 'Ravenport';
  static const startYear = 1998;
  static const startAge = 18;

  static const traits = [
    'Loyal',
    'Ambitious',
    'Cunning',
    'Reckless',
    'Greedy',
    'Compassionate',
    'Patient',
    'Violent',
    'Charming',
    'Paranoid',
  ];

  static const firstNamesMan = [
    'Julian', 'Marcus', 'Dominic', 'Caleb', 'Andre', 'Nolan', 'Wesley', 'Grant',
    'Elias', 'Roman', 'Theo', 'Malik', 'Owen', 'Silas', 'Adrian', 'Bennett',
    'Hugo', 'Isaiah', 'Leo', 'Victor', 'Darius', 'Felix', 'Jonah', 'Patrick',
  ];
  static const firstNamesWoman = [
    'Mara', 'Elena', 'Sable', 'Iris', 'Nadia', 'Quinn', 'Helena', 'Vera',
    'Camille', 'June', 'Rhea', 'Tessa', 'Lila', 'Noor', 'Avery', 'Dahlia',
    'Simone', 'Willa', 'Greta', 'Priya', 'Anika', 'Celia', 'Ruth', 'Ivy',
  ];
  static const firstNamesNb = [
    'Rowan', 'Casey', 'Morgan', 'Reese', 'Sage', 'Drew', 'Kendall', 'Eden',
    'Shiloh', 'River', 'Blake', 'Jamie',
  ];
  static const lastNames = [
    'Brennan', 'Walsh', 'Ibarra', 'Keene', 'Alvarez', 'Bishop', 'Crowe', 'Lang',
    'Patel', 'Okoye', 'Rossi', 'Nguyen', 'Hale', 'Drummond', 'Perez', 'Shah',
    'Okafor', 'Klein', 'Yates', 'Moreau', 'Diaz', 'Brooks', 'Ingram', 'Cho',
  ];
  static const crewRoles = ['muscle', 'driver', 'hacker', 'accountant', 'enforcer', 'lookout'];

  static String roleLabel(String role) => switch (role) {
        'muscle' => 'Muscle',
        'driver' => 'Driver',
        'hacker' => 'Hacker',
        'accountant' => 'Books',
        'enforcer' => 'Enforcer',
        'lookout' => 'Lookout',
        _ => role,
      };

  static String roleLoadout(String role) => switch (role) {
        'muscle' => 'Hard jobs land cleaner.',
        'driver' => 'Robbery and smuggle stay on the clock.',
        'hacker' => 'Quiet ledger does not need extra nerve.',
        'accountant' => 'Fronts pay quieter.',
        'enforcer' => 'Held streets cool faster.',
        'lookout' => 'Heat rises slower on the street.',
        _ => '',
      };

  static String districtName(String id) =>
      territories().cast<Map<String, String>?>().firstWhere((e) => e!['id'] == id, orElse: () => null)?['name'] ?? id;

  static String frontLabel(String type) => switch (type) {
        'club' => 'Nightclub',
        'shipping' => 'Shipping',
        'laundry' => 'Laundry',
        'construction' => 'Builders',
        'restaurant' => 'Supper club',
        'garage' => 'Garage',
        _ => type,
      };

  static String riskWord(int cover) {
    if (cover >= 9) return 'Low';
    if (cover >= 5) return 'Medium';
    return 'High';
  }

  static const businessMeta = {
    'club': ['The Lantern Room', 18000, 2400, 6, 'harbor_lights'],
    'laundry': ['Harbor Wash & Fold', 9000, 1100, 10, 'the_flats'],
    'shipping': ['North Pier Logistics', 28000, 3600, 8, 'docks'],
    'construction': ['Ridge & Rain Builders', 22000, 2800, 5, 'ironyard'],
    'restaurant': ['Orchard Supper Club', 14000, 1800, 4, 'old_quarter'],
    'garage': ['Westmere Motor Works', 11000, 1400, 3, 'westmere'],
  };

  static List<Map<String, String>> territories() => [
        {
          'id': 'docks',
          'name': 'The Docks',
          'blurb': 'Salt, cranes, and sealed crates. Whoever keeps the night shift keeps the city\'s pulse.',
        },
        {
          'id': 'midtown',
          'name': 'Midtown',
          'blurb': 'Glass towers and quiet lawyers. Money pretends it never gets its shoes wet.',
        },
        {
          'id': 'old_quarter',
          'name': 'Old Quarter',
          'blurb': 'Brick, neon saints, and walk-ups where everyone knows a name they should not say.',
        },
        {
          'id': 'glassridge',
          'name': 'Glassridge',
          'blurb': 'Hill money. Rain looks expensive from up here.',
        },
        {
          'id': 'the_flats',
          'name': 'The Flats',
          'blurb': 'Row houses and corner rooms. Loyalty is cheaper than rent and twice as costly.',
        },
        {
          'id': 'harbor_lights',
          'name': 'Harbor Lights',
          'blurb': 'Clubs, late ferries, and people who only exist after midnight.',
        },
        {
          'id': 'ironyard',
          'name': 'Ironyard',
          'blurb': 'Foundries gone quiet, crews that did not. Sparks still travel.',
        },
        {
          'id': 'westmere',
          'name': 'Westmere',
          'blurb': 'Quiet lawns and private gates. Respectable until the lights go out.',
        },
      ];

  static List<AchievementDef> achievements() => const [
        AchievementDef('first_score', 'Wet Pavement', 'Complete your first street score.'),
        AchievementDef('crew_of_three', 'A Proper Outfit', 'Keep three crew members at once.'),
        AchievementDef('married', 'A Witnessed Name', 'Marry in Ravenport.'),
        AchievementDef('parent', 'Bloodline', 'Have a child.'),
        AchievementDef('heir_rise', 'The Chair Passes', 'Continue as an heir.'),
        AchievementDef('prison_out', 'The Gate Opens', 'Walk out of Ravenport Detention.'),
        AchievementDef('tycoon', 'Clean Hands, Dirty Water', 'Own three businesses.'),
        AchievementDef('docks_king', 'Harbor Crown', 'Hold the Docks.'),
        AchievementDef('low_heat_rich', 'Quiet Fortune', 'Hold \$50,000 with heat under 15.'),
        AchievementDef('old_boss', 'Long Shadow', 'Lead past age 70.'),
        AchievementDef('generation_three', 'Third Verse', 'Reach generation 3.'),
        AchievementDef('rival_broke', 'Broken Crest', 'Drive a rival family below 10 power.'),
        AchievementDef('legit', 'Daylight Books', 'Carry the legitimate_turn flag.'),
        AchievementDef('heist', 'The Hill Job', 'Finish the Glassridge affair.'),
        AchievementDef('end_any', 'A Closed Ledger', 'Reach any ending.'),
      ];

  static String rivalMood(RivalFamily r) {
    if (r.hostility >= 55) {
      return switch (r.id) {
        'calderas' => 'Aurelia is counting your windows. Glassridge lights stay on past manners.',
        'rooke' => 'Dane Rooke wants a street that says his name in broken glass.',
        'vex' => 'Lior Vex has stopped sending invitations. That is not peace.',
        'marrow' => 'Nessa Marrow is recruiting with a smile that files teeth.',
        _ => 'They have stopped pretending this is business.',
      };
    }
    if (r.hostility >= 28) {
      return switch (r.id) {
        'calderas' => 'The Calderas smile like a contract. Cass is watching the door.',
        'rooke' => 'The Outfit paints over warnings. Ironyard sparks travel farther.',
        'vex' => 'House Vex offers mergers the way other people offer drinks.',
        'marrow' => 'The Kin keep Harbor Lights warm and expensive.',
        _ => 'They have noticed you.',
      };
    }
    return switch (r.id) {
      'calderas' => 'Old money, older patience. They can wait a generation.',
      'rooke' => 'Muscle with a bookie\'s sense of humor. Respect is a weekly rent.',
      'vex' => 'Midtown glass and quiet lawyers. They prefer your signature to your blood.',
      'marrow' => 'Night ferries and family dinners that double as strategy.',
      _ => 'A crest in the rain.',
    };
  }

  static String? npcMemory(Person p, Set<String> flags) {
    switch (p.id) {
      case 'p_mentor':
        if (flags.contains('sat_ever_p_mentor')) {
          if (flags.contains('will_burn_crowe')) return 'You sat. He still thinks the ferry name is rain.';
          return 'You sat. The raincoat still finds you first.';
        }
        if (flags.contains('will_burn_crowe')) return 'He still thinks the ferry name is safe with you.';
        if (flags.contains('crowe_cold')) return 'He stopped calling. The raincoat is a rumor this season.';
        if (flags.contains('crowe_secret')) return 'He gave you a name. You have not spent it.';
        if (flags.contains('mentor_crowe')) return 'The raincoat still finds you first.';
        return 'Silas Crowe watches the pier like it owes him rent.';
      case 'p_foil':
        if (flags.contains('sat_ever_p_foil')) {
          if (flags.contains('lied_to_vale')) return 'You sat. She kept the photograph anyway.';
          return 'You sat. Vale files you under unfinished, in ink now.';
        }
        if (flags.contains('vale_respect')) return 'Vale files you under unfinished, with a pencil.';
        if (flags.contains('lied_to_vale')) return 'She kept the photograph. The back has a case number.';
        if (flags.contains('vale_file')) return 'Detective Vale knows your diner. That is not nothing.';
        return 'Crown weather. She has not learned your face — yet.';
      case 'p_cass':
        if (flags.contains('sat_ever_p_cass')) return 'You sat. The gold still measures the chair.';
        if (flags.contains('cass_notice')) return 'The gold card is still in the drawer.';
        return 'Aurelia\'s heir. Sharp, bored, and already measuring the chair.';
      case 'p_mira':
        if (flags.contains('sat_ever_p_mira')) {
          if (flags.contains('courted')) return 'You sat. The second drink is already a habit.';
          return 'You sat. Harbor Lights still keeps your booth.';
        }
        return 'Harbor Lights after midnight. She remembers who buys the second drink.';
      case 'p_ben':
        if (flags.contains('sat_ever_p_ben')) {
          if (flags.contains('courted')) return 'You sat. He is still waiting on a daylight surname.';
          return 'You sat. Glassridge manners, still on the clock.';
        }
        return 'Glassridge manners. He wants a daylight surname and will wait for yours.';
      default:
        return null;
    }
  }

  static const endings = {
    'forgotten': [
      'Filed Under Weather',
      'Ravenport did not fight you. It forgot you. No street, no front, too many quiet years. The chair stays empty. This is not a dynasty.',
    ],
    'bloodline_ends': [
      'The Empty Chair',
      'No adult heir would take the name. Ravenport files the Harts under weather and rumor.',
    ],
    'retired_quiet': [
      'A House by the Water',
      'You put the yearbook down and let the rain work without you. The city does not applaud. It allows it.',
    ],
    'died_old': [
      'Natural Causes, Unnatural Life',
      'Age did what crews and courts could not. The table is still set for whoever sits next.',
    ],
    'died_street': [
      'A Night That Did Not Forgive',
      'Ravenport keeps the details. The family keeps the name.',
    ],
    'life_inside': [
      'The Long Corridor',
      'The state claims the rest of your years. Someone younger inherits the unfinished city.',
    ],
    'empire': [
      'Vice Dynasty',
      'Three generations, a skyline of fronts, and a city that says your surname like a weather warning.',
    ],
    'gone_straight': [
      'Daylight Surname',
      'The books are almost clean. The rain still knows you.',
    ],
  };
}

class AchievementDef {
  final String id;
  final String title;
  final String description;
  const AchievementDef(this.id, this.title, this.description);
}

class NameBank {
  static String first(SeededRng rng, String gender) {
    if (gender == 'woman') return rng.pick(WorldContent.firstNamesWoman);
    if (gender == 'man') return rng.pick(WorldContent.firstNamesMan);
    return rng.pick(WorldContent.firstNamesNb);
  }

  static String last(SeededRng rng) => rng.pick(WorldContent.lastNames);

  static String gender(SeededRng rng) {
    final r = rng.nextInt(10);
    if (r < 5) return 'man';
    if (r < 9) return 'woman';
    return 'nonbinary';
  }
}
