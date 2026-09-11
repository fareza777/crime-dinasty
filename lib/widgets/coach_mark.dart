import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme/app_theme.dart';
import '../tour.dart';

class CoachMarkLayer extends StatefulWidget {
  const CoachMarkLayer({
    super.key,
    required this.stepIndex,
    required this.targetKey,
    required this.onNext,
    required this.onSkip,
    this.measureToken = '',
  });

  final int stepIndex;
  final GlobalKey? targetKey;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final String measureToken;

  @override
  State<CoachMarkLayer> createState() => _CoachMarkLayerState();
}

class _CoachMarkLayerState extends State<CoachMarkLayer> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  final _tipKey = GlobalKey();
  int _loop = 0;
  int _tries = 0;
  bool _scrollOnce = false;
  Rect? _cachedTarget;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _remeasure();
  }

  @override
  void didUpdateWidget(covariant CoachMarkLayer old) {
    super.didUpdateWidget(old);
    final stepChanged = old.stepIndex != widget.stepIndex || old.targetKey != widget.targetKey;
    if (stepChanged) {
      _scrollOnce = false;
      _tries = 0;
      _cachedTarget = null;
    }
    if (stepChanged || old.measureToken != widget.measureToken) {
      _remeasure();
    }
  }

  @override
  void dispose() {
    _loop += 1;
    _pulse.dispose();
    super.dispose();
  }

  void _remeasure() {
    final loop = ++_loop;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || loop != _loop) return;
      final ctx = widget.targetKey?.currentContext;
      if (ctx != null && ctx.mounted && !_scrollOnce) {
        _scrollOnce = true;
        try {
          await Scrollable.ensureVisible(
            ctx,
            alignment: 0.42,
            alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
          );
        } catch (_) {}
        if (!mounted || loop != _loop) return;
      }
      final next = _rectOf(widget.targetKey);
      setState(() {
        _cachedTarget = next;
      });
      if (next == null && widget.targetKey != null) {
        _tries += 1;
        final wait = _tries < 24 ? 50 : 140;
        Future<void>.delayed(Duration(milliseconds: wait), () {
          if (mounted && loop == _loop) _remeasure();
        });
      }
    });
  }

  Rect? _rectOf(GlobalKey? key) {
    try {
      final ctx = key?.currentContext;
      if (ctx == null || !ctx.mounted) return null;
      final obj = ctx.findRenderObject();
      if (obj is! RenderBox || !obj.hasSize) return null;
      if (obj.size.width < 8 || obj.size.height < 8) return null;
      final offset = obj.localToGlobal(Offset.zero);
      if (offset.dx.isNaN || offset.dy.isNaN) return null;
      final rect = offset & obj.size;
      final screen = MediaQuery.sizeOf(context);
      if (rect.bottom < 0 || rect.top > screen.height || rect.right < 0 || rect.left > screen.width) {
        return null;
      }
      return rect;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = Tour.steps[widget.stepIndex.clamp(0, Tour.length - 1)];
    final target = _cachedTarget;
    final size = MediaQuery.sizeOf(context);
    final tipSize = Size(math.min(320, size.width - 28), 176);
    final tipOffset = _tipOffset(size, target, tipSize);

    return _TourHit(
      tipKey: _tipKey,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          return Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SpotlightPainter(target, _pulse.value),
                  ),
                ),
              ),
              if (target != null)
                Positioned.fromRect(
                  rect: target.inflate(12 + _pulse.value * 6),
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Palette.gold.withValues(alpha: 0.45 + _pulse.value * 0.5), width: 2.6),
                        boxShadow: [
                          BoxShadow(
                            color: Palette.gold.withValues(alpha: 0.32 + _pulse.value * 0.28),
                            blurRadius: 18 + _pulse.value * 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (target != null)
                IgnorePointer(
                  child: CustomPaint(
                    size: size,
                    painter: _ArrowPainter(from: tipOffset, tipSize: tipSize, target: target),
                  ),
                ),
              Positioned(
                left: tipOffset.dx,
                top: tipOffset.dy,
                width: tipSize.width,
                child: KeyedSubtree(
                  key: _tipKey,
                  child: _TipCard(
                    step: step,
                    index: widget.stepIndex,
                    found: target != null,
                    onNext: widget.onNext,
                    onSkip: widget.onSkip,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Offset _tipOffset(Size size, Rect? target, Size tip) {
    if (target == null) {
      return Offset((size.width - tip.width) / 2, 16);
    }
    final hole = target.inflate(18);
    Offset clamp(Offset o) {
      return Offset(
        o.dx.clamp(10.0, math.max(10.0, size.width - tip.width - 10)),
        o.dy.clamp(10.0, math.max(10.0, size.height - tip.height - 10)),
      );
    }

    bool overlaps(Offset o) => (o & tip).inflate(6).overlaps(hole);

    final below = clamp(Offset(target.center.dx - tip.width / 2, target.bottom + 20));
    final above = clamp(Offset(target.center.dx - tip.width / 2, target.top - tip.height - 20));
    final spaceBelow = size.height - target.bottom;
    final spaceAbove = target.top;
    final first = spaceBelow >= spaceAbove ? below : above;
    final second = spaceBelow >= spaceAbove ? above : below;
    if (!overlaps(first)) return first;
    if (!overlaps(second)) return second;
    if (hole.center.dy > size.height * 0.55) {
      return Offset((size.width - tip.width) / 2, 12);
    }
    return Offset((size.width - tip.width) / 2, size.height - tip.height - 18);
  }
}

/// The overlay never blocks the game: every tap outside the tip card passes
/// straight through to the real widgets. Only the tip card itself takes taps.
class _TourHit extends SingleChildRenderObjectWidget {
  const _TourHit({
    required this.tipKey,
    required Widget child,
  }) : super(child: child);

  final GlobalKey tipKey;

  @override
  RenderObject createRenderObject(BuildContext context) => _TourHitBox(tipKey);

  @override
  void updateRenderObject(BuildContext context, _TourHitBox renderObject) {
    renderObject.tipKey = tipKey;
  }
}

class _TourHitBox extends RenderProxyBox {
  _TourHitBox(this.tipKey);
  GlobalKey tipKey;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    final global = localToGlobal(position);
    final tipBox = tipKey.currentContext?.findRenderObject() as RenderBox?;
    if (tipBox != null && tipBox.hasSize) {
      final local = tipBox.globalToLocal(global);
      if (tipBox.size.contains(local) && tipBox.hitTest(result, position: local)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool hitTestSelf(Offset position) => false;
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.step,
    required this.index,
    required this.found,
    required this.onNext,
    required this.onSkip,
  });
  final TourStep step;
  final int index;
  final bool found;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final last = index >= Tour.length - 1;
    return Material(
      color: Palette.navy2,
      elevation: 12,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Palette.gold.withValues(alpha: 0.8), width: 1.4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(step.title, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Cinzel', color: Palette.gold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(step.body, textAlign: TextAlign.center, style: TextStyle(color: Palette.cream, height: 1.3, fontSize: 13)),
            const SizedBox(height: 6),
            Text(
              found
                  ? (step.waitForTap ? 'Tap the glow · Step ${index + 1} of ${Tour.length}' : 'Step ${index + 1} of ${Tour.length}')
                  : 'Step ${index + 1} of ${Tour.length} · tap the real button if you see it',
              textAlign: TextAlign.center,
              style: TextStyle(color: Palette.goldSoft, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                TextButton(
                  onPressed: onSkip,
                  child: Text('Skip', style: TextStyle(color: Palette.muted, fontSize: 13)),
                ),
                const Spacer(),
                if (!step.waitForTap || last || !found)
                  TextButton(
                    onPressed: onNext,
                    child: Text(
                      last ? 'Done' : 'Next',
                      style: TextStyle(color: Palette.gold, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter(this.target, this.pulse);
  final Rect? target;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()..addRect(Offset.zero & size);
    if (target != null) {
      overlay.addRRect(RRect.fromRectAndRadius(target!.inflate(10), const Radius.circular(14)));
      overlay.fillType = PathFillType.evenOdd;
    }
    canvas.drawPath(overlay, Paint()..color = Colors.black.withValues(alpha: target == null ? 0.28 : 0.8));
    if (target != null) {
      final spark = Paint()..color = Palette.goldSoft.withValues(alpha: 0.5 + pulse * 0.35);
      final pts = [
        target!.topLeft - const Offset(8, 8),
        target!.topRight + const Offset(6, -8),
        target!.bottomRight + const Offset(6, 6),
        target!.bottomLeft + const Offset(-8, 6),
      ];
      for (final o in pts) {
        canvas.drawCircle(o, 2 + pulse, spark);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) => old.target != target || old.pulse != pulse;
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.from, required this.tipSize, required this.target});
  final Offset from;
  final Size tipSize;
  final Rect target;

  @override
  void paint(Canvas canvas, Size size) {
    final tipCenter = from + Offset(tipSize.width / 2, from.dy + tipSize.height / 2 < target.center.dy ? tipSize.height : 0);
    final dest = target.center;
    final paint = Paint()
      ..color = Palette.gold
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tipCenter, dest, paint);
    final angle = math.atan2(dest.dy - tipCenter.dy, dest.dx - tipCenter.dx);
    final path = Path()
      ..moveTo(dest.dx, dest.dy)
      ..lineTo(dest.dx - 11 * math.cos(angle - 0.45), dest.dy - 11 * math.sin(angle - 0.45))
      ..moveTo(dest.dx, dest.dy)
      ..lineTo(dest.dx - 11 * math.cos(angle + 0.45), dest.dy - 11 * math.sin(angle + 0.45));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) => old.from != from || old.target != target;
}
