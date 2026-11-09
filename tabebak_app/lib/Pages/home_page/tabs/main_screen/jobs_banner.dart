import 'dart:async';

import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/animations/effects.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/Pages/explore/explore_pages.dart';
import 'package:clinic_dr_alla/data/models.dart';
import 'package:flutter/material.dart';

/// The home screen's live "وظائف شاغرة" banner. [jobs] must not be empty.
class JobsHomeBanner extends StatefulWidget {
  final List<Job> jobs;

  /// Every job on the dashboard; 0 when the count isn't known.
  final int total;
  final VoidCallback onSeeAll;

  const JobsHomeBanner({
    super.key,
    required this.jobs,
    required this.total,
    required this.onSeeAll,
  });

  @override
  State<JobsHomeBanner> createState() => _JobsHomeBannerState();
}

class _JobsHomeBannerState extends State<JobsHomeBanner> {
  static const _orange = Color(0xFFEF6C00);
  static const _rotateEvery = Duration(seconds: 4);

  // Starting deep in an endless list lets the jobs loop in both directions.
  late final int _start = _loops ? widget.jobs.length * 1000 : 0;
  late final _controller = PageController(initialPage: _start);
  late int _page = _start;
  Timer? _timer;

  bool get _loops => widget.jobs.length > 1;

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  /// Restarted on every page change, so a swipe gets a full turn on screen.
  void _scheduleNext() {
    _timer?.cancel();
    if (!_loops) return;
    _timer = Timer(_rotateEvery, () {
      if (_controller.hasClients) {
        _controller.nextPage(
            duration: const Duration(milliseconds: 550),
            curve: Curves.easeOutCubic);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String get _countLabel {
    final n = widget.total;
    if (n == 1) return 'وظيفة واحدة';
    if (n == 2) return 'وظيفتان';
    return n <= 10 ? '$n وظائف' : '$n وظيفة';
  }

  @override
  Widget build(BuildContext context) {
    final jobs = widget.jobs;
    return FadeSlideIn(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: AuroraBackground(
            colors: const [Color(0xFFD84315), _orange, Color(0xFFFFB74D)],
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                children: [
                  _header(),
                  const SizedBox(height: 12),
                  SizedBox(
                    // Grows with the phone's text size, so nothing is cut off.
                    height: MediaQuery.textScalerOf(context).scale(112),
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _loops ? null : 1,
                      onPageChanged: (p) {
                        setState(() => _page = p);
                        _scheduleNext();
                      },
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _JobSlide(job: jobs[i % jobs.length]),
                      ),
                    ),
                  ),
                  if (_loops) ...[
                    const SizedBox(height: 10),
                    _dots(jobs.length),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => PressableScale(
        pressedScale: 0.98,
        onTap: widget.onSeeAll,
        child: Row(
          children: [
            const PulsingDot(color: Colors.white, size: 8),
            const SizedBox(width: 10),
            const Text('وظائف شاغرة',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
            if (widget.total > 0) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_countLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ],
            const Spacer(),
            const Text('عرض الكل',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
            const Icon(Icons.chevron_left_rounded, color: Colors.white),
          ],
        ),
      );

  Widget _dots(int count) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _page % count ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white
                    .withValues(alpha: i == _page % count ? 1 : 0.45),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
        ],
      );
}

class _JobSlide extends StatelessWidget {
  final Job job;

  const _JobSlide({required this.job});

  static const _orange = _JobsHomeBannerState._orange;

  @override
  Widget build(BuildContext context) {
    final where = [job.employer, job.city].where((s) => s.isNotEmpty).join(' • ');
    return PressableScale(
      pressedScale: 0.97,
      onTap: () => showJobDetails(context, job),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(colors: [
                  _orange.withValues(alpha: 0.18),
                  const Color(0xFFFFB74D).withValues(alpha: 0.12),
                ]),
              ),
              child: FloatingWidget(
                distance: 4,
                child: Text(job.emoji, style: const TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15.5,
                          color: kBrandText)),
                  if (where.isNotEmpty)
                    Text(where,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: kBrandMuted, fontSize: 12.5)),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      if (job.type.isNotEmpty)
                        Flexible(child: _pill(job.type, _orange)),
                      if (job.featured) ...[
                        const SizedBox(width: 6),
                        _pill('⭐ مميزة', const Color(0xFFB7791F)),
                      ] else if (job.isNew) ...[
                        const SizedBox(width: 6),
                        _pill('جديدة', kBrandSuccess),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: kBrandMuted),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: color, fontSize: 11.5, fontWeight: FontWeight.w800)),
      );
}
