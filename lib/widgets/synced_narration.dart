import 'package:flutter/material.dart';

import '../services/voice_over.dart';
import '../theme/app_theme.dart';
import 'common.dart';

class SyncedNarration extends StatelessWidget {
  const SyncedNarration({
    super.key,
    required this.body,
    required this.clip,
    required this.position,
    this.fontSize = 14.5,
  });

  final String body;
  final VoiceClip? clip;
  final Duration position;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final lines = clip?.lines ?? const <VoiceLine>[];
    if (lines.isEmpty) {
      return NarrativePanel(body, fontSize: fontSize);
    }
    final t = position.inMilliseconds / 1000.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Palette.light ? const Color(0xFFF7F3EA) : Palette.card.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.line.withValues(alpha: Palette.light ? 0.9 : 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < lines.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: fontSize,
                  height: 1.4,
                  color: _color(lines[i], t),
                  fontWeight: t >= lines[i].start && t < lines[i].end + 0.15
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
                child: Text(lines[i].text),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _color(VoiceLine line, double t) {
    if (t >= line.start && t < line.end + 0.15) return Palette.gold;
    if (t >= line.end) return Palette.cream.withValues(alpha: 0.78);
    return Palette.muted;
  }
}
