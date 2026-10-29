import 'dart:async';

import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/animations/effects.dart';
import 'package:clinic_dr_alla/Components/brand_widgets.dart';
import 'package:clinic_dr_alla/Components/ui_kit.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/Pages/explore/explore_pages.dart';
import 'package:clinic_dr_alla/Pages/places/places_page.dart';
import 'package:clinic_dr_alla/data/demo_data.dart';
import 'package:clinic_dr_alla/data/models.dart';
import 'package:clinic_dr_alla/data/repository.dart';
import 'package:clinic_dr_alla/model/slider_model.dart';
import 'package:clinic_dr_alla/services/functions.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  final void Function(int) changeTabIndex;
  final Function(String) onLanguageSelected;
  final VoidCallback onSearch;

  const MainScreen({
    super.key,
    required this.changeTabIndex,
    required this.onLanguageSelected,
    required this.onSearch,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

/// A home-screen shortcut: either a listing kind or a dedicated screen.
class _Service {
  final String label;
  final String? asset;
  final String emoji;
  final List<Color> colors;
  final WidgetBuilder page;

  const _Service(this.label, this.asset, this.emoji, this.colors, this.page);
}

class _MainScreenState extends State<MainScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late Future<List<Place>> _featured = Repository.featuredDoctors();
  late Future<List<Place>> _pharmacies = Repository.onDutyPharmacies();

  late final List<_Service> _services = [
    _Service(
        'المدن',
        'assets/images/cityscape.png',
        '🗺️',
        const [Color(0xFF0D47A1), Color(0xFF26C6DA)],
        (_) => const CitiesScreen()),
    _Service('الأطباء', PlaceKind.doctor.asset, '🩺', PlaceKind.doctor.colors,
        (_) => const PlacesPage(kind: PlaceKind.doctor)),
    _Service(
        'التخصصات',
        'assets/images/doctor-categories.png',
        '🩺',
        const [Color(0xFF3949AB), Color(0xFF42A5F5)],
        (_) => const SpecialtiesScreen()),
    for (final k in PlaceKind.values.skip(1))
      _Service(k.short, k.asset, k.emoji, k.colors, (_) => PlacesPage(kind: k)),
  ];

  Future<void> _refresh() async {
    setState(() {
      _featured = Repository.featuredDoctors();
      _pharmacies = Repository.onDutyPharmacies();
    });
    await Future.wait([_featured, _pharmacies]);
  }

  void _push(WidgetBuilder b) =>
      Navigator.push(context, MaterialPageRoute(builder: b));

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: kBrandSurface,
      body: RefreshIndicator(
        color: kBrandPrimary,
        edgeOffset: 120,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _hero()),
            SliverToBoxAdapter(child: _promos()),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'التخصصات',
                emoji: '🩺',
                onSeeAll: () => _push((_) => const SpecialtiesScreen()),
              ),
            ),
            SliverToBoxAdapter(child: _specialtyStories()),
            const SliverToBoxAdapter(
                child: SectionHeader(title: 'خدماتنا الطبية', emoji: '✨')),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              sliver: SliverGrid.count(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 10,
                childAspectRatio: 0.74,
                children: [
                  for (var i = 0; i < _services.length; i++)
                    FadeSlideIn.item(
                        index: i, child: _serviceTile(_services[i], i)),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'أطباء مميزون',
                emoji: '⭐',
                onSeeAll: () => widget.changeTabIndex(1),
              ),
            ),
            SliverToBoxAdapter(child: _featuredDoctors()),
            SliverToBoxAdapter(child: _emergencyCard()),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'صيدليات مفتوحة الآن',
                emoji: '💊',
                onSeeAll: () =>
                    _push((_) => const PlacesPage(kind: PlaceKind.pharmacy)),
              ),
            ),
            SliverToBoxAdapter(child: _pharmaciesRow()),
            SliverToBoxAdapter(child: _jobsBanner()),
            SliverToBoxAdapter(child: _footer()),
            const SliverToBoxAdapter(child: SizedBox(height: 130)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'صباح الخير ☀️';
    if (h < 18) return 'نهارك سعيد 🌤️';
    return 'مساء الخير 🌙';
  }

  Widget _hero() {
    final topInset = MediaQuery.of(context).padding.top;
    final doctors = Repository.countFor(PlaceKind.doctor);
    final centers = PlaceKind.values
        .skip(1)
        .fold<int>(0, (s, k) => s + Repository.countFor(k));

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      child: AuroraBackground(
        colors: const [kBrandDark, kBrandPrimary, Color(0xFF29B6F6)],
        child: Stack(
          children: [
            const Positioned.fill(child: FloatingBubbles(count: 20)),
            Padding(
              padding: EdgeInsets.fromLTRB(18, topInset + 14, 18, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FadeSlideIn(
                        offset: const Offset(-0.3, 0),
                        fromScale: 0.7,
                        child: HeartbeatPulse(
                          strength: 0.05,
                          child: Container(
                            height: 54,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: kBrandDark.withValues(alpha: 0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ShimmerSweep(
                              period: const Duration(milliseconds: 4200),
                              child: Image.asset(kLogoAsset),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FadeSlideIn(
                          delay: const Duration(milliseconds: 120),
                          offset: const Offset(0.2, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_greeting,
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.85),
                                      fontSize: 13.5)),
                              const Text('كيف نساعدك اليوم؟',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      height: 1.25)),
                            ],
                          ),
                        ),
                      ),
                      GlassButton(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('لا توجد إشعارات جديدة 🔔'))),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.notifications_none_rounded,
                                color: Colors.white),
                            const PositionedDirectional(
                              top: -6,
                              end: -6,
                              child:
                                  PulsingDot(color: Color(0xFFFF3D6E), size: 7),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 220),
                    child: PressableScale(
                      pressedScale: 0.97,
                      onTap: widget.onSearch,
                      child: Hero(
                        tag: 'search-bar',
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded,
                                    color: kBrandPrimary),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text('ابحث عن طبيب، تخصص، صيدلية...',
                                      style: TextStyle(
                                          color: kBrandMuted, fontSize: 14)),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: kBrandGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.tune_rounded,
                                      color: Colors.white, size: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const EcgLine(
                      height: 30,
                      strokeWidth: 2,
                      period: Duration(milliseconds: 2600)),
                  if (kUseDemoData)
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 320),
                      child: Row(
                        children: [
                          _heroStat(doctors, 'طبيب', '🩺'),
                          _heroStat(centers, 'مركز وصيدلية', '🏥'),
                          _heroStat(DemoData.cities.length, 'مدن', '📍'),
                        ],
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

  Widget _heroStat(int value, String label, String emoji) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  CountUp(
                    value: value,
                    prefix: '+',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17),
                  ),
                ],
              ),
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11.5)),
            ],
          ),
        ),
      );

  Widget _promos() {
    if (kUseDemoData) return const _PromoCarousel(promos: DemoData.promos);
    return FutureBuilder(
      future: getSliders(),
      builder: (context, AsyncSnapshot snap) {
        final List raw = (snap.data is Map ? snap.data['sliders'] : null) ?? [];
        if (raw.isEmpty) return const SizedBox(height: 8);
        final slides = raw.map((e) => SliderModel.fromJson(e)).toList();
        return SizedBox(
          height: 170,
          child: PageView(
            controller: PageController(viewportFraction: 0.88),
            children: [
              for (final s in slides)
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 18, 6, 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: NetImage(s.image,
                        fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _specialtyStories() {
    final list = Repository.specialties();
    return SizedBox(
      height: 104,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final s = list[i];
          return FadeSlideIn.item(
            index: i,
            child: PressableScale(
              onTap: () => _push((_) =>
                  PlacesPage(kind: PlaceKind.doctor, initialSpecialty: s.name)),
              child: SizedBox(
                width: 80,
                child: Column(
                  children: [
                    _StoryRing(
                      color: s.color,
                      child:
                          Text(s.emoji, style: const TextStyle(fontSize: 28)),
                    ),
                    const SizedBox(height: 6),
                    Text(s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: kBrandText)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _serviceTile(_Service s, int i) {
    return PressableScale(
      onTap: () => _push(s.page),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: s.colors.first.withValues(alpha: 0.16),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  PositionedDirectional(
                    top: -14,
                    end: -14,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [
                          s.colors.last.withValues(alpha: 0.35),
                          s.colors.first.withValues(alpha: 0.12),
                        ]),
                      ),
                    ),
                  ),
                  Center(
                    child: FloatingWidget(
                      distance: 3,
                      period: Duration(milliseconds: 2200 + (i % 5) * 300),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: s.asset != null
                            ? Image.asset(s.asset!, fit: BoxFit.contain)
                            : Text(s.emoji,
                                style: const TextStyle(fontSize: 30)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            s.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800, color: kBrandText),
          ),
        ],
      ),
    );
  }

  Widget _featuredDoctors() {
    return SizedBox(
      height: 262,
      child: FutureBuilder<List<Place>>(
        future: _featured,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: List.generate(
                3,
                (_) => const Padding(
                  padding: EdgeInsetsDirectional.only(end: 14, bottom: 18),
                  child: Skeleton(
                      child: SkeletonBox(width: 172, height: 240, radius: 28)),
                ),
              ),
            );
          }
          final list = snap.data ?? [];
          if (list.isEmpty)
            return const EmptyState(title: 'لا يوجد أطباء حالياً');
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: list.length,
            itemBuilder: (context, i) => FadeSlideIn(
              delay: Duration(milliseconds: 80 * (i % 6)),
              offset: const Offset(0.4, 0),
              child: DoctorSpotlightCard(place: list[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _emergencyCard() {
    return FadeSlideIn(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: PressableScale(
          pressedScale: 0.97,
          onTap: () => callNumber('101'),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: AuroraBackground(
              colors: const [Color(0xFFC62828), Color(0xFFFF5252)],
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const HeartbeatPulse(
                      strength: 0.12,
                      child: Text('🚑', style: TextStyle(fontSize: 44)),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('حالة طارئة؟',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900)),
                          Text('اتصل بالإسعاف فوراً على الرقم 101',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.call_rounded,
                              color: Color(0xFFC62828), size: 18),
                          SizedBox(width: 4),
                          Text('101',
                              style: TextStyle(
                                  color: Color(0xFFC62828),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pharmaciesRow() {
    return SizedBox(
      height: 132,
      child: FutureBuilder<List<Place>>(
        future: _pharmacies,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: List.generate(
                2,
                (_) => const Padding(
                  padding: EdgeInsetsDirectional.only(end: 12, bottom: 14),
                  child: Skeleton(
                      child: SkeletonBox(width: 260, height: 118, radius: 24)),
                ),
              ),
            );
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(
                child: Text('لا توجد صيدليات مفتوحة حالياً',
                    style: TextStyle(color: kBrandMuted)));
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final p = list[i];
              return FadeSlideIn(
                delay: Duration(milliseconds: 80 * (i % 6)),
                offset: const Offset(0.4, 0),
                child: PressableScale(
                  pressedScale: 0.96,
                  onTap: () => openPlace(context, p),
                  child: Container(
                    width: 260,
                    margin:
                        const EdgeInsetsDirectional.only(end: 12, bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: softShadow(p.kind.colors.first),
                    ),
                    child: Row(
                      children: [
                        Hero(
                          tag: 'cover-${p.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: SizedBox(
                                width: 80,
                                height: 94,
                                child: PlaceCover(place: p, emojiSize: 36)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: kBrandText)),
                              Text('📍 ${p.city}',
                                  style: const TextStyle(
                                      color: kBrandMuted, fontSize: 12)),
                              const SizedBox(height: 6),
                              OpenStatusBadge(place: p, compact: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _jobsBanner() {
    return FadeSlideIn(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: PressableScale(
          pressedScale: 0.97,
          onTap: () => _push((_) => const JobsScreen()),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: AuroraBackground(
              colors: const [Color(0xFFEF6C00), Color(0xFFFFB74D)],
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تبحث عن عمل؟',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900)),
                          Text('وظائف جديدة في القطاع الطبي كل يوم',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 13)),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Text('تصفح الوظائف',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800)),
                              Icon(Icons.chevron_left_rounded,
                                  color: Colors.white),
                            ],
                          ),
                        ],
                      ),
                    ),
                    FloatingWidget(
                      distance: 8,
                      child: Image.asset('assets/images/job.png', height: 76),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        children: [
          Opacity(opacity: 0.6, child: Image.asset(kLogoAsset, height: 48)),
          const SizedBox(height: 6),
          const Text('صُنع بحب في فلسطين 🇵🇸',
              style:
                  TextStyle(color: kBrandMuted, fontWeight: FontWeight.w600)),
          if (kUseDemoData)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('وضع البيانات التجريبية',
                  style: TextStyle(
                      color: Color(0xFFEF6C00),
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

/// Gradient ring like a "story" avatar, slowly rotating.
class _StoryRing extends StatefulWidget {
  final Color color;
  final Widget child;
  const _StoryRing({required this.color, required this.child});

  @override
  State<_StoryRing> createState() => _StoryRingState();
}

class _StoryRingState extends State<_StoryRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: _c,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(colors: [
                  widget.color,
                  const Color(0xFFFFC107),
                  kBrandLight,
                  widget.color,
                ]),
              ),
            ),
          ),
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.1),
              ),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Auto-playing promo banners with a parallax scale effect.
class _PromoCarousel extends StatefulWidget {
  final List<Promo> promos;
  const _PromoCarousel({required this.promos});

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  final _controller = PageController(viewportFraction: 0.86);
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      final next = (_page + 1) % widget.promos.length;
      _controller.animateToPage(next,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic);
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
    return Column(
      children: [
        const SizedBox(height: 18),
        SizedBox(
          height: 164,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.promos.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) => AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                double d = 0;
                if (_controller.hasClients &&
                    _controller.position.haveDimensions) {
                  d = (_controller.page! - i).clamp(-1.0, 1.0);
                }
                return Transform.scale(
                    scale: 1 - d.abs() * 0.08,
                    child: _banner(widget.promos[i], d));
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < widget.promos.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  gradient: i == _page ? kBrandGradient : null,
                  color: i == _page ? null : const Color(0xFFCFDAEA),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _banner(Promo p, double d) {
    return PressableScale(
      pressedScale: 0.97,
      onTap: p.kind == null
          ? null
          : () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => PlacesPage(kind: p.kind!))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: p.colors.first.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: AuroraBackground(
            colors: p.colors,
            child: Stack(
              children: [
                const Positioned.fill(child: FloatingBubbles(count: 8)),
                PositionedDirectional(
                  end: 10 + d * 40,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: FloatingWidget(
                      distance: 8,
                      child:
                          Text(p.emoji, style: const TextStyle(fontSize: 70)),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsetsDirectional.fromSTEB(20, 18, 120, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(p.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              height: 1.3)),
                      const SizedBox(height: 4),
                      Text(p.subtitle,
                          maxLines: 2,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12.5)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text('اكتشف الآن',
                            style: TextStyle(
                                color: p.colors.first,
                                fontWeight: FontWeight.w800,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
