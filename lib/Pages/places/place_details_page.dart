import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/animations/effects.dart';
import 'package:clinic_dr_alla/Components/ui_kit.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/Local/Provider/favourite_provider/favourite_provider.dart';
import 'package:clinic_dr_alla/Pages/google_map_screen/google_map_screen.dart';
import 'package:clinic_dr_alla/data/models.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PlaceDetailsPage extends StatefulWidget {
  final Place place;

  const PlaceDetailsPage({super.key, required this.place});

  @override
  State<PlaceDetailsPage> createState() => _PlaceDetailsPageState();
}

class _PlaceDetailsPageState extends State<PlaceDetailsPage> {
  final _scroll = ScrollController();
  double _collapse = 0;
  bool _aboutExpanded = false;

  static const _days = [
    'السبت',
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة'
  ];
  static const _expanded = 330.0;

  Place get p => widget.place;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final v =
          (_scroll.offset / (_expanded - kToolbarHeight - 40)).clamp(0.0, 1.0);
      if ((v - _collapse).abs() > 0.01) setState(() => _collapse = v);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String _hour(int h) {
    final suffix = h < 12 ? 'ص' : 'م';
    final v = h % 12 == 0 ? 12 : h % 12;
    return '$v:00 $suffix';
  }

  void _openMap() {
    if (p.lat == null || p.lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الموقع غير متوفر حالياً')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            GoogleMapScreen(hospitalName: p.name, lat: p.lat!, lng: p.lng!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFav =
        context.select<FavoriteProvider, bool>((f) => f.isFavorite(p.id));
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: kBrandSurface,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: _expanded,
                pinned: true,
                stretch: true,
                automaticallyImplyLeading: false,
                backgroundColor: p.kind.colors.first,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'cover-${p.id}',
                        child: PlaceCover(place: p, emojiSize: 110),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x55000000),
                              Colors.transparent,
                              Color(0x66000000)
                            ],
                            stops: [0, 0.4, 1],
                          ),
                        ),
                      ),
                      const FloatingBubbles(count: 12),
                    ],
                  ),
                ),
                title: Opacity(
                  opacity: _collapse,
                  child: Text(p.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17)),
                ),
                centerTitle: true,
              ),
              SliverToBoxAdapter(child: _sheet()),
            ],
          ),
          // Floating glass controls stay above the collapsing header.
          Positioned(
            top: topInset + 8,
            left: 12,
            right: 12,
            child: Row(
              children: [
                GlassButton(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 19),
                ),
                const Spacer(),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 44,
                    height: 44,
                    color: Colors.white.withValues(alpha: 0.2),
                    child: OverflowBox(
                      maxWidth: 60,
                      maxHeight: 60,
                      child: HeartBurstButton(
                        active: isFav,
                        size: 24,
                        onTap: () => toggleFavorite(context, p),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _actionBar(),
    );
  }

  Widget _sheet() {
    final color = p.kind.colors.first;
    return Container(
      transform: Matrix4.translationValues(0, -34, 0),
      decoration: const BoxDecoration(
        color: kBrandSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Identity card.
          FadeSlideIn(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: softShadow(color),
              ),
              child: Row(
                children: [
                  HeartbeatPulse(
                      strength: 0.03, child: PlaceAvatar(place: p, size: 74)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(p.name,
                                  style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                      color: kBrandText)),
                            ),
                            if (p.verified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded,
                                  color: kBrandLight, size: 20),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: p.kind.gradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(p.subtitle,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (p.rating != null)
                              Row(mainAxisSize: MainAxisSize.min, children: [
                                StarRating(rating: p.rating!, size: 15),
                                const SizedBox(width: 4),
                                Text(
                                    '${p.rating!.toStringAsFixed(1)} (${p.reviews ?? 0})',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: kBrandMuted,
                                        fontWeight: FontWeight.w600)),
                              ]),
                            OpenStatusBadge(place: p, compact: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats.
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  if (p.experience != null)
                    _stat('🏅', p.experience!, 'سنوات خبرة', color),
                  if (p.reviews != null)
                    _stat('💬', p.reviews!, 'مراجعة', color),
                  if (p.fee != null)
                    _stat('💳', p.fee!, 'سعر الكشف', color, suffix: ' ₪')
                  else if (p.rating != null)
                    _stat('⭐', p.rating!, 'التقييم', color, decimals: 1),
                ],
              ),
            ),
          ),

          if (p.tags.isNotEmpty)
            FadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in p.tags)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: color.withValues(alpha: 0.15)),
                        ),
                        child: Text('✓ $t',
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5)),
                      ),
                  ],
                ),
              ),
            ),

          // About.
          if (p.description.isNotEmpty)
            _section(
              delay: 240,
              title: p.kind == PlaceKind.doctor ? 'عن الطبيب' : 'نبذة',
              emoji: '📋',
              child: GestureDetector(
                onTap: () => setState(() => _aboutExpanded = !_aboutExpanded),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.description,
                        maxLines: _aboutExpanded ? null : 3,
                        overflow: _aboutExpanded ? null : TextOverflow.ellipsis,
                        style: const TextStyle(
                            height: 1.7,
                            color: Color(0xFF3B4A63),
                            fontSize: 14),
                      ),
                      if (p.description.length > 110)
                        Text(_aboutExpanded ? 'عرض أقل' : 'اقرأ المزيد',
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w800,
                                fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),

          // Working hours.
          if (p.hasHours)
            _section(
              delay: 300,
              title: 'ساعات العمل',
              emoji: '🕒',
              child: Column(
                children: [
                  for (var d = 0; d < 7; d++) _dayRow(d, color),
                ],
              ),
            ),

          // Location.
          _section(
            delay: 360,
            title: 'الموقع',
            emoji: '📍',
            child: PressableScale(
              pressedScale: 0.97,
              onTap: _openMap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 140,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AuroraBackground(colors: [
                        color.withValues(alpha: 0.85),
                        p.kind.colors.last
                      ]),
                      CustomPaint(painter: _MapGridPainter()),
                      const Center(
                        child: FloatingWidget(
                          distance: 10,
                          period: Duration(milliseconds: 1200),
                          child: Text('📍', style: TextStyle(fontSize: 44)),
                        ),
                      ),
                      PositionedDirectional(
                        start: 12,
                        end: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.address.isNotEmpty ? p.address : p.city,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: kBrandText),
                                ),
                              ),
                              Text('افتح الخريطة',
                                  style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5)),
                              Icon(Icons.chevron_left_rounded, color: color),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _stat(String emoji, num value, String label, Color color,
      {String suffix = '', int decimals = 0}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: softShadow(color),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            CountUp(
              value: value,
              suffix: suffix,
              decimals: decimals,
              style: TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w900, color: color),
            ),
            Text(label,
                style: const TextStyle(color: kBrandMuted, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }

  Widget _section(
      {required int delay,
      required String title,
      required String emoji,
      required Widget child}) {
    return FadeSlideIn(
      delay: Duration(milliseconds: delay),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: softShadow(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: kBrandText)),
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _dayRow(int d, Color color) {
    final today = d == Place.todayIndex;
    final works = p.open24h || p.workDays.contains(d);
    final hours = p.open24h
        ? '24 ساعة'
        : works
            ? 'من ${_hour(p.opensAt!)} إلى ${_hour(p.closesAt!)}'
            : 'مغلق';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: today ? p.kind.gradient : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(_days[d],
              style: TextStyle(
                fontWeight: today ? FontWeight.w800 : FontWeight.w600,
                color: today ? Colors.white : kBrandText,
              )),
          if (today)
            const Text('  • اليوم',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
          const Spacer(),
          Text(hours,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: today
                    ? Colors.white
                    : (works ? kBrandMuted : const Color(0xFFE53935)),
              )),
        ],
      ),
    );
  }

  Widget _actionBar() {
    final bottom = MediaQuery.of(context).padding.bottom;
    return FadeSlideIn(
      offset: const Offset(0, 1),
      delay: const Duration(milliseconds: 250),
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
                color: kBrandDark.withValues(alpha: 0.1),
                blurRadius: 24,
                offset: const Offset(0, -6)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: PressableScale(
                onTap: p.phone.isEmpty ? null : () => callNumber(p.phone),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF16A34A), Color(0xFF22C55E)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: kBrandSuccess.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const HeartbeatPulse(
                        strength: 0.15,
                        child: Icon(Icons.call_rounded, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        p.kind == PlaceKind.doctor
                            ? 'اتصل واحجز موعدك'
                            : 'اتصل الآن',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _roundAction(
              const Color(0xFF25D366),
              const Icon(Icons.chat_rounded, color: Colors.white),
              p.phone.isEmpty ? null : () => openWhatsApp(p.phone),
            ),
            const SizedBox(width: 10),
            _roundAction(
              p.kind.colors.first,
              const Icon(Icons.map_rounded, color: Colors.white),
              _openMap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundAction(Color color, Widget icon, VoidCallback? onTap) =>
      PressableScale(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 6))
            ],
          ),
          child: icon,
        ),
      );
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 26) {
      canvas.drawLine(Offset(x, 0), Offset(x + 30, size.height), line);
    }
    for (double y = 0; y < size.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 12), line);
    }
    final road = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
          size.width * 0.4, size.height * 0.2, size.width, size.height * 0.45);
    canvas.drawPath(path, road);
  }

  @override
  bool shouldRepaint(_MapGridPainter old) => false;
}
