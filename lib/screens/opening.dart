import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../art.dart';
import '../game_controller.dart';
import '../services/voice_over.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class OpeningScreen extends StatefulWidget {
  const OpeningScreen({super.key, required this.c});
  final GameController c;

  @override
  State<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends State<OpeningScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ken;
  Timer? _end;

  @override
  void initState() {
    super.initState();
    _ken = AnimationController(vsync: this, duration: const Duration(seconds: 22))..forward();
    _ken.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _end ??= Timer(const Duration(milliseconds: 400), widget.c.finishOpening);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(widget.c.vo.play('opening'));
    });
    widget.c.vo.addListener(_onVo);
  }

  void _onVo() {
    if (!mounted) return;
    setState(() {});
    final clip = widget.c.vo.current;
    if (clip == null) return;
    if (!widget.c.vo.playing && widget.c.vo.position.inMilliseconds > 400) {
      _end ??= Timer(const Duration(milliseconds: 900), widget.c.finishOpening);
    }
  }

  @override
  void dispose() {
    widget.c.vo.removeListener(_onVo);
    _ken.dispose();
    _end?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vo = widget.c.vo;
    final line = vo.activeLine;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _ken,
            builder: (context, _) {
              final t = _ken.value;
              final scale = 1.08 + (t * 0.12);
              final dx = math.sin(t * math.pi) * 12;
              return Transform.scale(
                scale: scale,
                child: Transform.translate(
                  offset: Offset(dx, t * -18),
                  child: Image.asset(
                    Art.openingStill,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Image.asset(
                      Art.splash,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(color: Palette.navy),
                    ),
                  ),
                ),
              );
            },
          ),
          const _CinematicRain(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Palette.navy.withValues(alpha: 0.18),
                  Palette.navy.withValues(alpha: 0.35),
                  Palette.navy.withValues(alpha: 0.92),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: GhostButton(label: 'Skip', expand: false, onTap: widget.c.finishOpening),
                  ),
                  const Spacer(),
                  Text(
                    'RAVENPORT, 1998',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Palette.gold.withValues(alpha: 0.85),
                      letterSpacing: 3.2,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: Text(
                      line?.text ?? '',
                      key: ValueKey(line?.text ?? ''),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Cinzel',
                        color: Palette.cream,
                        fontSize: (line?.text == 'Vice Dynasty.') ? 32 : 22,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _VoScrub(clip: vo.current, position: vo.position),
                  const SizedBox(height: 10),
                  Text(
                    'Vice Dynasty',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      color: Palette.gold.withValues(alpha: 0.7),
                      letterSpacing: 2.4,
                      fontSize: 13,
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

class _VoScrub extends StatelessWidget {
  const _VoScrub({required this.clip, required this.position});
  final VoiceClip? clip;
  final Duration position;

  @override
  Widget build(BuildContext context) {
    final total = clip == null || clip!.duration <= 0 ? 16.0 : clip!.duration;
    final t = (position.inMilliseconds / 1000.0 / total).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: t,
        minHeight: 3,
        color: Palette.gold,
        backgroundColor: Palette.gold.withValues(alpha: 0.18),
      ),
    );
  }
}

class _CinematicRain extends StatelessWidget {
  const _CinematicRain();
  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _RainPainter(), size: Size.infinite);
  }
}

class _RainPainter extends CustomPainter {
  const _RainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rain = Paint()
      ..color = const Color(0xFFE8E4DC).withValues(alpha: 0.16)
      ..strokeWidth = 1.1;
    for (var i = 0; i < 64; i++) {
      final x = (i * 41) % size.width;
      final y = (i * 67) % size.height;
      canvas.drawLine(Offset(x, y), Offset(x + 5, y + 22), rain);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
