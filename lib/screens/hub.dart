import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../art.dart';
import '../engine/catalog.dart';
import '../engine/game_engine.dart';
import '../game_controller.dart';
import '../models/game_models.dart';
import '../theme/app_theme.dart';
import '../tour.dart';
import '../widgets/common.dart';
import '../widgets/dynasty_tree.dart';
import 'overlays.dart';

class HubShell extends StatelessWidget {
  const HubShell({super.key, required this.c});
  final GameController c;

  @override
  Widget build(BuildContext context) {
    final e = c.engine!;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: Palette.light ? 0.08 : 0.28,
              child: Image.asset(Art.splash, fit: BoxFit.cover, errorBuilder: (_, _, _) => ColoredBox(color: Palette.navy)),
            ),
          ),
          Positioned.fill(
            child: Container(color: Palette.navy.withValues(alpha: Palette.light ? 0.96 : 0.55)),
          ),
          Column(
            children: [
              _TopBar(c: c),
              Expanded(
                child: IndexedStack(
                  index: c.hubIndex.clamp(0, 3),
                  children: [
                    LifeScreen(c: c),
                    FamilyScreen(c: c),
                    CityScreen(c: c),
                    MoreScreen(c: c),
                  ],
                ),
              ),
            ],
          ),
          if (e.state.phase == 'event' && e.currentEvent() != null && c.lastOutcome == null) EventLayer(c: c),
          if (c.lastOutcome != null) OutcomeLayer(c: c),
          if (e.state.awaitingHeir && c.lastOutcome == null) HeirLayer(c: c),
          if (e.state.phase == 'ending' && c.lastOutcome == null) EndingLayer(c: c),
          if (c.showHelp) HelpSheet(c: c),
          if (c.showSideSheet) SideActionSheet(c: c),
        ],
      ),
      bottomNavigationBar: _NoirNav(c: c, index: c.hubIndex.clamp(0, 3), onSelect: c.setHub),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.c});
  final GameController c;
  @override
  Widget build(BuildContext context) {
    final s = c.s;
    return Container(
      color: Palette.navy2,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 6, left: 14, right: 14, bottom: 8),
      child: Column(
        children: [
          Row(
            children: [
              FramedPortrait(person: s.player, size: 44, year: s.year),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.player.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Cinzel', fontSize: 15, color: Palette.gold)),
                    Text(
                        '${s.year} · age ${s.age}${s.generation > 1 ? ' · gen ${s.generation}' : ''}${s.inPrison ? ' · in prison' : ''}',
                        style: TextStyle(color: Palette.muted, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'How to play',
                onPressed: c.openHelp,
                icon: Icon(Icons.help_outline, color: Palette.gold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
            children: [
              StatChip(label: 'Cash', value: s.stats.money, statKey: 'cash'),
              const SizedBox(width: 6),
              StatChip(label: 'Heat', value: s.stats.heat, warn: s.stats.heat > 55, statKey: 'heat'),
              const SizedBox(width: 6),
              StatChip(label: 'Health', value: s.stats.health, warn: s.stats.health < 30, statKey: 'health'),
              const SizedBox(width: 6),
              StatChip(label: 'Rep', value: s.stats.reputation, statKey: 'reputation'),
            ],
            ),
          ),
          if (c.showMoreStats) ...[
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  StatChip(label: 'INT', value: s.stats.intelligence, statKey: 'intelligence'),
                  const SizedBox(width: 6),
                  StatChip(label: 'CHA', value: s.stats.charisma, statKey: 'charisma'),
                  const SizedBox(width: 6),
                  StatChip(label: 'Nerve', value: s.stats.nerve, statKey: 'nerve'),
                  const SizedBox(width: 6),
                  StatChip(label: 'Loyalty', value: s.stats.loyalty, statKey: 'loyalty'),
                  const SizedBox(width: 6),
                  StatChip(label: 'Stress', value: s.stats.stress, warn: s.stats.stress > 65, statKey: 'stress'),
                ],
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: c.toggleMoreStats,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(c.showMoreStats ? 'Hide extra stats' : 'More stats',
                    style: TextStyle(color: Palette.goldSoft, fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LifeScreen extends StatelessWidget {
  const LifeScreen({super.key, required this.c});
  final GameController c;

  @override
  Widget build(BuildContext context) {
    final e = c.engine!;
    final s = e.state;
    final last = s.timeline.isEmpty ? null : s.timeline.last;
    final blocked = s.phase == 'event' || c.lastOutcome != null || s.awaitingHeir || s.phase == 'ending';
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: c.yearFlash
                      ? [BoxShadow(color: Palette.gold.withValues(alpha: 0.35), blurRadius: 18)]
                      : null,
                ),
                child: SceneArt(s.inPrison ? Art.event('prison') : Art.event('skyline'), height: 138, textured: true),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: Text(
                  s.inPrison ? 'Prison — year ${s.year}' : 'Year ${s.year}',
                  key: ValueKey(s.year),
                  style: TextStyle(fontFamily: 'Cinzel', color: Palette.gold, fontSize: 22, letterSpacing: 0.4),
                ),
              ),
              Text(
                s.generation > 1
                    ? 'Gen ${s.generation} · age ${s.age} · ${s.dynastyName} · cash ${s.stats.money} · heat ${s.stats.heat}'
                    : 'Age ${s.age} · ${s.dynastyName} · cash ${s.stats.money} · heat ${s.stats.heat}',
                style: TextStyle(color: Palette.muted, fontSize: 13),
              ),
              const SizedBox(height: 10),
              GoldFrame(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const PixelIcon(Art.tipCompass, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('THIS YEAR', style: TextStyle(color: Palette.muted, fontSize: 10, letterSpacing: 0.8)),
                          Text(e.ambition(), style: TextStyle(color: Palette.goldSoft, height: 1.35, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (e.warLine() != null) ...[
                GoldFrame(
                  accent: true,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WAR SEASON', style: TextStyle(color: Palette.gold, fontSize: 10, letterSpacing: 1.1)),
                      const SizedBox(height: 4),
                      Text(e.warLine()!, style: TextStyle(color: Palette.cream, height: 1.35, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              NarrativePanel(e.cityPressure(), fontSize: 13),
              const SizedBox(height: 10),
              if (last == null)
                GoldFrame(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('OPEN THE YEAR', style: TextStyle(color: Palette.muted, fontSize: 10, letterSpacing: 1.1)),
                      const SizedBox(height: 6),
                      Text(
                        'The rain is waiting. Open the year when you are ready.',
                        style: TextStyle(color: Palette.cream, height: 1.45, fontSize: 15),
                      ),
                    ],
                  ),
                )
              else
                NarrativePanel(last.text),
              if (s.lastYearLog.isNotEmpty) ...[
                const SizedBox(height: 14),
                GoldFrame(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SceneArt(Art.yearBanner, height: 52, alignment: Alignment.center),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('WHEN THE YEAR CLOSED', style: TextStyle(color: Palette.muted, fontSize: 10, letterSpacing: 1.1)),
                            const SizedBox(height: 6),
                            Text(
                              s.yearHeadline.isEmpty ? 'The books moved.' : s.yearHeadline,
                              style: TextStyle(fontFamily: 'Cinzel', color: Palette.gold, fontSize: 16, height: 1.3),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                GlanceChip(label: 'Year', value: '${s.year}'),
                                GlanceChip(label: 'Age', value: '${s.age}'),
                                GlanceChip(label: 'Cash', value: MoneyText.format(s.stats.money)),
                                GlanceChip(label: 'Heat', value: '${s.stats.heat}', warn: s.stats.heat > 55),
                              ],
                            ),
                            const SizedBox(height: 8),
                            for (final line in s.lastYearLog.take(4))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text('· $line', style: TextStyle(color: Palette.cream, height: 1.35, fontSize: 13)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (s.inPrison) ...[
                const SizedBox(height: 8),
                Text('${s.prisonYearsLeft} year${s.prisonYearsLeft == 1 ? '' : 's'} left inside. You still play each year.',
                    style: TextStyle(color: Palette.muted, fontSize: 13)),
              ],
              if (s.timeline.length > 1) ...[
                const SizedBox(height: 14),
                const SectionTitle('Earlier this life'),
                for (final line in s.timeline.reversed.skip(1).take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('${line.year} — ${line.text}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Palette.muted, height: 1.35, fontSize: 13)),
                  ),
              ],
            ],
          ),
        ),
        if (!blocked) _YearDock(c: c),
      ],
    );
  }
}

class _YearDock extends StatelessWidget {
  const _YearDock({required this.c});
  final GameController c;

  @override
  Widget build(BuildContext context) {
    final e = c.engine!;
    final see = e.yearEventPending;
    final next = e.canAgeUp;
    return Material(
      color: Palette.navy2,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Palette.gold.withValues(alpha: 0.35))),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KeyedSubtree(
              key: c.tourKeys.yearCta,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                decoration: BoxDecoration(
                  boxShadow: see ? [BoxShadow(color: Palette.gold.withValues(alpha: 0.22), blurRadius: 14)] : null,
                ),
                child: PrimaryButton(
                  label: 'What happens this year',
                  onTap: see ? c.seeYear : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            GhostButton(
              label: e.state.activityUsed ? 'Already did something' : 'Do something',
              onTap: e.state.activityUsed || e.state.currentEventId != null ? null : c.openSideSheet,
            ),
            const SizedBox(height: 8),
            KeyedSubtree(
              key: c.tourKeys.nextYear,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                decoration: BoxDecoration(
                  boxShadow: next ? [BoxShadow(color: Palette.goldSoft.withValues(alpha: 0.28), blurRadius: 14)] : null,
                ),
                child: PrimaryButton(
                  label: 'Next year',
                  color: Palette.goldSoft,
                  onTap: next ? c.nextYear : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HelpSheet extends StatelessWidget {
  const HelpSheet({super.key, required this.c});
  final GameController c;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.scrim,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: GoldFrame(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('How to play', style: TextStyle(fontFamily: 'Cinzel', color: Palette.gold, fontSize: 20)),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.46),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('1. Tap What happens this year.'),
                        SizedBox(height: 6),
                        Text('2. Pick one option on the card.'),
                        SizedBox(height: 6),
                        Text('3. Optionally Do something, then tap Next year.'),
                        SizedBox(height: 10),
                        Text(
                          'Sit with only one person each year. Gift is also once per year, separate from Sit. Empire hire is cash, not the year\'s extra move. Unaffordable buttons say how much more you need.',
                          style: TextStyle(color: Palette.muted, height: 1.35),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'When this life ends, pick who sits next. Money, turf, and enemies stay with the name.',
                          style: TextStyle(color: Palette.muted, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(label: 'Replay tour', onTap: c.replayTour),
                const SizedBox(height: 8),
                GhostButton(label: 'Got it', onTap: c.closeHelp),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SideActionSheet extends StatelessWidget {
  const SideActionSheet({super.key, required this.c});
  final GameController c;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.scrim,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GoldFrame(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Do something this year',
                      style: TextStyle(fontFamily: 'Cinzel', color: Palette.gold, fontSize: 18)),
                  const SizedBox(height: 6),
                  Text('Optional. One extra move, then you can still go to next year.',
                      style: TextStyle(color: Palette.muted, fontSize: 13)),
                  const SizedBox(height: 12),
                  for (final row in const [
                    ('earn', 'Earn', 'A quiet payday.'),
                    ('risk', 'Risk', 'More cash. More heat.'),
                    ('family', 'Family', 'Open Family. One Sit per year.'),
                    ('cool', 'Cool down', 'Let the city forget you.'),
                  ]) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GoldFrame(
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        child: Row(
                          children: [
                            PixelIcon(Art.activityTile(row.$1), size: 44),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(row.$2, style: TextStyle(fontFamily: 'Cinzel', color: Palette.gold)),
                                  Text(row.$3, style: TextStyle(color: Palette.muted, fontSize: 12)),
                                ],
                              ),
                            ),
                            PrimaryButton(label: row.$2, expand: false, onTap: () => c.doSide(row.$1)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  GhostButton(label: 'Not now', onTap: c.closeSideSheet),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key, required this.c});
  final GameController c;

  @override
  Widget build(BuildContext context) {
    final e = c.engine!;
    final people = e.state.people.values.toList()
      ..sort((a, b) => a.birthYear.compareTo(b.birthYear));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        HeaderBanner(
          asset: Art.header('family'),
          title: 'Family',
          subtitle: e.familyCapBlurb(),
        ),
        for (var i = 0; i < people.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Builder(
              builder: (context) {
                final p = people[i];
                final you = p.id == e.state.playerId;
                                final satThem = e.satPersonId() == p.id;
                final giftThem = e.giftedPersonId() == p.id;
                final card = GestureDetector(
                  onTap: () => c.tourConsume(TourAnchor.familyTree),
                  child: GoldFrame(
                    accent: satThem || giftThem,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FramedPortrait(person: p, size: 52, year: e.state.year),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name + (you ? '  · you' : ''),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontFamily: 'Cinzel', fontSize: 14, color: Palette.cream),
                              ),
                              Text(
                                '${p.relation} · ${p.isAlive ? 'age ${p.ageIn(e.state.year)}' : 'd. ${p.deathYear}'} · ${p.lifePath}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Palette.muted, fontSize: 12),
                              ),
                              if (p.traits.isNotEmpty)
                                Text(
                                  p.traits.join(', '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Palette.muted, fontSize: 11),
                                ),
                              const SizedBox(height: 4),
                              Text('Bond ${p.bond} · loyalty ${p.loyaltyToFamily}',
                                  style: TextStyle(color: Palette.goldSoft, fontSize: 12)),
                              if (WorldContent.npcMemory(p, e.state.flags) != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    WorldContent.npcMemory(p, e.state.flags)!,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Palette.goldSoft, fontSize: 12, height: 1.3),
                                  ),
                                ),
                              if (!you && p.isAlive) ...[
                                const SizedBox(height: 8),
                                _BondActions(c: c, person: p),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                return i == 0 ? KeyedSubtree(key: c.tourKeys.familyTree, child: card) : card;
              },
            ),
          ),
      ],
    );
  }
}

class _BondActions extends StatelessWidget {
  const _BondActions({required this.c, required this.person});
  final GameController c;
  final Person person;

  @override
  Widget build(BuildContext context) {
    final e = c.engine!;
    final satId = e.satPersonId();
    final satThem = satId == person.id;
    final satOther = e.satThisYear && !satThem;
    final giftId = e.giftedPersonId();
    final giftThem = giftId == person.id;
    final giftOther = e.giftedThisYear && !giftThem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (satThem)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('Sat with them this year.', style: TextStyle(color: Palette.goldSoft, fontSize: 12)),
          )
        else if (satOther)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('Already sat with someone this year.', style: TextStyle(color: Palette.muted, fontSize: 12)),
          ),
        if (giftThem)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('Gifted them this year.', style: TextStyle(color: Palette.goldSoft, fontSize: 12)),
          )
        else if (giftOther)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('Already gifted someone this year.', style: TextStyle(color: Palette.muted, fontSize: 12)),
          ),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            if (!e.satThisYear)
              MiniAction(label: 'Sit', onTap: () => c.sitWith(person.id)),
            if (!e.giftedThisYear)
              MiniAction(
                label: GameEngine.unaffordable(e.state.stats.money, GameEngine.giftCost) ?? 'Gift · \$${GameEngine.giftCost}',
                onTap: GameEngine.unaffordable(e.state.stats.money, GameEngine.giftCost) == null
                    ? () => c.giftPerson(person.id)
                    : null,
              ),
          ],
        ),
      ],
    );
  }
}

class CityScreen extends StatelessWidget {
  const CityScreen({super.key, required this.c});
  final GameController c;

  @override
  Widget build(BuildContext context) {
    final s = c.s;
    String owner(Territory t) {
      if (t.controller == 'player') return s.dynastyName;
      if (t.controller == null) return 'Open';
      final r = s.rivals.cast<RivalFamily?>().firstWhere((e) => e!.id == t.controller, orElse: () => null);
      return r?.name ?? t.controller!;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        HeaderBanner(
          asset: Art.header('city'),
          title: 'Ravenport',
          subtitle: '${c.engine!.cityPressure()} Open streets want a hand and cash. Held streets can be cooled. You do not need this screen to finish a year.',
        ),
        if (c.engine!.warLine() != null) ...[
          GoldFrame(
            accent: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WAR SEASON', style: TextStyle(color: Palette.gold, fontSize: 10, letterSpacing: 1.1)),
                const SizedBox(height: 6),
                Text(c.engine!.warLine()!, style: TextStyle(color: Palette.cream, height: 1.35, fontSize: 15)),
                const SizedBox(height: 6),
                Text(
                  'Threat becomes a street or a pinch of cash. Resolution cools the house — or leaves blood on the books.',
                  style: TextStyle(color: Palette.muted, fontSize: 12, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        for (var i = 0; i < s.territories.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Builder(
              builder: (context) {
                final t = s.territories[i];
                final card = GestureDetector(
                  onTap: () => c.tourConsume(TourAnchor.cityDistrict),
                  child: GoldFrame(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SceneArt(Art.district(t.id), height: 92),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                t.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontFamily: 'Cinzel', color: Palette.gold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                owner(t),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: TextStyle(color: Palette.muted, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(t.blurb, style: TextStyle(fontSize: 13, color: Palette.cream, height: 1.35)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            GlanceChip(label: 'Income', value: '${t.income}'),
                            GlanceChip(label: 'Heat', value: '${t.heat}', warn: t.heat > 20),
                            GlanceChip(label: 'Hold', value: '${t.influence}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(height: 6),
                        Text(
                          t.controller == 'player'
                              ? 'Yours. Cool it if heat is loud.'
                              : (t.controller == null
                                  ? (s.crew.isEmpty
                                      ? 'Open. Hire a hand on Empire, then press.'
                                      : 'Open. Press if the books can stand \$${GameEngine.pressCost}.')
                                  : 'Held by a house. Pressing here starts a fight.'),
                          style: TextStyle(color: Palette.goldSoft, fontSize: 12, height: 1.3),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (t.controller != 'player')
                              MiniAction(
                                label: s.crew.isEmpty
                                    ? 'Hire a hand first'
                                    : (GameEngine.unaffordable(s.stats.money, GameEngine.pressCost) ??
                                        'Press · \$${GameEngine.pressCost}'),
                                onTap: s.crew.isEmpty || GameEngine.unaffordable(s.stats.money, GameEngine.pressCost) != null
                                    ? null
                                    : () => c.pressTurf(t.id),
                              ),
                            if (t.controller == 'player')
                              MiniAction(
                                label: GameEngine.unaffordable(s.stats.money, GameEngine.coolCost) ??
                                    'Cool · \$${GameEngine.coolCost}',
                                onTap: GameEngine.unaffordable(s.stats.money, GameEngine.coolCost) == null
                                    ? () => c.coolTurf(t.id)
                                    : null,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
                );
                return i == 0 ? KeyedSubtree(key: c.tourKeys.cityDistrict, child: card) : card;
              },
            ),
          ),
        const SectionTitle('Rival families'),
        for (final r in s.rivals)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GoldFrame(
              accent: c.engine!.warRival()?.id == r.id,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PixelIcon(Art.crest(r.id), size: 56),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name, style: TextStyle(fontFamily: 'Cinzel', color: Palette.gold)),
                        Text('${r.bossName} · power ${r.power} · hostility ${r.hostility}',
                            style: TextStyle(color: Palette.muted, fontSize: 12)),
                        const SizedBox(height: 6),
                        Text(WorldContent.rivalMood(r), style: TextStyle(height: 1.35, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          r.territories.isEmpty
                              ? 'No turf on the board.'
                              : r.territories.map(WorldContent.districtName).join(' · '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Palette.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class EmpireScreen extends StatelessWidget {
  const EmpireScreen({super.key, required this.c});
  final GameController c;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final e = c.engine!;
        final s = e.state;
        final take = s.businesses.fold<int>(0, (n, b) => n + b.yearlyIncome);
        final hireNeed = GameEngine.unaffordable(s.stats.money, GameEngine.hireCost);
        final frontNeed = e.buyFrontReason();
        final openTypes = e.availableFrontTypes();
        final mood = s.crew.isEmpty
            ? 'Earn a year, hire a hand, then open a front.'
            : s.crew.map((m) => m.loyalty).reduce((a, b) => a + b) / s.crew.length >= 70
                ? 'The table is loyal.'
                : s.crew.map((m) => m.loyalty).reduce((a, b) => a + b) / s.crew.length >= 45
                    ? 'The table is working.'
                    : 'The table is restless.';
        final bottom = MediaQuery.paddingOf(context).bottom;
        return Scaffold(
          backgroundColor: Palette.navy,
          appBar: AppBar(
            backgroundColor: Palette.navy2,
            titleSpacing: 4,
            leadingWidth: 44,
            title: const ScreenTitle('Empire'),
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottom),
            children: [
              HeaderBanner(
                asset: Art.header('empire'),
                title: 'The books',
                subtitle: 'Hire and pay crew. Invest in fronts. This is cash, not the year\'s extra move.',
              ),
              GoldFrame(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mood, style: TextStyle(fontFamily: 'Cinzel', color: Palette.gold, fontSize: 15)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        GlanceChip(label: 'Cash', value: MoneyText.format(s.stats.money)),
                        GlanceChip(label: 'Crew', value: '${s.crew.length}/5'),
                        GlanceChip(label: 'Fronts', value: '${s.businesses.length}'),
                        GlanceChip(label: 'Year take', value: MoneyText.format(take)),
                        GlanceChip(label: 'Heat', value: '${s.stats.heat}', warn: s.stats.heat > 55),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SectionTitle('Crew'),
              if (s.crew.isEmpty)
                EmptyState(
                  art: Art.empty('crew'),
                  text: s.inPrison
                      ? 'You cannot hire from inside. Finish the stretch, then fill the table.'
                      : 'No one on the books. Play Life to earn, then hire a hand for \$${GameEngine.hireCost}. This does not spend the year\'s extra move.',
                  cta: s.inPrison || s.crew.length >= 5
                      ? 'Back to Life'
                      : (hireNeed ?? 'Hire a hand · \$${GameEngine.hireCost}'),
                  onTap: s.inPrison || s.crew.length >= 5
                      ? () {
                          Navigator.maybePop(context);
                          c.setHub(0);
                        }
                      : (hireNeed == null ? c.hireHand : null),
                )
              else ...[
                for (final m in s.crew) _CrewCard(c: c, member: m),
                if (s.crew.length < 5 && !s.inPrison) ...[
                  const SizedBox(height: 4),
                  PrimaryButton(
                    label: hireNeed ?? 'Hire another hand · \$${GameEngine.hireCost}',
                    onTap: hireNeed == null ? c.hireHand : null,
                  ),
                ],
              ],
              const SizedBox(height: 18),
              const SectionTitle('Fronts'),
              if (s.businesses.isEmpty)
                EmptyState(
                  art: Art.empty('shop'),
                  text:
                      'No fronts yet. Play years on Life for a key, or open one here when the books can stand \$${GameEngine.frontCost}.',
                  cta: s.inPrison
                      ? 'Back to Life'
                      : (frontNeed ?? 'Open a front · \$${GameEngine.frontCost}'),
                  onTap: s.inPrison
                      ? () {
                          Navigator.maybePop(context);
                          c.setHub(0);
                        }
                      : (frontNeed == null ? () => c.buyFront() : null),
                )
              else
                for (final b in s.businesses) _FrontCard(c: c, business: b),
              if (openTypes.isNotEmpty && !s.inPrison) ...[
                const SizedBox(height: 8),
                Text(
                  s.businesses.isEmpty
                      ? 'The shop. Cash opens a front. Years can still gift a key.'
                      : 'Open another front when the books allow.',
                  style: TextStyle(color: Palette.muted, fontSize: 12, height: 1.35),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final type in openTypes)
                      MiniAction(
                        label: frontNeed ??
                            '${WorldContent.frontLabel(type)} · \$${GameEngine.frontCost}',
                        onTap: frontNeed == null ? () => c.buyFront(type) : null,
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CrewCard extends StatelessWidget {
  const _CrewCard({required this.c, required this.member});
  final GameController c;
  final CrewMember member;

  @override
  Widget build(BuildContext context) {
    final s = c.s;
    final p = s.people[member.personId];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GoldFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p != null) FramedPortrait(person: p, size: 52, year: s.year) else PixelIcon(Art.crew, size: 48),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p?.name ?? member.personId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: 'Cinzel', fontSize: 15, color: Palette.cream),
                      ),
                      Text(
                        WorldContent.roleLabel(member.role),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Palette.goldSoft, fontSize: 12),
                      ),
                      if (member.assignedBizId != null)
                        Text(
                          'Watches ${c.s.businesses.cast<Business?>().firstWhere((b) => b!.id == member.assignedBizId, orElse: () => null)?.name ?? 'a front'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Palette.muted, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GlanceChip(label: 'Cut', value: '${member.cut}%'),
              ],
            ),
            const SizedBox(height: 10),
            MeterRow(label: 'Skill', value: member.skill),
            const SizedBox(height: 6),
            MeterRow(label: 'Loyalty', value: member.loyalty),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                MiniAction(
                  label: GameEngine.unaffordable(s.stats.money, GameEngine.bonusCost) ?? 'Pay · \$${GameEngine.bonusCost}',
                  onTap: GameEngine.unaffordable(s.stats.money, GameEngine.bonusCost) == null
                      ? () => c.payBonus(member.personId)
                      : null,
                ),
                MiniAction(label: 'Raise cut', onTap: () => c.bumpCut(member.personId)),
                MiniAction(
                  label: member.assignedBizId == null ? 'Assign' : 'Reassign',
                  onTap: () => c.assignCrew(member.personId),
                ),
                MiniAction(label: 'Let go', danger: true, onTap: () => c.letGo(member.personId)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FrontCard extends StatelessWidget {
  const _FrontCard({required this.c, required this.business});
  final GameController c;
  final Business business;

  @override
  Widget build(BuildContext context) {
    final risk = WorldContent.riskWord(business.cover);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GoldFrame(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SceneArt(Art.businessFront(business.type), height: 100, alignment: const Alignment(0, -0.15)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    business.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'Cinzel', color: Palette.gold, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${WorldContent.frontLabel(business.type)} · ${WorldContent.districtName(business.districtId)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Palette.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      GlanceChip(label: 'Income', value: MoneyText.format(business.yearlyIncome)),
                      GlanceChip(label: 'Risk', value: risk, warn: risk == 'High'),
                      GlanceChip(label: 'Cover', value: '${business.cover}'),
                      GlanceChip(label: 'Value', value: MoneyText.format(business.value)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  MiniAction(
                    label: GameEngine.unaffordable(c.s.stats.money, GameEngine.investCost) ??
                        'Invest · \$${GameEngine.investCost}',
                    onTap: GameEngine.unaffordable(c.s.stats.money, GameEngine.investCost) == null
                        ? () => c.investFront(business.id)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.c});
  final GameController c;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _More('Empire', Art.navEmpire, Art.header('empire'), 'Hire, pay, invest.', () => _open(context, EmpireScreen(c: c)), null, null),
      _More('Activities', Art.icoActivities, Art.header('activities'), 'One extra move.', () => _open(context, ActivitiesPage(c: c)), c.tourKeys.moreActivities, TourAnchor.moreActivities),
      _More('Relations', Art.icoRelations, Art.header('relations'), 'Sit and Gift: one each.', () => _open(context, RelationsPage(c: c)), c.tourKeys.moreRelations, TourAnchor.moreRelations),
      _More('Court', Art.icoCourt, Art.header('court'), 'Heat and prison.', () => _open(context, CourtPage(c: c)), c.tourKeys.moreCourt, TourAnchor.moreCourt),
      _More('Dynasty', Art.icoLegacy, Art.header('legacy'), 'Tree, chair, heirs.', () => _open(context, LegacyPage(c: c)), c.tourKeys.moreLegacy, TourAnchor.moreLegacy),
      _More('Settings', Art.icoSettings, Art.header('settings'), 'Look, music, saves.', () => _open(context, SettingsPage(c: c)), c.tourKeys.moreSettings, TourAnchor.moreSettings),
    ];
    return GridView.count(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.78,
      children: [
        for (final t in tiles)
          Builder(
            builder: (context) {
              final tile = InkWell(
                onTap: () {
                  if (t.anchor != null && c.tourConsume(t.anchor!)) return;
                  t.onTap();
                },
                child: GoldFrame(
                  image: t.art,
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                  child: Column(
                    children: [
                      PixelIcon(t.icon, size: 30),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Text(
                            t.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            softWrap: true,
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              fontFamily: 'Cinzel',
                              fontSize: 15,
                              color: Palette.gold,
                              height: 1.2,
                              letterSpacing: 0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        t.blurb,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.fade,
                        softWrap: true,
                        style: TextStyle(color: Palette.cream, fontSize: 11, height: 1.25),
                      ),
                    ],
                  ),
                ),
              );
              return t.key == null ? tile : KeyedSubtree(key: t.key, child: tile);
            },
          ),
      ],
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

class _More {
  _More(this.label, this.icon, this.art, this.blurb, this.onTap, this.key, this.anchor);
  final String label;
  final String icon;
  final String art;
  final String blurb;
  final VoidCallback onTap;
  final GlobalKey? key;
  final TourAnchor? anchor;
}

class ActivitiesPage extends StatelessWidget {
  const ActivitiesPage({super.key, required this.c});
  final GameController c;

  @override
  Widget build(BuildContext context) {
    final e = c.engine!;
    final acts = e.activities();
    return Scaffold(
      appBar: AppBar(titleSpacing: 4, leadingWidth: 44, title: const ScreenTitle('Activities')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HeaderBanner(
            asset: Art.header('activities'),
            title: 'Activities',
            subtitle: e.state.activityUsed
                ? 'You already used this year\'s extra move.'
                : 'Same extras as Do something on Life. One move per year.',
          ),
          GhostButton(label: 'Watch for a bonus whisper (rewarded)', onTap: c.bonusWhisper),
          const SizedBox(height: 12),
          if (acts.isEmpty)
            EmptyState(
              art: Art.empty('activities'),
              text: 'Nothing fits this year. Next year will open a door.',
              cta: 'Back to Life',
              onTap: () {
                Navigator.pop(context);
                c.setHub(0);
              },
            ),
          for (final a in acts)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GoldFrame(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SceneArt(Art.event(a.art), height: 78),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    Text(a.name, style: TextStyle(fontFamily: 'Cinzel', color: Palette.gold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(a.description, style: TextStyle(height: 1.4)),
                    const SizedBox(height: 8),
                    Text(
                      e.state.activityUsed
                          ? 'Already used this year\'s extra move.'
                          : 'One extra move this year. Outcomes hit harder than they used to.',
                      style: TextStyle(color: Palette.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    PrimaryButton(
                      label: e.state.activityUsed ? 'Already done' : 'Do this',
                      onTap: e.state.activityUsed
                          ? null
                          : () {
                              Navigator.pop(context);
                              c.openActivity(a.id);
                            },
                    ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoirNav extends StatelessWidget {
  const _NoirNav({required this.c, required this.index, required this.onSelect});
  final GameController c;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Art.navLife, 'Life', c.tourKeys.navLife),
      (Art.navFamily, 'Family', c.tourKeys.navFamily),
      (Art.navCity, 'City', c.tourKeys.navCity),
      (Art.navMore, 'More', c.tourKeys.navMore),
    ];
    return Material(
      color: Palette.navy2,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Palette.gold, width: 0.8)),
          ),
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: KeyedSubtree(
                    key: items[i].$3,
                    child: InkWell(
                      onTap: () => onSelect(i),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (i == index)
                            Icon(Icons.diamond, size: 8, color: Palette.gold)
                          else
                            const SizedBox(height: 8),
                          PixelIcon(items[i].$1, size: i == index ? 28 : 24),
                          const SizedBox(height: 4),
                          Text(
                            items[i].$2,
                            style: TextStyle(
                              fontFamily: 'Cinzel',
                              fontSize: 10,
                              color: i == index ? Palette.gold : Palette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class BusinessPage extends StatelessWidget {
  const BusinessPage({super.key, required this.c});
  final GameController c;
  @override
  Widget build(BuildContext context) {
    final s = c.s;
    return Scaffold(
      appBar: AppBar(titleSpacing: 4, leadingWidth: 44, title: const ScreenTitle('Business')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HeaderBanner(
            asset: Art.header('business'),
            title: 'Fronts',
            subtitle: 'A shopfront is a story with a lock on the back door.',
          ),
          if (s.businesses.isEmpty)
            EmptyState(
              art: Art.empty('shop'),
              text: 'No holdings. Play a year and the city may offer a key.',
              cta: 'Back to Life',
              onTap: () {
                Navigator.pop(context);
                c.setHub(0);
              },
            ),
          for (final b in s.businesses) _FrontCard(c: c, business: b),
        ],
      ),
    );
  }
}

class RelationsPage extends StatelessWidget {
  const RelationsPage({super.key, required this.c});
  final GameController c;
  @override
  Widget build(BuildContext context) {
    final s = c.s;
    final rel = s.people.values.where((p) => p.id != s.playerId && p.relation != 'crew').toList();
    return Scaffold(
      appBar: AppBar(titleSpacing: 4, leadingWidth: 44, title: const ScreenTitle('Relations')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HeaderBanner(
            asset: Art.header('relations'),
            title: 'Relationships',
            subtitle: 'Bond and loyalty. Sit one person a year. Gift one person a year. Separate caps.',
          ),
          if (rel.isEmpty)
            EmptyState(
              art: Art.empty('relations'),
              text: 'No one sits across from you yet.',
              cta: 'Open Family',
              onTap: () {
                Navigator.pop(context);
                c.setHub(1);
              },
            ),
          for (final p in rel)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GoldFrame(
                accent: c.engine!.satPersonId() == p.id,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FramedPortrait(person: p, size: 52, year: s.year),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: 'Cinzel', color: Palette.cream),
                          ),
                          Text(
                            '${p.relation} · ${p.lifePath}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Palette.muted, fontSize: 12),
                          ),
                          Text('Bond ${p.bond} · loyalty ${p.loyaltyToFamily}',
                              style: TextStyle(color: Palette.goldSoft, fontSize: 12)),
                          if (p.isAlive) ...[
                            const SizedBox(height: 8),
                            _BondActions(c: c, person: p),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CourtPage extends StatelessWidget {
  const CourtPage({super.key, required this.c});
  final GameController c;
  @override
  Widget build(BuildContext context) {
    final s = c.s;
    return Scaffold(
      appBar: AppBar(titleSpacing: 4, leadingWidth: 44, title: const ScreenTitle('Court')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HeaderBanner(
            asset: Art.header('court'),
            title: s.inPrison ? 'Inside' : 'Free — for now',
            subtitle:
                'Heat ${s.stats.heat}. Lawyer ${s.lawyerQuality}. ${s.inPrison ? '${s.prisonYearsLeft} year${s.prisonYearsLeft == 1 ? '' : 's'} left. Life still plays from here.' : 'Keep heat down or keep a lawyer.'}',
          ),
          if (s.timeline.where((t) => t.category == 'police' || t.category == 'prison').isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: EmptyState(
                art: Art.empty('court'),
                text: 'No warrants in the ink yet. Vale is still a rumor with a badge.',
              ),
            )
          else ...[
            const SectionTitle('Recent legal weather'),
            for (final t in s.timeline.reversed.where((t) => t.category == 'police' || t.category == 'prison').take(12))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${t.year} — ${t.text}', style: TextStyle(fontSize: 13)),
              ),
          ],
        ],
      ),
    );
  }
}

class LegacyPage extends StatelessWidget {
  const LegacyPage({super.key, required this.c});
  final GameController c;
  @override
  Widget build(BuildContext context) {
    final e = c.engine!;
    final s = e.state;
    final heirs = e.eligibleHeirs();
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 4,
        leadingWidth: 44,
        title: const ScreenTitle('Dynasty', size: 22),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HeaderBanner(
            asset: Art.header('legacy'),
            title: 'The ${s.dynastyName} name',
            subtitle: e.inheritBlurb(),
          ),
          GoldFrame(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FramedPortrait(person: s.player, size: 64, year: s.year),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('IN THE CHAIR', style: TextStyle(color: Palette.muted, fontSize: 10, letterSpacing: 1.1)),
                      Text(s.player.name, style: TextStyle(fontFamily: 'Cinzel', color: Palette.gold, fontSize: 18)),
                      Text(
                        'Gen ${s.generation} · age ${s.age} · sat since ${s.leaderStartYear}',
                        style: TextStyle(color: Palette.cream, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'When this life ends you pick who plays next. Cash, fronts, and streets stay. Heat cools. Reputation thins.',
                        style: TextStyle(color: Palette.muted, height: 1.35, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const SectionTitle('If the chair empties'),
          if (heirs.isEmpty)
            EmptyState(
              art: Art.emptyChair,
              text: 'No eligible heir yet. A child, sibling, or cousin of age can take the name. Mentors and foils cannot.',
            )
          else
            for (final p in heirs.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GoldFrame(
                  accent: p.id == heirs.first.id,
                  child: Row(
                    children: [
                      FramedPortrait(person: p, size: 52, year: s.year),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.id == heirs.first.id ? '${p.name}  · first in line' : p.name,
                              style: TextStyle(fontFamily: 'Cinzel', color: Palette.cream, fontSize: 14),
                            ),
                            Text(
                              '${p.relation} · age ${p.ageIn(s.year)} · bond ${p.bond} · loyalty ${p.loyaltyToFamily}',
                              style: TextStyle(color: Palette.muted, fontSize: 12),
                            ),
                            if (p.traits.isNotEmpty)
                              Text(p.traits.join(', '), style: TextStyle(color: Palette.goldSoft, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 8),
          const SectionTitle('The tree'),
          GoldFrame(child: DynastyTreeView(engine: e)),
          const SizedBox(height: 14),
          const SectionTitle('Hall of Legacy'),
          if (s.hall.isEmpty)
            EmptyState(
              art: Art.empty('hall'),
              text: 'The hall is waiting. When you die or retire, this life is carved here and the next generation sits.',
            )
          else
            for (final h in s.hall.reversed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GoldFrame(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gen ${h.generation} · ${h.name}', style: TextStyle(fontFamily: 'Cinzel', color: Palette.gold, fontSize: 16)),
                      Text('${h.startYear}–${h.endYear}  (age ${h.startAge}–${h.endAge}) · ${h.fate}'),
                      const SizedBox(height: 6),
                      Text(h.epitaph, style: TextStyle(color: Palette.cream)),
                      Text('Peak wealth ${h.peakWealth} · peak reputation ${h.peakReputation}',
                          style: TextStyle(color: Palette.muted, fontSize: 12)),
                    ],
                  ),
                ),
              ),
          const SectionTitle('Achievements'),
          for (final a in WorldContent.achievements())
            ListTile(
              dense: true,
              leading: PixelIcon(
                s.achievements.contains(a.id) ? Art.icoLegacy : Art.icoSettings,
                size: 28,
              ),
              title: Text(a.title),
              subtitle: Text(a.description, style: TextStyle(color: Palette.muted)),
            ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.c});
  final GameController c;
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => Scaffold(
      appBar: AppBar(titleSpacing: 4, leadingWidth: 44, title: const ScreenTitle('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HeaderBanner(
            asset: Art.header('settings'),
            title: 'Settings',
            subtitle: 'Look, music, sound, saves, and ads. All of it stays on this device.',
          ),
          SwitchListTile(
            value: c.darkMode,
            onChanged: (_) => c.toggleDarkMode(),
            title: const Text('Dark mode'),
            subtitle: Text(c.darkMode
                ? 'Neo-noir navy. Night is the default. Paper is optional.'
                : 'Soft paper. One tap returns you to night.'),
            activeThumbColor: Palette.gold,
          ),
          SwitchListTile(
            value: c.musicOn,
            onChanged: (_) => c.toggleMusic(),
            title: const Text('Music'),
            subtitle: const Text('Quiet neo-noir loop'),
            activeThumbColor: Palette.gold,
          ),
          if (c.musicOn)
            Slider(
              value: c.audio.musicVolume,
              onChanged: c.setMusicVol,
              activeColor: Palette.gold,
            ),
          SwitchListTile(
            value: c.sfxOn,
            onChanged: (_) => c.toggleSfx(),
            title: const Text('Sound'),
            subtitle: const Text('Taps, choices, years, heat'),
            activeThumbColor: Palette.gold,
          ),
          if (c.sfxOn)
            Slider(
              value: c.audio.sfxVolume,
              onChanged: c.setSfxVol,
              activeColor: Palette.gold,
            ),
          Divider(color: Palette.line),
          const SectionTitle('The shop'),
          Text(
            'No banners. The city already has enough neon. Remove Ads is a one-time ledger entry: '
            'com.vicedynasty.life.remove_ads. Interstitials only at a generation end or a major jail door. Rewarded ads stay optional for rewriting a bad night.',
            style: TextStyle(color: Palette.muted, height: 1.4),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: c.ads.adsRemoved ? 'Ads already removed' : 'Remove ads',
            onTap: c.ads.adsRemoved ? null : c.buyRemoveAds,
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 8),
            GhostButton(label: 'Debug: grant remove ads', onTap: c.grantRemoveAds),
          ],
          const SizedBox(height: 16),
          const SectionTitle('Save slots'),
          for (var i = 1; i <= 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GhostButton(
                label: 'Save to slot $i',
                onTap: () async {
                  await c.persist(slot: i);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Wrote slot $i')));
                  }
                },
              ),
            ),
          GhostButton(label: 'Back to title', onTap: c.goTitle),
          const SizedBox(height: 16),
          Text('Vice Dynasty 1.9.3', textAlign: TextAlign.center, style: TextStyle(color: Palette.muted, fontSize: 12)),
        ],
      ),
    ),
    );
  }
}
