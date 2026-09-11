import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../art.dart';
import '../engine/catalog.dart';
import '../game_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key, required this.c});
  final GameController c;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(Art.splash, fit: BoxFit.cover, errorBuilder: (_, _, _) => const _RainBg()),
          const _RainBg(transparent: true),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: Palette.light
                    ? [
                        const Color(0xFFE8E4DC).withValues(alpha: 0.22),
                        const Color(0xFFE8E4DC).withValues(alpha: 0.78),
                        const Color(0xFFE8E4DC).withValues(alpha: 0.97),
                      ]
                    : [
                        Palette.navy.withValues(alpha: 0.15),
                        Palette.navy.withValues(alpha: 0.55),
                        Palette.navy.withValues(alpha: 0.92),
                      ],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final compact = box.maxHeight < 680;
                return Padding(
                  padding: EdgeInsets.fromLTRB(22, compact ? 10 : 16, 22, compact ? 10 : 14),
                  child: Column(
                    children: [
                      Expanded(
                        child: GoldFrame(
                          padding: const EdgeInsets.all(6),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFF070B14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(
                                    Art.titlePoster,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.center,
                                    filterQuality: FilterQuality.medium,
                                    errorBuilder: (_, _, _) => Image.asset(
                                      Art.splash,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFF0B1220)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 12),
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'VICE DYNASTY',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontFamily: 'Cinzel',
                                  fontSize: compact ? 26 : 32,
                                  color: Palette.gold,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: compact ? 0.8 : 1.4,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'CRIME LIFE SIMULATOR',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontFamily: 'DMSans',
                                  letterSpacing: compact ? 1.4 : 2.2,
                                  fontSize: 11,
                                  color: Palette.cream,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 12),
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Ravenport. One year. One choice. A name that outlives you.',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.visible,
                            style: TextStyle(color: Palette.cream.withValues(alpha: 0.86), height: 1.35, fontSize: 13),
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 10 : 16),
                      PrimaryButton(label: 'NEW GAME', onTap: c.goNew),
                      SizedBox(height: compact ? 8 : 10),
                      FutureBuilder(
                        future: c.saves.read(0),
                        builder: (context, snap) {
                          final has = snap.data != null;
                          return GhostButton(
                            label: has ? 'Continue' : 'Continue (no save yet)',
                            onTap: has ? () => c.loadSlot(0) : null,
                          );
                        },
                      ),
                      SizedBox(height: compact ? 8 : 10),
                      GhostButton(label: 'Load', onTap: c.goLoad),
                      SizedBox(height: compact ? 8 : 10),
                      GhostButton(label: 'Watch opening', onTap: c.replayOpening),
                      SizedBox(height: compact ? 8 : 12),
                      Text(
                        'Offline · Saves on this device · 1.9.11',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Palette.muted, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RainBg extends StatelessWidget {
  const _RainBg({this.transparent = false});
  final bool transparent;
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _RainPainter(transparent), size: Size.infinite);
  }
}

class _RainPainter extends CustomPainter {
  _RainPainter(this.transparent);
  final bool transparent;

  @override
  void paint(Canvas canvas, Size size) {
    if (!transparent) {
      canvas.drawRect(Offset.zero & size, Paint()..color = Palette.navy);
    }
    final rain = Paint()
      ..color = Palette.cream.withValues(alpha: transparent ? 0.12 : 0.18)
      ..strokeWidth = 1;
    for (var i = 0; i < 48; i++) {
      final x = (i * 37) % size.width;
      final y = (i * 53) % size.height;
      canvas.drawLine(Offset(x, y), Offset(x + 4, y + 18), rain);
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter old) =>
      old.transparent != transparent || old._light != _light;

  final bool _light = Palette.light;
}

class NewGameScreen extends StatefulWidget {
  const NewGameScreen({super.key, required this.c});
  final GameController c;
  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  final first = TextEditingController();
  final last = TextEditingController();
  String gender = 'man';
  final picked = <String>{};

  @override
  void initState() {
    super.initState();
    first.addListener(() => setState(() {}));
    last.addListener(() => setState(() {}));
  }

  bool get _ready =>
      first.text.trim().isNotEmpty && last.text.trim().isNotEmpty && picked.length == 2;

  @override
  void dispose() {
    first.dispose();
    last.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Palette.gold), onPressed: widget.c.goTitle),
        title: ScreenTitle('New game'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Text(
              'Name yourself, pick two traits, then Start. 1998. Eighteen. A year at a time.',
              style: TextStyle(color: Palette.muted, height: 1.4)),
          const SizedBox(height: 12),
          TextField(
            controller: first,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [LengthLimitingTextInputFormatter(16)],
            style: TextStyle(color: Palette.cream),
            decoration: _dec('First name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: last,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [LengthLimitingTextInputFormatter(16)],
            style: TextStyle(color: Palette.cream),
            decoration: _dec('Family name'),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                first.text = 'Julian';
                last.text = 'Hart';
                setState(() {
                  gender = 'man';
                  picked
                    ..clear()
                    ..add('Ambitious')
                    ..add('Cunning');
                });
              },
              child: Text('Fill a sample character', style: TextStyle(color: Palette.goldSoft)),
            ),
          ),
          const SectionTitle('Look'),
          Wrap(
            spacing: 8,
            children: [
              for (final g in ['man', 'woman', 'nonbinary'])
                ChoiceChip(
                  label: Text(g == 'nonbinary' ? 'Nonbinary' : (g[0].toUpperCase() + g.substring(1))),
                  selected: gender == g,
                  onSelected: (_) => setState(() => gender = g),
                  selectedColor: Palette.gold,
                  labelStyle: TextStyle(color: gender == g ? Palette.onGold : Palette.cream),
                  backgroundColor: Palette.charcoal,
                ),
            ],
          ),
          const SizedBox(height: 16),
          const SectionTitle('Two traits'),
          Text('Pick two. They open and close choices later.',
              style: TextStyle(color: Palette.muted, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in WorldContent.traits)
                FilterChip(
                  label: Text(t),
                  selected: picked.contains(t),
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        if (picked.length >= 2) picked.remove(picked.first);
                        picked.add(t);
                      } else {
                        picked.remove(t);
                      }
                    });
                  },
                  selectedColor: Palette.red,
                  labelStyle: TextStyle(color: picked.contains(t) ? Palette.onGold : Palette.muted),
                  backgroundColor: Palette.charcoal,
                ),
            ],
          ),
          const SizedBox(height: 8),
          GhostButton(
            label: 'Roll two traits',
            onTap: () {
              final pool = List<String>.of(WorldContent.traits)..shuffle();
              setState(() {
                picked
                  ..clear()
                  ..add(pool[0])
                  ..add(pool[1]);
              });
            },
          ),
        ],
        ),
            ),
          ),
          Material(
            color: Palette.navy2,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: KeyedSubtree(
                  key: widget.c.tourKeys.newGame,
                  child: PrimaryButton(
                    label: _ready ? 'Start' : 'Name + 2 traits to start',
                    onTap: _ready
                        ? () => widget.c.startNewGame(
                              first: first.text,
                              last: last.text,
                              gender: gender,
                              traits: picked.toList(),
                            )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Palette.muted),
        filled: true,
        fillColor: Palette.card,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Palette.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Palette.gold),
        ),
      );
}

