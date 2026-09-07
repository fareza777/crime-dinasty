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
  });

  final int stepIndex;
  final GlobalKey? targetKey;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  State<CoachMarkLayer> createState() => _CoachMarkLayerState();
}

class _CoachMarkLayerState extends State<CoachMarkLayer> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  final _tipKey = GlobalKey();
  int _tries = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
    _remeasure();
  }

  @override
  void didUpdateWidget(covariant CoachMarkLayer old) {
    super.didUpdateWidget(old);
    if (old.stepIndex != widget.stepIndex || old.targetKey != widget.targetKey) {
      _tries = 0;
    }
    _remeasure();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _remeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
      final missing = _targetRect() == null && widget.targetKey != null;
      if (missing && _tries < 12) {
        _tries += 1;
        Future<void>.delayed(const Duration(milliseconds: 40), _remeasure);
      }
    });
  }

  Rect? _targetRect() {
    final ctx = widget.targetKey?.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    if (offset.dx.isNaN || offset.dy.isNaN) return null;
    return offset & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final step = Tour.steps[widget.stepIndex.clamp(0, Tour.length - 1)];
    final target = _targetRect();
    final size = MediaQuery.sizeOf(context);
    final tipSize = Size(math.min(300, size.width - 32), 148);
    final tipOffset = _tipOffset(size, target, tipSize);

    return _TourHit(
      hole: target?.inflate(10),
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
                  rect: target.inflate(14 + _pulse.value * 7),
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Palette.gold.withValues(alpha: 0.35 + _pulse.value * 0.5), width: 2.4),
                        boxShadow: [
                          BoxShadow(
                            color: Palette.gold.withValues(alpha: 0.28 + _pulse.value * 0.25),
                            blurRadius: 18 + _pulse.value * 10,
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
      return Offset((size.width - tip.width) / 2, size.height * 0.38);
    }
    final above = target.center.dy > size.height * 0.48;
    var top = above ? target.top - tip.height - 22 : target.bottom + 22;
    top = top.clamp(12.0, size.height - tip.height - 12);
    var left = target.center.dx - tip.width / 2;
    left = left.clamp(12.0, size.width - tip.width - 12);
    return Offset(left, top);
  }
}

/// Dim absorbs taps; the spotlight hole lets the real control receive them.
class _TourHit extends SingleChildRenderObjectWidget {
  const _TourHit({required this.hole, required this.tipKey, required Widget child}) : super(child: child);

  final Rect? hole;
  final GlobalKey tipKey;

  @override
  RenderObject createRenderObject(BuildContext context) => _TourHitBox(hole, tipKey);

  @override
  void updateRenderObject(BuildContext context, _TourHitBox renderObject) {
    renderObject.hole = hole;
    renderObject.tipKey = tipKey;
  }
}

class _TourHitBox extends RenderProxyBox {
  _TourHitBox(this._hole, this.tipKey);
  Rect? _hole;
  GlobalKey tipKey;
  set hole(Rect? v) {
    if (_hole == v) return;
    _hole = v;
    markNeedsPaint();
  }

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
    if (_hole != null && _hole!.contains(global)) return false;
    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  bool hitTestSelf(Offset position) => false;
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.step,
    required this.index,
    required this.onNext,
    required this.onSkip,
  });
  final TourStep step;
  final int index;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.navy2,
      elevation: 10,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Palette.gold.withValues(alpha: 0.75)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(step.title, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Cinzel', color: Palette.gold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(step.body, textAlign: TextAlign.center, style: TextStyle(color: Palette.cream, height: 1.3, fontSize: 12.5)),
            const SizedBox(height: 6),
            Text('Step ${index + 1} of ${Tour.length}', style: TextStyle(color: Palette.goldSoft, fontSize: 10)),
            const SizedBox(height: 4),
            Row(
              children: [
                TextButton(
                  onPressed: onSkip,
                  child: Text('Skip', style: TextStyle(color: Palette.muted, fontSize: 13)),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onNext,
                  child: Text(
                    index >= Tour.length - 1 ? 'Done' : 'Next',
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
      overlay.addRRect(RRect.fromRectAndRadius(target!.inflate(8), const Radius.circular(14)));
      overlay.fillType = PathFillType.evenOdd;
    }
    canvas.drawPath(overlay, Paint()..color = Colors.black.withValues(alpha: 0.78));
    if (target != null) {
      final spark = Paint()..color = Palette.goldSoft.withValues(alpha: 0.45 + pulse * 0.35);
      final pts = [
        target!.topLeft - const Offset(8, 8),
        target!.topRight + const Offset(6, -8),
        target!.bottomRight + const Offset(6, 6),
        target!.bottomLeft + const Offset(-8, 6),
      ];
      for (final o in pts) {
        canvas.drawCircle(o, 1.8 + pulse, spark);
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
    final tipCenter = from + Offset(tipSize.width / 2, from.dy < target.center.dy ? tipSize.height : 0);
    final dest = target.center;
    final paint = Paint()
      ..color = Palette.gold
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final mid = Offset((tipCenter.dx + dest.dx) / 2, (tipCenter.dy + dest.dy) / 2);
    canvas.drawLine(tipCenter, dest, paint);
    final angle = math.atan2(dest.dy - tipCenter.dy, dest.dx - tipCenter.dx);
    final path = Path()
      ..moveTo(dest.dx, dest.dy)
      ..lineTo(dest.dx - 10 * math.cos(angle - 0.45), dest.dy - 10 * math.sin(angle - 0.45))
      ..moveTo(dest.dx, dest.dy)
      ..lineTo(dest.dx - 10 * math.cos(angle + 0.45), dest.dy - 10 * math.sin(angle + 0.45));
    canvas.drawPath(path, paint);
    canvas.drawCircle(mid, 2.2, Paint()..color = Palette.goldSoft);
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter old) => old.from != from || old.target != target;
}
