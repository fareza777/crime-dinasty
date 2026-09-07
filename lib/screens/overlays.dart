import 'package:flutter/material.dart';

import '../art.dart';
import '../engine/catalog.dart';
import '../engine/game_engine.dart';
import '../game_controller.dart';
import '../models/event_models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class EventLayer extends StatelessWidget {
  const EventLayer({super.key, required this.c});
  final GameController c;

  @override
  Widget build(BuildContext context) {
    final e = c.engine!;
    final ev = e.currentEvent()!;
    final choices = e.choicesFor(ev);
    final short = MediaQuery.sizeOf(context).height < 740;
    return Material(
      color: Palette.scrim,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: KeyedSubtree(
            key: c.tourKeys.choice,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.96, end: 1),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height - 28),
                  child: GoldFrame(
                    image: Art.choice,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(ev.category.toUpperCase(),
                              style: TextStyle(color: Palette.muted, letterSpacing: 1.4, fontSize: 11)),
                          const SizedBox(height: 8),
                          SceneArt(Art.event(ev.art), height: short ? 124 : 156, textured: true),
                          const SizedBox(height: 8),
                          Text(ev.title, style: TextStyle(fontFamily: 'Cinzel', color: Palette.gold, fontSize: 21, height: 1.2)),
                          const SizedBox(height: 8),
                          NarrativePanel(ev.body, fontSize: 14.5),
                          const SizedBox(height: 10),
                          for (final ch in choices) ...[
                            PrimaryButton(
                              label: _choiceLabel(c, e, ev, ch),
                              color: !ch.enabled
                                  ? Palette.charcoal
                                  : (_isSuggested(c, e, ev, ch) ? Palette.gold : Palette.goldSoft),
                              onTap: ch.enabled ? () => c.choose(ch.choice.id) : null,
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class OutcomeLayer extends StatelessWidget {
  const OutcomeLayer({super.key, required this.c});
  final GameController c;

  @override
  Widget build(BuildContext context) {
    final o = c.lastOutcome!;
    final harsh = o.isHarsh;
    final heat = (o.stats['heat'] ?? 0) >= 8;
    final cash = o.stats['money'] ?? 0;
    final win = !harsh && cash >= 400;
    final e = c.engine!;
    return Material(
      color: Palette.scrim,
      child: Stack(
        children: [
          if (heat || harsh || win || o.id == 'sit' || o.id == 'heir_rise')
            Positioned.fill(child: NoirBurst(heat: heat || harsh)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.92, end: 1),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                child: GoldFrame(
                image: o.id == 'sit'
                    ? Art.event('sit')
                    : (o.id == 'heir_rise'
                        ? Art.emptyChair
                        : (heat ? Art.event('crime_night') : Art.panel)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                        o.id == 'sit'
                            ? 'A quiet hour'
                            : (o.id == 'heir_rise'
                                ? 'A new generation'
                                : (harsh ? 'That went badly' : (win ? 'Paid and done' : 'What happened'))),
                        style: TextStyle(color: harsh ? Palette.redSoft : Palette.gold, letterSpacing: 0.6, fontSize: 12)),
                    if (heat) ...[
                      const SizedBox(height: 6),
                      Text('HEAT SPIKE', style: TextStyle(color: Palette.redSoft.withValues(alpha: 0.9), letterSpacing: 2, fontSize: 10)),
                    ],
                    if (win) ...[
                      const SizedBox(height: 6),
                      Text('CLEAN TAKE', style: TextStyle(color: Palette.goldSoft.withValues(alpha: 0.95), letterSpacing: 2, fontSize: 10)),
                    ],
                const SizedBox(height: 8),
                Text(o.title, style: TextStyle(fontFamily: 'Cinzel', fontSize: 22, color: Palette.cream)),
                const SizedBox(height: 10),
                NarrativePanel(o.body),
                if (o.stats.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final s in o.stats.entries.where((e) => e.value != 0))
                        GlanceChip(
                          label: s.key == 'money' ? 'Cash' : s.key,
                          value: '${s.value > 0 ? '+' : ''}${s.key == 'money' ? MoneyText.format(s.value) : s.value}',
                          warn: s.value < 0 || s.key == 'heat' && s.value > 0,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                PrimaryButton(label: 'OK', onTap: c.dismissOutcome),
                if (harsh && !e.state.retryUsed && e.state.lastChoiceId != null) ...[
                  const SizedBox(height: 8),
                  GhostButton(
                    label: 'Try that choice again (ad)',
                    onTap: () {
                      c.dismissOutcome();
                      c.retryDecision();
                    },
                  ),
                ],
              ],
            ),
          ),
                ),
        ),
          ),
        ],
      ),
    );
  }
}

