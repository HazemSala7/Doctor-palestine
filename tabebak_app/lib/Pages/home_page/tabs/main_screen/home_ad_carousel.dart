import 'dart:async';

import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/brand_widgets.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:flutter/material.dart';

class AdSlide {
  final String image;
  final String? title;
  final VoidCallback? onTap;

  const AdSlide(this.image, {this.title, this.onTap});
}

/// The home screen's advertising strip: moves by itself and loops, and holds
/// still while a finger is on it. [slides] must not be empty.
class HomeAdCarousel extends StatelessWidget {
  final List<AdSlide> slides;

  const HomeAdCarousel({super.key, required this.slides});

  @override
  Widget build(BuildContext context) => AutoPager(
        count: slides.length,
        height: 170,
        itemBuilder: (_, i) => _Slide(slide: slides[i]),
      );
}

/// Pages that move by themselves every 4 seconds and loop, hold still while a
/// finger is on them, and show dots when there's more than one. [count] > 0.
class AutoPager extends StatefulWidget {
  final int count;
  final double height;
  final IndexedWidgetBuilder itemBuilder;

  /// The dot of the page on screen; the others are [dotColor].
  final Gradient activeDot;
  final Color dotColor;

  const AutoPager({
    super.key,
    required this.count,
    required this.height,
    required this.itemBuilder,
    this.activeDot = kBrandGradient,
    this.dotColor = const Color(0xFFCFDAEA),
  });

  @override
  State<AutoPager> createState() => _AutoPagerState();
}

class _AutoPagerState extends State<AutoPager> {
  static const _rotateEvery = Duration(seconds: 4);

  // Starting deep in an endless list lets the pages loop in both directions.
  late final int _start = _loops ? widget.count * 1000 : 0;
  late final _controller =
      PageController(initialPage: _start, viewportFraction: 0.88);
  late int _page = _start;
  Timer? _timer;

  bool get _loops => widget.count > 1;

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  void _scheduleNext() {
    _timer?.cancel();
    if (!_loops) return;
    _timer = Timer(_rotateEvery, () {
      if (_controller.hasClients) {
        _controller.nextPage(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.count;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: Listener(
            onPointerDown: (_) => _timer?.cancel(),
            onPointerUp: (_) => _scheduleNext(),
            onPointerCancel: (_) => _scheduleNext(),
            child: PageView.builder(
              controller: _controller,
              itemCount: _loops ? null : 1,
              onPageChanged: (p) {
                setState(() => _page = p);
                _scheduleNext();
              },
              itemBuilder: (context, i) => AnimatedBuilder(
                animation: _controller,
                builder: (_, child) {
                  var distance = 0.0;
                  if (_controller.hasClients &&
                      _controller.position.haveDimensions) {
                    distance = (_controller.page! - i).clamp(-1.0, 1.0);
                  }
                  return Transform.scale(
                      scale: 1 - distance.abs() * 0.08, child: child);
                },
                child: widget.itemBuilder(context, i % count),
              ),
            ),
          ),
        ),
        if (_loops) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < count; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page % count ? 22 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    gradient: i == _page % count ? widget.activeDot : null,
                    color: i == _page % count ? null : widget.dotColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Slide extends StatelessWidget {
  final AdSlide slide;

  const _Slide({required this.slide});

  @override
  Widget build(BuildContext context) {
    final title = slide.title;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 18, 6, 0),
      child: PressableScale(
        pressedScale: 0.97,
        onTap: slide.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            fit: StackFit.expand,
            children: [
              NetImage(slide.image, fit: BoxFit.cover, width: double.infinity),
              if (title != null && title.isNotEmpty)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 24, 14, 10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xAA000000), Colors.transparent],
                      ),
                    ),
                    child: Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
