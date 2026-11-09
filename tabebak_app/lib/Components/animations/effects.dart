import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Slowly drifting light blobs over a gradient, for living backgrounds.
class AuroraBackground extends StatefulWidget {
  final List<Color> colors;
  final Widget? child;

  const AuroraBackground({super.key, required this.colors, this.child});

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _AuroraPainter(_c, widget.colors)),
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final Animation<double> t;
  final List<Color> colors;

  _AuroraPainter(this.t, this.colors) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: colors,
        ).createShader(rect),
    );
    final a = t.value * math.pi * 2;
    final blobs = [
      [0.15 + 0.12 * math.cos(a), 0.2 + 0.15 * math.sin(a), 0.55, 0.22],
      [0.85 + 0.1 * math.sin(a * 2), 0.35 + 0.2 * math.cos(a), 0.45, 0.18],
      [0.5 + 0.25 * math.sin(a), 0.95 + 0.1 * math.cos(a * 2), 0.6, 0.16],
    ];
    for (final b in blobs) {
      final c = Offset(size.width * b[0], size.height * b[1]);
      final r = size.width * b[2];
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            Colors.white.withValues(alpha: b[3]),
            Colors.white.withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.colors != colors;
}

/// Counts up from 0 to [value] once.
class CountUp extends StatelessWidget {
  final num value;
  final String prefix;
  final String suffix;
  final int decimals;
  final TextStyle? style;
  final Duration duration;

  const CountUp({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.decimals = 0,
    this.style,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) =>
          Text('$prefix${v.toStringAsFixed(decimals)}$suffix', style: style),
    );
  }
}

/// Shimmering placeholder shown while content loads.
class Skeleton extends StatefulWidget {
  final Widget child;
  const Skeleton({super.key, required this.child});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1300))
    ..repeat();

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
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (b) => LinearGradient(
          begin: Alignment(-1.5 + _c.value * 3, 0),
          end: Alignment(-0.5 + _c.value * 3, 0),
          colors: const [
            Color(0xFFE4ECF7),
            Color(0xFFF8FBFF),
            Color(0xFFE4ECF7),
          ],
        ).createShader(b),
        child: child,
      ),
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox(
      {super.key, this.width, required this.height, this.radius = 10});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE4ECF7),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

/// A dot with an expanding halo, e.g. for "open now".
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingDot({super.key, required this.color, this.size = 8});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
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
      width: s * 2.6,
      height: s * 2.6,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: s * (1 + _c.value * 1.6),
              height: s * (1 + _c.value * 1.6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.4 * (1 - _c.value)),
              ),
            ),
            Container(
              width: s,
              height: s,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: widget.color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Heart toggle that pops and bursts confetti when switched on.
class HeartBurstButton extends StatefulWidget {
  final bool active;
  final VoidCallback onTap;
  final double size;
  final Color inactiveColor;

  const HeartBurstButton({
    super.key,
    required this.active,
    required this.onTap,
    this.size = 26,
    this.inactiveColor = Colors.white,
  });

  @override
  State<HeartBurstButton> createState() => _HeartBurstButtonState();
}

class _HeartBurstButtonState extends State<HeartBurstButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 750));

  static final _pop = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.6), weight: 20),
    TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 80),
  ]);

  @override
  void didUpdateWidget(HeartBurstButton old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      child: SizedBox(
        width: s * 2,
        height: s * 2,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final v = _c.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                if (v > 0 && v < 1)
                  CustomPaint(
                      size: Size(s * 2, s * 2), painter: _BurstPainter(v)),
                Transform.scale(
                  scale: v == 0 ? 1.0 : _pop.transform(v),
                  child: Icon(
                    widget.active
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: widget.active
                        ? const Color(0xFFFF3D6E)
                        : widget.inactiveColor,
                    size: s,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final double t;
  _BurstPainter(this.t);

  static const _colors = [
    Color(0xFFFF3D6E),
    Color(0xFFFFC107),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final p = Curves.easeOutCubic.transform(t);
    canvas.drawCircle(
        c,
        size.width * (0.18 + 0.32 * p),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1 - p)
          ..color = const Color(0xFFFF3D6E).withValues(alpha: 1 - p));
    for (var i = 0; i < 10; i++) {
      final ang = i / 10 * math.pi * 2;
      final d = size.width * (0.2 + 0.32 * p);
      canvas.drawCircle(
        c + Offset(math.cos(ang), math.sin(ang)) * d,
        3.2 * (1 - p),
        Paint()..color = _colors[i % _colors.length],
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}

/// Read-only star rating.
class StarRating extends StatelessWidget {
  final double rating;
  final double size;

  const StarRating({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star_rounded
                : rating >= i - 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
            size: size,
            color: const Color(0xFFFFB300),
          ),
      ],
    );
  }
}

/// Gives a child a 3D tilt that follows the finger while pressed.
class TiltOnTouch extends StatefulWidget {
  final Widget child;
  final double maxTilt;

  const TiltOnTouch({super.key, required this.child, this.maxTilt = 0.12});

  @override
  State<TiltOnTouch> createState() => _TiltOnTouchState();
}

class _TiltOnTouchState extends State<TiltOnTouch> {
  Offset _tilt = Offset.zero;

  void _update(Offset local, Size size) {
    final dx = (local.dx / size.width - 0.5) * 2;
    final dy = (local.dy / size.height - 0.5) * 2;
    setState(() => _tilt = Offset(dx.clamp(-1, 1), dy.clamp(-1, 1)));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return Listener(
          onPointerDown: (e) => _update(e.localPosition, size),
          onPointerMove: (e) => _update(e.localPosition, size),
          onPointerUp: (_) => setState(() => _tilt = Offset.zero),
          onPointerCancel: (_) => setState(() => _tilt = Offset.zero),
          child: TweenAnimationBuilder<Offset>(
            tween: Tween(end: _tilt),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            builder: (context, o, child) => Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateX(-o.dy * widget.maxTilt)
                ..rotateY(o.dx * widget.maxTilt),
              child: child,
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}