class SummaryLayer extends StatelessWidget {
  const SummaryLayer({super.key, required this.c});
  final GameController c;

  @override
  Widget build(BuildContext context) {
    final s = c.s;
    return Material(
      color: Palette.scrim,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: GoldFrame(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SceneArt(Art.yearBanner, height: 56),
                const SizedBox(height: 10),
                Text(s.yearHeadline.isEmpty ? 'YEAR ${s.year}' : s.yearHeadline,
                    style: TextStyle(fontFamily: 'Cinzel', color: Palette.gold, fontSize: 18, height: 1.3)),
                Text('Age ${s.age} · Generation ${s.generation}', style: TextStyle(color: Palette.muted)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: ListView(
                    children: [
                      if (s.lastYearLog.isEmpty)
                        const Text('The rain kept its appointment. So did you.'),
                      for (final line in s.lastYearLog)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('· $line'),
                        ),
                    ],
                  ),
                ),
                  PrimaryButton(label: 'Turn the page', onTap: c.continueYear),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HeirLayer extends StatelessWidget {
  const HeirLayer({super.key, required this.c});
  final GameController c;

  @override
  Widget build(BuildContext context) {
    final e = c.engine!;
    final heirs = e.eligibleHeirs();
    return Material(
      color: Palette.navy.withValues(alpha: 0.94),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SceneArt(Art.emptyChair, height: 120),
              const SizedBox(height: 12),
              Text('The chair is empty',
                  style: TextStyle(fontFamily: 'Cinzel', color: Palette.gold, fontSize: 22, letterSpacing: 0.4)),
              const SizedBox(height: 8),
              Text(
                '${e.state.heirReason ?? 'This life ended.'} ${e.inheritBlurb()}',
                style: TextStyle(color: Palette.muted, height: 1.4),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    if (heirs.isEmpty) const EmptyHint('No heir. The dynasty ends here.'),
                    for (final p in heirs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GoldFrame(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  FramedPortrait(person: p, size: 56, year: e.state.year),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${p.name}\n${p.relation} · age ${p.ageIn(e.state.year)} · ${p.lifePath}\n${p.traits.join(', ')}',
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(height: 1.3),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              PrimaryButton(label: 'Play as ${p.firstName}', onTap: () => c.pickHeir(p.id)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EndingLayer extends StatelessWidget {
  const EndingLayer({super.key, required this.c});
  final GameController c;
  @override
  Widget build(BuildContext context) {
    final id = c.s.endingId ?? 'bloodline_ends';
    final pair = WorldContent.endings[id] ??
        const ['A Closed Ledger', 'The rain keeps the last copy. The Hall keeps the chair.'];
    return Material(
      color: Palette.navy,
      child: Stack(
        children: [
          const Positioned.fill(child: NoirBurst()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SceneArt(Art.hall, height: 160),
                  const SizedBox(height: 16),
                  const Spacer(),
                  Text(pair[0],
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Cinzel', color: Palette.gold, fontSize: 26, height: 1.25)),
                  const SizedBox(height: 12),
                  Text(pair[1], textAlign: TextAlign.center, style: TextStyle(height: 1.45, color: Palette.cream)),
                  const Spacer(),
                  PrimaryButton(label: 'Back to menu', onTap: c.goTitle),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isSuggested(GameController c, GameEngine e, EventDef ev, ChoiceView ch) {
  if (!(c.coachActive || e.guidedStart)) return false;
  return e.suggestedChoiceId(ev) == ch.choice.id;
}

String _choiceLabel(GameController c, GameEngine e, EventDef ev, ChoiceView ch) {
  final base = ch.enabled ? ch.choice.text : '${ch.choice.text}  (${ch.reason})';
  if (ch.enabled && _isSuggested(c, e, ev, ch)) return 'Suggested — $base';
  return base;
}
