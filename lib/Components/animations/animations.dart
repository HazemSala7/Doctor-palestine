import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Fades and slides its child in once, after an optional delay.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final double fromScale;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 550),
    this.offset = const Offset(0, 0.15),
    this.fromScale = 1.0,
  });

  /// Staggered entrance for list/grid items; the delay is capped so items
  /// far down an infinite list don't wait.
  factory FadeSlideIn.item(
      {Key? key, required int index, required Widget child}) {
    return FadeSlideIn(
      key: key,
      delay: Duration(milliseconds: 70 * (index % 8)),
      offset: const Offset(0, 0.25),
      fromScale: 0.94,
      child: child,
    );
  }

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _curve =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(begin: widget.offset, end: Offset.zero).animate(_curve),
        child: ScaleTransition(
          scale: Tween(begin: widget.fromScale, end: 1.0).animate(_curve),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Wraps an item builder so every built item animates in.
IndexedWidgetBuilder animatedItemBuilder(IndexedWidgetBuilder builder) {
  return (context, index) =>
      FadeSlideIn.item(index: index, child: builder(context, index));
}

/// Shrinks slightly while pressed and springs back, with a light haptic.
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.93,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _set(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: Duration(milliseconds: _pressed ? 110 : 380),
        curve: _pressed ? Curves.easeOut : Curves.elasticOut,
        child: widget.child,
      ),
    );
  }
}

/// A double "lub-dub" heartbeat pulse, repeating.
class HeartbeatPulse extends StatefulWidget {
  final Widget child;
  final double strength;
  final Duration period;

  const HeartbeatPulse({
    super.key,
    required this.child,
    this.strength = 0.06,
    this.period = const Duration(milliseconds: 1600),
  });

  @override
  State<HeartbeatPulse> createState() => _HeartbeatPulseState();
}

class _HeartbeatPulseState extends State<HeartbeatPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1 + widget.strength)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 10),
    TweenSequenceItem(
        tween: Tween(begin: 1 + widget.strength, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10),
    TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1 + widget.strength * 0.7)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 10),
    TweenSequenceItem(
        tween: Tween(begin: 1 + widget.strength * 0.7, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 12),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 58),
  ]).animate(_c);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}

/// Gentle endless up/down float.
class FloatingWidget extends StatefulWidget {
  final Widget child;
  final double distance;
  final Duration period;

  const FloatingWidget({
    super.key,
    required this.child,
    this.distance = 6,
    this.period = const Duration(milliseconds: 2600),
  });

  @override
  State<FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<FloatingWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset:
            Offset(0, -widget.distance * Curves.easeInOut.transform(_c.value)),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Animated backdrop of drifting translucent bubbles and medical crosses.
class FloatingBubbles extends StatefulWidget {
  final Color color;
  final int count;

  const FloatingBubbles(
      {super.key, this.color = Colors.white, this.count = 18});

  @override
  State<FloatingBubbles> createState() => _FloatingBubblesState();
}

class _FloatingBubblesState extends State<FloatingBubbles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 18))
        ..repeat();
  late final List<_Bubble> _bubbles = List.generate(widget.count, (i) {
    final r = math.Random(i * 7919 + 13);
    return _Bubble(
      x: r.nextDouble(),
      phase: r.nextDouble(),
      size: 6 + r.nextDouble() * 26,
      speed: 0.5 + r.nextDouble(),
      sway: 0.02 + r.nextDouble() * 0.05,
      isCross: i % 4 == 0,
      opacity: 0.08 + r.nextDouble() * 0.16,
    );
  });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _BubblesPainter(_c, _bubbles, widget.color),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Bubble {
  final double x, phase, size, speed, sway, opacity;
  final bool isCross;
  _Bubble({
    required this.x,
    required this.phase,
    required this.size,
    required this.speed,
    required this.sway,
    required this.isCross,
    required this.opacity,
  });
}

class _BubblesPainter extends CustomPainter {
  final Animation<double> t;
  final List<_Bubble> bubbles;
  final Color color;

  _BubblesPainter(this.t, this.bubbles, this.color) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in bubbles) {
      final p = (b.phase + t.value * b.speed) % 1.0;
      final y = size.height * (1.1 - p * 1.25);
      final x =
          size.width * (b.x + math.sin((p + b.phase) * math.pi * 4) * b.sway);
      // Fade in at the bottom and out at the top.
      final fade = math.sin(p * math.pi);
      final paint = Paint()..color = color.withValues(alpha: b.opacity * fade);
      if (b.isCross) {
        final s = b.size * 0.9;
        final w = s * 0.32;
        final rr = Radius.circular(w / 2);
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(p * math.pi);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset.zero, width: s, height: w), rr),
            paint);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset.zero, width: w, height: s), rr),
            paint);
        canvas.restore();
      } else {
        canvas.drawCircle(Offset(x, y), b.size / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BubblesPainter old) => false;
}

