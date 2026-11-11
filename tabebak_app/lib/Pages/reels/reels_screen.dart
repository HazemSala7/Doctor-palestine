import 'dart:async';

import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/brand_widgets.dart';
import 'package:clinic_dr_alla/Components/tabebak_nav_bar.dart';
import 'package:clinic_dr_alla/Components/ui_kit.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/Pages/booking/book_appointment_page.dart';
import 'package:clinic_dr_alla/Pages/places/place_details_page.dart';
import 'package:clinic_dr_alla/data/models.dart';
import 'package:clinic_dr_alla/data/reels.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Full-screen vertical reels. Plays only while [active] (its tab is shown)
/// and the app is in the foreground.
class ReelsScreen extends StatefulWidget {
  final bool active;

  /// A change checks the dashboard for new or removed reels.
  final int refreshTick;

  const ReelsScreen({super.key, required this.active, this.refreshTick = 0});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> with WidgetsBindingObserver {
  final _pager = PageController();
  final _reels = <Reel>[];
  final _controllers = <int, VideoPlayerController>{};
  final _failed = <int>{};
  final _counted = <int>{};

  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;
  int _current = 0;
  bool _muted = false;
  bool _userPaused = false;
  bool _foreground = true;
  bool _covered = false; // another page is pushed on top
  Timer? _viewTimer;

  bool get _shouldPlay => widget.active && _foreground && !_covered && !_userPaused;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewTimer?.cancel();
    for (final c in _controllers.values) {
      c.dispose();
    }
    _pager.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ReelsScreen old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _syncPlayback();
    if (old.refreshTick != widget.refreshTick) _refreshIfChanged();
  }

