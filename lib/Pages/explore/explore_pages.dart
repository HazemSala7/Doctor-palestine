import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/animations/effects.dart';
import 'package:clinic_dr_alla/Components/brand_widgets.dart';
import 'package:clinic_dr_alla/Components/ui_kit.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/Pages/places/places_page.dart';
import 'package:clinic_dr_alla/data/models.dart';
import 'package:clinic_dr_alla/data/repository.dart';
import 'package:flutter/material.dart';

/// Gradient page header shared by the explore screens.
class _ExploreHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> colors;

  const _ExploreHeader({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      child: AuroraBackground(
        colors: colors,
        child: Stack(
          children: [
            const Positioned.fill(child: FloatingBubbles(count: 12)),
            PositionedDirectional(
              end: 18,
              top: topInset + 4,
              child: FloatingWidget(
                distance: 8,
                child: Text(emoji, style: const TextStyle(fontSize: 58)),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassButton(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 19),
                  ),
                  const SizedBox(height: 24),
                  FadeSlideIn(
                    offset: const Offset(0.2, 0),
                    child: Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900)),
                  ),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    offset: const Offset(0.2, 0),
                    child: Text(subtitle,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CitiesScreen extends StatelessWidget {
  const CitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBrandSurface,
      body: FutureBuilder<List<City>>(
        future: Repository.cities(),
        builder: (context, snap) {
          final cities = snap.data ?? [];
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: _ExploreHeader(
                  title: 'المدن',
                  subtitle: 'اختر مدينتك لتصفح أطبائها ومراكزها',
                  emoji: '🗺️',
                  colors: [Color(0xFF0D47A1), Color(0xFF26C6DA)],
                ),
              ),
              if (snap.connectionState != ConnectionState.done)
                const SliverFillRemaining(child: AppLoader())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                  sliver: SliverGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.05,
                    children: [
                      for (var i = 0; i < cities.length; i++)
                        FadeSlideIn.item(
                            index: i, child: _CityCard(city: cities[i])),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CityCard extends StatelessWidget {
  final City city;
  const _CityCard({required this.city});

  @override
  Widget build(BuildContext context) {
    final doctors = Repository.countFor(PlaceKind.doctor, cityId: city.id);
    return TiltOnTouch(
      child: PressableScale(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PlacesPage(kind: PlaceKind.doctor, initialCityId: city.id),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [city.color, Color.lerp(city.color, Colors.white, 0.45)!],
            ),
            boxShadow: [
              BoxShadow(
                color: city.color.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (city.imageUrl != null)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Opacity(
                      opacity: 0.35,
                      child: NetImage(city.imageUrl!, fit: BoxFit.cover),
                    ),
                  ),
                ),
              PositionedDirectional(
                top: 10,
                end: 12,
                child: FloatingWidget(
                  distance: 5,
                  period: Duration(milliseconds: 2000 + city.id * 200),
                  child: Text(city.emoji, style: const TextStyle(fontSize: 46)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(city.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                    if (doctors > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('$doctors طبيب',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SpecialtiesScreen extends StatelessWidget {
  const SpecialtiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = Repository.specialties();
    return Scaffold(
      backgroundColor: kBrandSurface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(
            child: _ExploreHeader(
              title: 'التخصصات',
              subtitle: 'كل تخصص وأفضل أطبائه في مكان واحد',
              emoji: '🩺',
              colors: [Color(0xFF3949AB), Color(0xFF42A5F5)],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
            sliver: SliverGrid.count(
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.82,
              children: [
                for (var i = 0; i < list.length; i++)
                  FadeSlideIn.item(index: i, child: _SpecialtyTile(s: list[i])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecialtyTile extends StatelessWidget {
  final Specialty s;
  const _SpecialtyTile({required this.s});

  @override
  Widget build(BuildContext context) {
    final count = Repository.countForSpecialty(s.name);
    return PressableScale(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PlacesPage(kind: PlaceKind.doctor, initialSpecialty: s.name),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: softShadow(s.color),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 62,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  s.color.withValues(alpha: 0.25),
                  s.color.withValues(alpha: 0.06),
                ]),
              ),
              child: Text(s.emoji, style: const TextStyle(fontSize: 30)),
            ),
            const SizedBox(height: 8),
            Text(s.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: kBrandText,
                    height: 1.2)),
            if (count > 0)
              Text('$count أطباء',
                  style: TextStyle(
                      color: s.color,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  int? _cityId;
  List<City> _cities = [];
  late Future<List<Job>> _future = Repository.jobs();

  @override
  void initState() {
    super.initState();
    Repository.cities().then((c) {
      if (mounted) setState(() => _cities = c);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBrandSurface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(
            child: _ExploreHeader(
              title: 'وظائف القطاع الطبي',
              subtitle: 'فرص عمل جديدة في المستشفيات والمراكز',
              emoji: '💼',
              colors: [Color(0xFFEF6C00), Color(0xFFFFB74D)],
            ),
          ),
          if (_cities.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 6),
                child: ChoiceChipsRow<int>(
                  values: [null, ..._cities.map((c) => c.id)],
                  selected: _cityId,
                  activeColors: const [Color(0xFFEF6C00), Color(0xFFFFB74D)],
                  label: (id) => id == null
                      ? 'كل المدن'
                      : _cities.firstWhere((c) => c.id == id).name,
                  onSelected: (id) => setState(() {
                    _cityId = id;
                    _future = Repository.jobs(cityId: id);
                  }),
                ),
              ),
            ),
          FutureBuilder<List<Job>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SliverFillRemaining(child: AppLoader());
              }
              final jobs = snap.data ?? [];
              if (jobs.isEmpty) {
                return const SliverFillRemaining(
                    hasScrollBody: false, child: EmptyState());
              }
              return SliverPadding(
                padding: const EdgeInsets.only(top: 10, bottom: 30),
                sliver: SliverList.builder(
                  itemCount: jobs.length,
                  itemBuilder: (context, i) =>
                      FadeSlideIn.item(index: i, child: _JobCard(job: jobs[i])),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Job job;
  const _JobCard({required this.job});

  static const _orange = Color(0xFFEF6C00);

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      pressedScale: 0.97,
      onTap: () => _showDetails(context),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: softShadow(_orange),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(colors: [
                  _orange.withValues(alpha: 0.18),
                  const Color(0xFFFFB74D).withValues(alpha: 0.12),
                ]),
              ),
              child: Text(job.emoji, style: const TextStyle(fontSize: 30)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                          color: kBrandText)),
                  Text(job.employer,
                      style:
                          const TextStyle(color: kBrandMuted, fontSize: 12.5)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _chip('📍 ${job.city}', kBrandPrimary),
                      if (job.type.isNotEmpty) _chip(job.type, _orange),
                      if (job.salary != null)
                        _chip('💰 ${job.salary}', kBrandSuccess),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  job.postedDaysAgo == 0
                      ? 'جديد'
                      : 'منذ ${job.postedDaysAgo} يوم',
                  style: TextStyle(
                    color: job.postedDaysAgo == 0 ? kBrandSuccess : kBrandMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                const Icon(Icons.chevron_left_rounded, color: kBrandMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 11.5, fontWeight: FontWeight.w700)),
      );

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2EAF5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(job.emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: kBrandText)),
                      Text('${job.employer} • ${job.city}',
                          style: const TextStyle(color: kBrandMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              if (job.type.isNotEmpty) _chip(job.type, _orange),
              if (job.salary != null) _chip('💰 ${job.salary}', kBrandSuccess),
            ]),
            const SizedBox(height: 16),
            Text(job.description,
                style: const TextStyle(height: 1.7, color: Color(0xFF3B4A63))),
            const SizedBox(height: 22),
            if (job.phone.isNotEmpty)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        minimumSize: const Size.fromHeight(54),
                      ),
                      onPressed: () => openWhatsApp(job.phone,
                          'مرحباً، أرغب بالتقدم لوظيفة ${job.title}'),
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('قدّم الآن عبر واتساب'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  PressableScale(
                    onTap: () => callNumber(job.phone),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: kBrandSuccess,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child:
                          const Icon(Icons.call_rounded, color: Colors.white),
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
