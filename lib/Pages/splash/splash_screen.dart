import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:flutter/material.dart';

/// Animated brand intro: the logo springs in over drifting bubbles,
/// a heartbeat trace runs beneath it, then the app fades in.
class SplashScreen extends StatefulWidget {
  final WidgetBuilder nextBuilder;

  const SplashScreen({super.key, required this.nextBuilder});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))
    ..forward();

  Animation<double> _interval(double a, double b, [Curve c = Curves.easeOut]) =>
      CurvedAnimation(parent: _intro, curve: Interval(a, b, curve: c));

  late final _glow = _interval(0.0, 0.5);
  late final _logo = _interval(0.1, 0.75, Curves.elasticOut);
  late final _logoFade = _interval(0.1, 0.35);
  late final _title = _interval(0.45, 0.8, Curves.easeOutCubic);
  late final _tagline = _interval(0.6, 0.95, Curves.easeOutCubic);
  late final _ecg = _interval(0.7, 1.0);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3600), _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 900),
      pageBuilder: (context, _, __) => widget.nextBuilder(context),
      transitionsBuilder: (context, animation, _, child) {
        final a =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: a,
          child: ScaleTransition(
            scale: Tween(begin: 1.08, end: 1.0).animate(a),
            child: child,
          ),
        );
      },
    ));
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kBrandGradient),
        child: Stack(
          children: [
            const Positioned.fill(child: FloatingBubbles(count: 26)),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo card with expanding glow behind it.
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ScaleTransition(
                        scale: Tween(begin: 0.2, end: 1.0).animate(_glow),
                        child: FadeTransition(
                          opacity: _glow,
                          child: Container(
                            width: width * 0.9,
                            height: width * 0.9,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [
                                Colors.white.withValues(alpha: 0.35),
                                Colors.white.withValues(alpha: 0.0),
                              ]),
                            ),
                          ),
                        ),
                      ),
                      FadeTransition(
                        opacity: _logoFade,
                        child: ScaleTransition(
                          scale: Tween(begin: 0.3, end: 1.0).animate(_logo),
                          child: HeartbeatPulse(
                            strength: 0.035,
                            child: Container(
                              width: width * 0.68,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(32),
                                boxShadow: [
                                  BoxShadow(
                                    color: kBrandDark.withValues(alpha: 0.35),
                                    blurRadius: 40,
                                    offset: const Offset(0, 18),
                                  ),
                                ],
                              ),
                              child: ShimmerSweep(
                                child: Image.asset(kLogoAsset),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _rise(
                    _title,
                    const Text(
                      'طبيبك',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _rise(
                    _tagline,
                    Text(
                      'دليلك الطبي الشامل في فلسطين',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  FadeTransition(
                    opacity: _ecg,
                    child: SizedBox(
                      width: width * 0.62,
                      child: const EcgLine(height: 46),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rise(Animation<double> a, Widget child) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position:
              Tween(begin: const Offset(0, 0.6), end: Offset.zero).animate(a),
          child: child,
        ),
      );
}
