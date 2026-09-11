import 'dart:math';

import 'package:flutter/material.dart';

import '../art.dart';
import '../models/game_models.dart';
import '../theme/app_theme.dart';

class PixelIcon extends StatelessWidget {
  const PixelIcon(this.asset, {super.key, this.size = 28});
  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => CustomPaint(
        size: Size.square(size),
        painter: _GoldMarkPainter(),
      ),
    );
  }
}

class SceneArt extends StatelessWidget {
  const SceneArt(
    this.asset, {
    super.key,
    this.height = 140,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.textured = false,
    this.grade,
  });
  final String asset;
  final double height;
  final BoxFit fit;
  final Alignment alignment;
  final bool textured;
  final ColorFilter? grade;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColorFiltered(
              colorFilter: grade ?? const ColorFilter.mode(Colors.transparent, BlendMode.dst),
              child: Image.asset(
                asset,
                fit: fit,
                alignment: alignment,
                errorBuilder: (_, _, _) => CustomPaint(
                  painter: _RainFallbackPainter(),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            if (textured && !Palette.light)
              Opacity(
                opacity: 0.22,
                child: Image.asset(
                  Art.eventPanel,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: Palette.light ? 0.04 : 0.12),
                    Colors.transparent,
                    Palette.navy.withValues(alpha: Palette.light ? 0.18 : 0.38),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GoldFrame extends StatelessWidget {
  const GoldFrame({
    super.key,
    required this.child,
    this.padding,
    this.image,
    this.accent = false,
    this.rim,
  });
  final Widget child;
  final EdgeInsets? padding;
  final String? image;
  final bool accent;
  final Color? rim;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (rim ?? Palette.gold).withValues(alpha: accent || rim != null ? 0.88 : 0.5), width: accent || rim != null ? 1.7 : 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Palette.light ? 0.08 : 0.4),
            blurRadius: Palette.light ? 10 : 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(color: Palette.gold.withValues(alpha: accent ? 0.2 : 0.06), blurRadius: accent ? 18 : 10),
        ],
        image: Palette.light
            ? null
            : DecorationImage(
                image: AssetImage(image ?? Art.panel),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Palette.navy.withValues(alpha: image == null ? 0.78 : 0.58),
                  BlendMode.darken,
                ),
              ),
      ),
      padding: padding ?? const EdgeInsets.all(14),
      child: child,
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.expand = true,
  });
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final btn = AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: onTap == null ? 0.45 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              color: color ?? Palette.gold,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Palette.goldSoft.withValues(alpha: 0.55), width: 1.2),
              image: DecorationImage(
                image: AssetImage(color == Palette.red ? Art.btnDanger : Art.btnPrimary),
                fit: BoxFit.cover,
                opacity: 0.38,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    color: Palette.onGold,
                    letterSpacing: 0.2,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, required this.onTap, this.expand = true});
  final String label;
  final VoidCallback? onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final btn = OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Palette.cream,
        side: BorderSide(color: Palette.line),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Art.btnGhost),
            fit: BoxFit.cover,
            opacity: Palette.light ? 0.14 : 0.32,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class StatChip extends StatelessWidget {
  const StatChip({super.key, required this.label, required this.value, this.warn = false, this.statKey});
  final String label;
  final int value;
  final bool warn;
  final String? statKey;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Palette.navy2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: warn ? Palette.red : Palette.line, width: warn ? 1.6 : 1),
        boxShadow: warn ? [BoxShadow(color: Palette.redSoft.withValues(alpha: 0.28), blurRadius: 8)] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PixelIcon(Art.stat(statKey ?? label), size: 16),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: TextStyle(fontSize: 9, color: Palette.muted, letterSpacing: 0.6)),
              Text('$value', style: TextStyle(fontWeight: FontWeight.w700, color: warn ? Palette.redSoft : Palette.cream)),
            ],
          ),
        ],
      ),
    );
  }
}

class FramedPortrait extends StatelessWidget {
  const FramedPortrait({super.key, required this.person, this.size = 56, this.year, this.dead});
  final Person person;
  final double size;
  final int? year;
  final bool? dead;

  @override
  Widget build(BuildContext context) {
    final gone = dead ?? !person.isAlive;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(Art.dossier, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
          Padding(
            padding: EdgeInsets.all(size * 0.12),
            child: PixelPortrait(person: person, size: size * 0.76, year: year, dead: gone),
          ),
        ],
      ),
    );
  }
}

