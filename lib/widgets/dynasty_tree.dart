import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_models.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Groups living and dead people into a readable genealogy for the Dynasty page.
class DynastyTreeLayout {
  DynastyTreeLayout({
    required this.elders,
    required this.peers,
    required this.children,
    required this.orbit,
    required this.heirIds,
    required this.firstHeirId,
    required this.chairId,
  });

  final List<Person> elders;
  final List<Person> peers;
  final List<Person> children;
  final List<Person> orbit;
  final Set<String> heirIds;
  final String? firstHeirId;
  final String chairId;

  static DynastyTreeLayout from(GameEngine e) {
    final s = e.state;
    final player = s.player;
    final heirs = e.eligibleHeirs();
    final placed = <String>{};

    final elders = <Person>[];
    final peers = <Person>[];
    final children = <Person>[];
    final orbit = <Person>[];

    void take(Person p, List<Person> into) {
      if (placed.contains(p.id)) return;
      placed.add(p.id);
      into.add(p);
    }

    take(player, peers);

    for (final p in s.people.values) {
      if (p.id == player.id) continue;
      if (p.parentId == player.id ||
          p.otherParentId == player.id ||
          p.relation == 'child' ||
          p.relation == 'heir') {
        take(p, children);
      }
    }
    for (final p in s.people.values) {
      if (placed.contains(p.id)) continue;
      if (p.spouseId == player.id || p.relation == 'spouse' || p.relation == 'sibling') {
        take(p, peers);
      }
    }
    for (final p in s.people.values) {
      if (placed.contains(p.id)) continue;
      if (p.id == player.parentId ||
          p.id == player.otherParentId ||
          p.relation == 'parent' ||
          p.relation == 'mentor') {
        take(p, elders);
      }
    }
    for (final p in s.people.values) {
      if (!placed.contains(p.id)) take(p, orbit);
    }

    int byName(Person a, Person b) => a.firstName.compareTo(b.firstName);
    elders.sort(byName);
    peers.sort((a, b) {
      if (a.id == player.id) return -1;
      if (b.id == player.id) return 1;
      return byName(a, b);
    });
    children.sort(byName);
    orbit.sort(byName);

    return DynastyTreeLayout(
      elders: elders,
      peers: peers,
      children: children,
      orbit: orbit,
      heirIds: heirs.map((p) => p.id).toSet(),
      firstHeirId: heirs.isEmpty ? null : heirs.first.id,
      chairId: s.playerId,
    );
  }
}

class DynastyTreeView extends StatelessWidget {
  const DynastyTreeView({super.key, required this.engine});
  final GameEngine engine;

  @override
  Widget build(BuildContext context) {
    final layout = DynastyTreeLayout.from(engine);
    final year = engine.state.year;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (layout.elders.isNotEmpty) ...[
          const _GenLabel('Elders'),
          _GenRow(people: layout.elders, layout: layout, year: year),
          _ConnectorBar(fromCount: layout.elders.length, toCount: layout.peers.length),
        ],
        const _GenLabel('The chair'),
        _GenRow(people: layout.peers, layout: layout, year: year),
        if (layout.children.isNotEmpty) ...[
          _ConnectorBar(fromCount: layout.peers.length, toCount: layout.children.length),
          const _GenLabel('The next names'),
          _GenRow(people: layout.children, layout: layout, year: year),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No children on the tree yet. A birth writes a new row.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Palette.muted, fontSize: 12, height: 1.35),
            ),
          ),
        if (layout.orbit.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('THE CIRCLE', style: TextStyle(color: Palette.muted, fontSize: 10, letterSpacing: 1.1)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final p in layout.orbit) _TreeNode(person: p, layout: layout, year: year, compact: true),
            ],
          ),
        ],
      ],
    );
  }
}

class _GenLabel extends StatelessWidget {
  const _GenLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        textAlign: TextAlign.center,
        style: TextStyle(color: Palette.muted, fontSize: 10, letterSpacing: 1.2),
      ),
    );
  }
}

class _GenRow extends StatelessWidget {
  const _GenRow({required this.people, required this.layout, required this.year});
  final List<Person> people;
  final DynastyTreeLayout layout;
  final int year;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in people)
          Expanded(
            child: _TreeNode(person: p, layout: layout, year: year),
          ),
      ],
    );
  }
}

class _TreeNode extends StatelessWidget {
  const _TreeNode({
    required this.person,
    required this.layout,
    required this.year,
    this.compact = false,
  });
  final Person person;
  final DynastyTreeLayout layout;
  final int year;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final chair = person.id == layout.chairId;
    final heir = person.id == layout.firstHeirId;
    final inLine = layout.heirIds.contains(person.id);
    final dead = !person.isAlive;
    final size = compact ? 48.0 : 56.0;
    final status = dead
        ? 'dead'
        : (chair
            ? 'chair'
            : (heir
                ? 'heir'
                : (inLine ? 'in line' : person.relation.replaceAll('_', ' '))));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: chair || heir
                  ? Palette.gold.withValues(alpha: 0.92)
                  : (dead ? Palette.muted.withValues(alpha: 0.35) : Palette.gold.withValues(alpha: 0.28)),
              width: chair || heir ? 1.7 : 1,
            ),
            boxShadow: chair || heir
                ? [BoxShadow(color: Palette.gold.withValues(alpha: 0.28), blurRadius: 10)]
                : null,
          ),
          child: FramedPortrait(person: person, size: size, year: year, dead: dead),
        ),
        const SizedBox(height: 4),
        Text(
          person.firstName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Cinzel',
            fontSize: compact ? 11 : 12,
            color: chair ? Palette.gold : (dead ? Palette.muted : Palette.cream),
          ),
        ),
        Text(
          status,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: heir ? Palette.goldSoft : Palette.muted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _ConnectorBar extends StatelessWidget {
  const _ConnectorBar({required this.fromCount, required this.toCount});
  final int fromCount;
  final int toCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: CustomPaint(
        painter: _TreeConnectorPainter(fromCount: fromCount, toCount: toCount),
        size: const Size(double.infinity, 26),
      ),
    );
  }
}

class _TreeConnectorPainter extends CustomPainter {
  _TreeConnectorPainter({required this.fromCount, required this.toCount});
  final int fromCount;
  final int toCount;

  @override
  void paint(Canvas canvas, Size size) {
    if (fromCount <= 0 || toCount <= 0 || size.width <= 0) return;
    final gold = Paint()
      ..color = Palette.gold.withValues(alpha: 0.72)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final midY = size.height * 0.5;
    double xFor(int i, int n) => size.width * (i + 0.5) / n;

    final fromXs = [for (var i = 0; i < fromCount; i++) xFor(i, fromCount)];
    final toXs = [for (var i = 0; i < toCount; i++) xFor(i, toCount)];
    final left = [...fromXs, ...toXs].reduce((a, b) => a < b ? a : b);
    final right = [...fromXs, ...toXs].reduce((a, b) => a > b ? a : b);

    for (final x in fromXs) {
      canvas.drawLine(Offset(x, 0), Offset(x, midY), gold);
    }
    canvas.drawLine(Offset(left, midY), Offset(right, midY), gold);
    for (final x in toXs) {
      canvas.drawLine(Offset(x, midY), Offset(x, size.height), gold);
    }
  }

  @override
  bool shouldRepaint(covariant _TreeConnectorPainter old) =>
      old.fromCount != fromCount || old.toCount != toCount || old._light != _light;

  final bool _light = Palette.light;
}