  /// Reloads only when the first reels differ, so a video isn't interrupted
  /// for nothing.
  Future<void> _refreshIfChanged() async {
    try {
      final batch = await ReelsApi.fetch(1);
      if (!mounted) return;
      final fresh = batch.items.map((r) => r.id).toList();
      final current = _reels.take(fresh.length).map((r) => r.id).toList();
      if (fresh.join(',') != current.join(',')) await _refresh();
    } catch (e) {
      debugPrint('reels refresh failed: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncPlayback();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final batch = await ReelsApi.fetch(_page + 1);
      if (!mounted) return;
      final firstLoad = _reels.isEmpty;
      setState(() {
        _page++;
        _hasMore = batch.hasMore;
        _reels.addAll(batch.items);
      });
      if (firstLoad && _reels.isNotEmpty) _prepareAround(0);
    } catch (e) {
      if (mounted) setState(() => _error = 'تعذّر تحميل الريلز، تحقق من الإنترنت');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    _failed.clear();
    setState(() {
      _reels.clear();
      _page = 0;
      _hasMore = true;
      _current = 0;
      _userPaused = false;
    });
    if (_pager.hasClients) _pager.jumpToPage(0);
    await _loadMore();
  }

  /// Keeps players for the current reel and its neighbours only.
  void _prepareAround(int index) {
    for (final i in _controllers.keys.toList()) {
      if ((i - index).abs() > 1) _controllers.remove(i)!.dispose();
    }
    for (var i = index - 1; i <= index + 1; i++) {
      if (i < 0 || i >= _reels.length || _controllers.containsKey(i)) continue;
      final c = VideoPlayerController.networkUrl(Uri.parse(_reels[i].videoUrl));
      _controllers[i] = c;
      c.setLooping(true);
      c.setVolume(_muted ? 0 : 1);
      c.initialize().then((_) {
        if (!mounted || _controllers[i] != c) return;
        setState(() {});
        if (i == _current) _syncPlayback();
      }).catchError((Object e) {
        debugPrint('reel ${_reels[i].id} failed: $e');
        if (mounted) setState(() => _failed.add(i));
      });
    }
    _syncPlayback();
  }

  void _syncPlayback() {
    for (final entry in _controllers.entries) {
      final c = entry.value;
      if (!c.value.isInitialized) continue;
      if (entry.key == _current && _shouldPlay) {
        if (!c.value.isPlaying) c.play();
      } else if (c.value.isPlaying) {
        c.pause();
      }
    }
    _viewTimer?.cancel();
    if (_shouldPlay && _current < _reels.length) {
      final id = _reels[_current].id;
      // Counted once per session, after two seconds of watching.
      if (!_counted.contains(id)) {
        _viewTimer = Timer(const Duration(seconds: 2), () {
          if (_counted.add(id)) ReelsApi.markViewed(id);
        });
      }
    }
  }

  void _onPage(int index) {
    _controllers[_current]?.seekTo(Duration.zero);
    setState(() {
      _current = index;
      _userPaused = false;
    });
    _prepareAround(index);
    if (index >= _reels.length - 3) _loadMore();
  }

  void _togglePause() {
    setState(() => _userPaused = !_userPaused);
    _syncPlayback();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    for (final c in _controllers.values) {
      c.setVolume(_muted ? 0 : 1);
    }
  }

  /// Pauses while another page is open on top.
  Future<void> _open(Widget page) async {
    setState(() => _covered = true);
    _syncPlayback();
    await Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute(builder: (_) => page));
    if (!mounted) return;
    setState(() => _covered = false);
    _syncPlayback();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_reels.isEmpty)
            _emptyOrError()
          else
            PageView.builder(
              controller: _pager,
              scrollDirection: Axis.vertical,
              onPageChanged: _onPage,
              itemCount: _reels.length,
              itemBuilder: (context, i) => _ReelView(
                reel: _reels[i],
                controller: _controllers[i],
                failed: _failed.contains(i),
                paused: i == _current && _userPaused,
                muted: _muted,
                onTap: _togglePause,
                onMute: _toggleMute,
                onDoctor: (d) => _open(PlaceDetailsPage(place: d)),
                onBook: (d) => _open(BookAppointmentPage(place: d)),
              ),
            ),
          // Title bar.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: _reels.isEmpty,
              child: Container(
                padding: EdgeInsets.fromLTRB(20, topInset + 12, 12, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x99000000), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    const Text('🎬 ريلز',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                    const Spacer(),
                    if (_reels.isNotEmpty)
                      IconButton(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded,
                            color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyOrError() {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: FadeSlideIn(
          fromScale: 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FloatingWidget(
                  distance: 8,
                  child: Text('🎬', style: TextStyle(fontSize: 64))),
              const SizedBox(height: 16),
              Text(_error ?? 'لا توجد ريلز بعد',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                  _error == null
                      ? 'قريباً: فيديوهات طبية قصيرة ونصائح من أطبائنا'
                      : 'اسحب لإعادة المحاولة أو اضغط الزر',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _refresh,
                style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54)),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('تحديث'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReelView extends StatelessWidget {
  final Reel reel;
  final VideoPlayerController? controller;
  final bool failed;
  final bool paused;
  final bool muted;
  final VoidCallback onTap;
  final VoidCallback onMute;
  final ValueChanged<Place> onDoctor;
  final ValueChanged<Place> onBook;

  const _ReelView({
    required this.reel,
    required this.controller,
    required this.failed,
    required this.paused,
    required this.muted,
    required this.onTap,
    required this.onMute,
    required this.onDoctor,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final ready = c != null && c.value.isInitialized;
    // Clear the floating navigation bar.
    final bottom = MediaQuery.of(context).padding.bottom + TabebakNavBar.height + 30;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (reel.thumbnail != null && !ready)
            NetImage(reel.thumbnail!, fit: BoxFit.cover),
          if (ready)
            FittedBox(
              // Portrait videos fill the screen; landscape ones are shown whole.
              fit: c.value.aspectRatio < 1 ? BoxFit.cover : BoxFit.contain,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            ),
          if (failed)
            const Center(
              child: Text('تعذّر تشغيل هذا الفيديو',
                  style: TextStyle(color: Colors.white70)),
            )
          else if (!ready)
            const Center(
                child: CircularProgressIndicator(color: Colors.white)),
          if (ready)
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: c,
              builder: (_, v, __) => v.isBuffering && !paused
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white54))
                  : const SizedBox(),
            ),
          // Play icon while paused by the viewer.
          Center(
            child: AnimatedScale(
              scale: paused ? 1 : 0.6,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: paused ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: const BoxDecoration(
                      color: Color(0x66000000), shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 52),
                ),
              ),
            ),
          ),
          // Shade under the text.
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 340,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xCC000000), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          // Side actions.
          PositionedDirectional(
            end: 12,
            bottom: bottom + 8,
            child: Column(
              children: [
                _SideButton(
                  icon: muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                  onTap: onMute,
                ),
                const SizedBox(height: 14),
                _SideButton(
                  icon: Icons.outlined_flag_rounded,
                  onTap: () => reportContent(context, 'فيديو رقم ${reel.id}: ${reel.title}'),
                ),
                const SizedBox(height: 14),
                const Icon(Icons.visibility_rounded, color: Colors.white, size: 26),
                const SizedBox(height: 2),
                Text(_compact(reel.views),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ],
            ),
          ),
          // Doctor, title, description.
          PositionedDirectional(
            start: 16,
            end: 76,
            bottom: bottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (reel.doctor != null) ...[
                  _DoctorChip(doctor: reel.doctor!, onTap: () => onDoctor(reel.doctor!)),
                  const SizedBox(height: 10),
                ],
                Text(reel.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(blurRadius: 8)])),
                if (reel.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(reel.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, height: 1.5, fontSize: 13.5)),
                ],
                if (reel.doctor?.bookingEnabled == true) ...[
                  const SizedBox(height: 12),
                  PressableScale(
                    onTap: () => onBook(reel.doctor!),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: kBrandGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.event_available_rounded,
                              color: Colors.white, size: 19),
                          SizedBox(width: 6),
                          Text('احجز موعدك',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Progress, scrubbable.
          if (ready)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottom - 14,
              child: SizedBox(
                height: 4,
                child: VideoProgressIndicator(
                  c,
                  allowScrubbing: true,
                  padding: EdgeInsets.zero,
                  colors: const VideoProgressColors(
                    playedColor: Colors.white,
                    bufferedColor: Colors.white38,
                    backgroundColor: Colors.white12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _compact(int n) => n >= 1000000
      ? '${(n / 1000000).toStringAsFixed(1)} مليون'
      : n >= 1000
          ? '${(n / 1000).toStringAsFixed(1)} ألف'
          : '$n';
}

class _DoctorChip extends StatelessWidget {
  final Place doctor;
  final VoidCallback onTap;

  const _DoctorChip({required this.doctor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 14, 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: SizedBox(
                width: 36,
                height: 36,
                child: doctor.logoUrl != null
                    ? NetImage(doctor.logoUrl!, fit: BoxFit.cover)
                    : Container(
                        color: kBrandSky,
                        alignment: Alignment.center,
                        child: const Text('🩺')),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(doctor.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5)),
                  if (doctor.specialty != null)
                    Text(doctor.specialty!,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11.5)),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_left_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SideButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => PressableScale(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      );
}