class LoadScreen extends StatefulWidget {
  const LoadScreen({super.key, required this.c});
  final GameController c;
  @override
  State<LoadScreen> createState() => _LoadScreenState();
}

class _LoadScreenState extends State<LoadScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back, color: Palette.gold), onPressed: widget.c.goTitle),
        title: const ScreenTitle('Load'),
      ),
      body: FutureBuilder(
        future: widget.c.saves.list(),
        builder: (context, snap) {
          final list = snap.data;
          if (list == null) {
            return Center(child: CircularProgressIndicator(color: Palette.gold));
          }
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              SceneArt(Art.cover, height: 110),
              const SizedBox(height: 14),
              Text('Pick a save.', style: TextStyle(color: Palette.muted, height: 1.4)),
              const SizedBox(height: 12),
              if (list.every((e) => e == null))
                EmptyState(
                  art: Art.empty('ledger'),
                  text: 'No saves on this device yet. Start a new game.',
                ),
              for (var i = 0; i < list.length; i++)
                if (list[i] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GoldFrame(
                      image: Art.event('ledger'),
                      child: ListTile(
                        title: Text(
                          i == 0 ? 'Autosave · ${list[i]!.dynasty}' : list[i]!.dynasty,
                          style: TextStyle(fontFamily: 'Cinzel', color: Palette.gold),
                        ),
                        subtitle: Text(list[i]!.label, style: TextStyle(color: Palette.muted)),
                        trailing: const PixelIcon(Art.icoLegacy, size: 22),
                        onTap: () => widget.c.loadSlot(i),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(i == 0 ? 'Autosave — none yet' : 'Slot $i — none yet',
                        style: TextStyle(color: Palette.muted, fontSize: 13)),
                  ),
            ],
          );
        },
      ),
    );
  }
}