class PixelPortrait extends StatelessWidget {
  const PixelPortrait({super.key, required this.person, this.size = 56, this.year, this.dead = false});
  final Person person;
  final double size;
  final int? year;
  final bool dead;

  @override
  Widget build(BuildContext context) {
    Widget face = Image.asset(
      Art.portraitFor(person, year: year ?? 1998),
      width: size,
      height: size,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, _, _) => CustomPaint(
        size: Size.square(size),
        painter: _PortraitPainter(person.portraitSeed, dead, person.gender, person.relation),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: ColorFiltered(
        colorFilter: dead
            ? const ColorFilter.mode(Color(0xAA0B1220), BlendMode.saturation)
            : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
        child: face,
      ),
    );
  }
}

class _PortraitPainter extends CustomPainter {
  _PortraitPainter(this.seed, this.dead, this.gender, this.relation);
  final int seed;
  final bool dead;
  final String gender;
  final String relation;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    const n = 14;
    final cell = size.width / n;
    final skin = [
      const Color(0xFFC4A484),
      const Color(0xFF8D6E4C),
      const Color(0xFFE2C7A6),
      const Color(0xFF6B4A32),
      const Color(0xFF4A2F22),
      const Color(0xFFD7B08C),
    ][rng.nextInt(6)];
    final hair = [
      const Color(0xFF1A1A1A),
      const Color(0xFF3B2A1A),
      const Color(0xFFC9A227),
      const Color(0xFF4A5568),
      const Color(0xFFE8E4D9),
      const Color(0xFF8B1E3F),
      const Color(0xFFB4532A),
    ][rng.nextInt(7)];
    final coat = [
      Palette.charcoal,
      Palette.navy2,
      Palette.red,
      const Color(0xFF243044),
      const Color(0xFF3A2A1A),
    ][rng.nextInt(5)];
    final wide = relation == 'crew' || gender == 'man' && rng.nextBool();
    final beard = gender == 'man' && (relation == 'mentor' || relation == 'parent' || rng.nextInt(3) == 0);
    final glasses = relation == 'sibling' || relation == 'foil' || rng.nextInt(4) == 0;
    final longHair = gender == 'woman' || relation == 'matriarch';
    final x0 = wide ? 2 : 3;
    final x1 = wide ? 11 : 10;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        Color? c;
        if (y >= 10) {
          c = coat;
        } else if (y >= 4 && x >= x0 && x <= x1) {
          c = skin;
        } else if (y <= (longHair ? 6 : 4) && x >= x0 - 1 && x <= x1 + 1) {
          c = hair;
        }
        if (beard && y >= 8 && y <= 10 && x >= 5 && x <= 8) c = hair;
        if (c != null) {
          final p = Paint()..color = dead ? c.withValues(alpha: 0.35) : c;
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), p);
        }
      }
    }
    final eye = Paint()..color = dead ? Palette.muted : Palette.navy;
    canvas.drawRect(Rect.fromLTWH(4 * cell, 6 * cell, cell, cell), eye);
    canvas.drawRect(Rect.fromLTWH(8 * cell, 6 * cell, cell, cell), eye);
    if (glasses) {
      final g = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Palette.gold;
      canvas.drawRect(Rect.fromLTWH(3.5 * cell, 5.5 * cell, 2.2 * cell, 2 * cell), g);
      canvas.drawRect(Rect.fromLTWH(7.3 * cell, 5.5 * cell, 2.2 * cell, 2 * cell), g);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Palette.gold.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant _PortraitPainter old) =>
      old.seed != seed || old.dead != dead || old.gender != gender || old.relation != relation;
}