/// An ECG trace that draws itself left-to-right with a glowing head,
/// then repeats.
class EcgLine extends StatefulWidget {
  final Color color;
  final double height;
  final double strokeWidth;
  final Duration period;

  const EcgLine({
    super.key,
    this.color = Colors.white,
    this.height = 50,
    this.strokeWidth = 2.6,
    this.period = const Duration(milliseconds: 2200),
  });

  @override
  State<EcgLine> createState() => _EcgLineState();
}

class _EcgLineState extends State<EcgLine> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: CustomPaint(
        painter: _EcgPainter(_c, widget.color, widget.strokeWidth),
      ),
    );
  }
}

class _EcgPainter extends CustomPainter {
  final Animation<double> t;
  final Color color;
  final double strokeWidth;

  _EcgPainter(this.t, this.color, this.strokeWidth) : super(repaint: t);

  Path _trace(Size s) {
    final m = s.height / 2;
    final w = s.width;
    final h = s.height;
    // Two heartbeats across the width.
    final path = Path()..moveTo(0, m);
    for (final base in [0.0, 0.5]) {
      double x(double f) => w * (base + f * 0.5);
      path
        ..lineTo(x(0.22), m)
        ..quadraticBezierTo(x(0.27), m - h * 0.12, x(0.32), m)
        ..lineTo(x(0.38), m)
        ..lineTo(x(0.42), m + h * 0.14)
        ..lineTo(x(0.48), m - h * 0.46)
        ..lineTo(x(0.54), m + h * 0.36)
        ..lineTo(x(0.58), m)
        ..lineTo(x(0.66), m)
        ..quadraticBezierTo(x(0.73), m - h * 0.18, x(0.80), m)
        ..lineTo(x(1.0), m);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final metric = _trace(size).computeMetrics().first;
    final progress = Curves.easeInOut.transform(t.value);
    final len = metric.length * progress;
    // Visible tail behind the head.
    final tail = metric.length * 0.45;
    final start = math.max(0.0, len - tail);
    final segment = metric.extractPath(start, len);

    final rect = Offset.zero & size;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(colors: [
        color.withValues(alpha: 0.0),
        color,
      ]).createShader(Rect.fromLTRB(rect.width * (start / metric.length), 0,
          rect.width * (len / metric.length) + 1, rect.height));
    canvas.drawPath(segment, line);

    final head = metric.getTangentForOffset(len)?.position;
    if (head != null && progress > 0.01 && progress < 0.99) {
      canvas.drawCircle(head, strokeWidth * 3.2,
          Paint()..color = color.withValues(alpha: 0.25));
      canvas.drawCircle(head, strokeWidth * 1.4, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_EcgPainter old) => false;
}

/// A bright highlight that sweeps across its child periodically.
class ShimmerSweep extends StatefulWidget {
  final Widget child;
  final Duration period;

  const ShimmerSweep({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 2800),
  });

  @override
  State<ShimmerSweep> createState() => _ShimmerSweepState();
}

class _ShimmerSweepState extends State<ShimmerSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        // Sweep during the first 45% of the cycle, then rest.
        final p = (_c.value / 0.45).clamp(0.0, 1.0);
        final dx = -1.5 + p * 3.0;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(dx - 0.5, -0.3),
            end: Alignment(dx + 0.5, 0.3),
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.55),
              Colors.white.withValues(alpha: 0.0),
            ],
            stops: const [0.35, 0.5, 0.65],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

/// Branded loading indicator: the logo pulsing over an expanding ripple.
class BrandLoader extends StatefulWidget {
  final double size;
  final String logoAsset;
  final Color color;

  const BrandLoader({
    super.key,
    this.size = 90,
    required this.logoAsset,
    required this.color,
  });

  @override
  State<BrandLoader> createState() => _BrandLoaderState();
}

class _BrandLoaderState extends State<BrandLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 1.8,
      height: s * 1.8,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Stack(
          alignment: Alignment.center,
          children: [
            for (final offset in [0.0, 0.5])
              Builder(builder: (_) {
                final v = (_c.value + offset) % 1.0;
                return Container(
                  width: s * (0.9 + v * 0.9),
                  height: s * (0.9 + v * 0.9),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withValues(alpha: (1 - v) * 0.5),
                      width: 2,
                    ),
                  ),
                );
              }),
            child!,
          ],
        ),
        child: HeartbeatPulse(
          strength: 0.08,
          child: Container(
            width: s,
            height: s,
            padding: EdgeInsets.all(s * 0.12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.25),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Image.asset(widget.logoAsset, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