class MoneyText extends StatelessWidget {
  const MoneyText(this.value, {super.key, this.size = 16});
  final int value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      _fmt(value),
      style: TextStyle(fontFamily: 'Cinzel', color: Palette.goldSoft, fontSize: size, fontWeight: FontWeight.w600),
    );
  }

  static String format(int n) => _fmt(n);

  static String _fmt(int n) {
    final s = n.abs().toString();
    final buf = StringBuffer(n < 0 ? '-' : '');
    buf.write('\$');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.text, {super.key, this.size = 20});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: TextStyle(
            fontFamily: 'Cinzel',
            color: Palette.gold,
            fontSize: size,
            height: 1.15,
            letterSpacing: 0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Container(width: 14, height: 1.2, color: Palette.gold.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: TextStyle(fontFamily: 'Cinzel', color: Palette.gold, fontSize: 16, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

class MeterRow extends StatelessWidget {
  const MeterRow({super.key, required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0, 100);
    return Row(
      children: [
        SizedBox(
          width: 54,
          child: Text(label, style: TextStyle(color: Palette.muted, fontSize: 11)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: v / 100,
              minHeight: 7,
              backgroundColor: Palette.navy2,
              color: Palette.goldSoft,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            '$v',
            textAlign: TextAlign.right,
            style: TextStyle(color: Palette.cream, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class GlanceChip extends StatelessWidget {
  const GlanceChip({super.key, required this.label, required this.value, this.warn = false});
  final String label;
  final String value;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.navy2.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: warn ? Palette.redSoft : Palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(), style: TextStyle(color: Palette.muted, fontSize: 9, letterSpacing: 0.6)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: warn ? Palette.redSoft : Palette.cream, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class MiniAction extends StatelessWidget {
  const MiniAction({super.key, required this.label, required this.onTap, this.danger = false, this.icon});
  final String label;
  final VoidCallback? onTap;
  final bool danger;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final color = danger ? Palette.redSoft : Palette.gold;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 36),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.55)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              PixelIcon(icon!, size: 14),
              const SizedBox(width: 4),
            ],
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class NarrativePanel extends StatelessWidget {
  const NarrativePanel(this.text, {super.key, this.fontSize = 15, this.serif = false, this.align = TextAlign.left});
  final String text;
  final double fontSize;
  final bool serif;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Palette.light ? const Color(0xFFF7F3EA) : Palette.card.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.line.withValues(alpha: Palette.light ? 0.9 : 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Text(
          text,
          textAlign: align,
          style: TextStyle(
            fontFamily: serif ? 'Cinzel' : 'DMSans',
            color: Palette.cream,
            height: 1.45,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}

class HeaderBanner extends StatelessWidget {
  const HeaderBanner({super.key, required this.asset, required this.title, this.subtitle});
  final String asset;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final short = MediaQuery.sizeOf(context).height < 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SceneArt(asset, height: short ? 96 : 124, alignment: Alignment.center),
        const SizedBox(height: 10),
        GoldFrame(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                softWrap: true,
                overflow: TextOverflow.visible,
                style: TextStyle(fontFamily: 'Cinzel', color: Palette.gold, fontSize: 20, letterSpacing: 0.4, height: 1.15),
              ),
              const SizedBox(height: 6),
              Container(width: 36, height: 1.2, color: Palette.gold.withValues(alpha: 0.55)),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(subtitle!, style: TextStyle(color: Palette.cream, height: 1.4, fontSize: 13)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.art,
    required this.text,
    this.cta,
    this.onTap,
  });
  final String art;
  final String text;
  final String? cta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final short = MediaQuery.sizeOf(context).height < 700;
    return Column(
      children: [
        SceneArt(art, height: short ? 88 : 120),
        const SizedBox(height: 10),
        NarrativePanel(text, fontSize: 14, align: TextAlign.center),
        if (cta != null) ...[
          const SizedBox(height: 10),
          PrimaryButton(label: cta!, onTap: onTap),
        ],
      ],
    );
  }
}

class EmptyHint extends StatelessWidget {
  const EmptyHint(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    return EmptyState(art: Art.empty('ledger'), text: text);
  }
}

class _GoldMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()
      ..color = Palette.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final fill = Paint()..color = Palette.navy2;
    final r = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), gold);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width * 0.18, Paint()..color = Palette.goldSoft);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RainFallbackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Palette.navy);
    final rain = Paint()
      ..color = Palette.cream.withValues(alpha: 0.16)
      ..strokeWidth = 1;
    for (var i = 0; i < 36; i++) {
      final x = (i * 41) % (size.width + 1);
      final y = (i * 29) % (size.height + 1);
      canvas.drawLine(Offset(x, y), Offset(x + 3, y + 14), rain);
    }
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Palette.gold.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NoirBurst extends StatelessWidget {
  const NoirBurst({super.key, this.heat = false});
  final bool heat;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _BurstPainter(heat: heat), size: Size.infinite),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.heat});
  final bool heat;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(heat ? 11 : 3);
    for (var i = 0; i < 28; i++) {
      final p = Paint()
        ..color = (heat ? Palette.redSoft : Palette.goldSoft).withValues(alpha: 0.18 + rng.nextDouble() * 0.35);
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        1.2 + rng.nextDouble() * 2.4,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.heat != heat;
}
