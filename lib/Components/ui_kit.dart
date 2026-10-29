import 'dart:math' as math;
import 'dart:ui';

import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/animations/effects.dart';
import 'package:clinic_dr_alla/Components/brand_widgets.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/Local/Model/FavoriteItem/FavoriteItem.dart';
import 'package:clinic_dr_alla/Local/Provider/favourite_provider/favourite_provider.dart';
import 'package:clinic_dr_alla/Pages/places/place_details_page.dart';
import 'package:clinic_dr_alla/data/models.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// ---------------------------------------------------------------------------
// Actions

Future<void> callNumber(String phone) async {
  final uri = Uri(scheme: 'tel', path: phone);
  if (await canLaunchUrl(uri)) await launchUrl(uri);
}

Future<void> openWhatsApp(String phone,
    [String text = 'مرحباً، وصلت إليك عبر تطبيق طبيبك']) async {
  final intl = phone.startsWith('0') ? '970${phone.substring(1)}' : phone;
  final uri =
      Uri.parse('https://wa.me/$intl?text=${Uri.encodeComponent(text)}');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

void openPlace(BuildContext context, Place place) {
  Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(builder: (_) => PlaceDetailsPage(place: place)),
  );
}

void toggleFavorite(BuildContext context, Place place) {
  final fav = context.read<FavoriteProvider>();
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  if (fav.isFavorite(place.id)) {
    fav.removeFavorite(place.id);
    messenger.showSnackBar(
        SnackBar(content: Text('تمت إزالة ${place.name} من المفضلة')));
  } else {
    fav.addFavorite(FavoriteItem(
      productId: place.id,
      name: place.name,
      nameEn: place.name,
      nameHe: place.name,
      desc: place.subtitle,
      image: place.coverUrl ?? '',
      // The unused `color` column stores the listing kind so favourites
      // can be reopened with the right look.
      color: place.kind.name,
    ));
    messenger.showSnackBar(
        SnackBar(content: Text('أُضيف ${place.name} إلى المفضلة ❤')));
  }
}

// ---------------------------------------------------------------------------
// Art

/// Cover for a listing: the real photo when there is one, otherwise a
/// generated gradient scene with the kind's emoji.
class PlaceCover extends StatelessWidget {
  final Place place;
  final double emojiSize;
  final bool showEmoji;

  const PlaceCover(
      {super.key,
      required this.place,
      this.emojiSize = 64,
      this.showEmoji = true});

  @override
  Widget build(BuildContext context) {
    final url = place.coverUrl;
    if (url != null && url.isNotEmpty) {
      return NetImage(url,
          fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }
    final colors = place.kind.colors;
    final shift = (place.id % 7) / 7;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-1 + shift, -1),
          end: Alignment(1, 1 - shift),
          colors: [colors[0], colors[1]],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
              child: CustomPaint(painter: _PatternPainter(place.id))),
          if (showEmoji)
            Center(
              child: Text(
                place.kind == PlaceKind.doctor
                    ? _specialtyEmoji(place)
                    : place.kind.emoji,
                style: TextStyle(fontSize: emojiSize, shadows: [
                  Shadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 18),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

String _specialtyEmoji(Place p) {
  const map = {
    'باطنية': '🫀', 'أطفال': '👶', 'أسنان': '🦷', 'نسائية وتوليد': '🤰', //
    'عيون': '👁️', 'قلب وشرايين': '❤️', 'جلدية': '🧴', 'عظام': '🦴',
    'أنف وأذن وحنجرة': '👂', 'أعصاب': '🧠', 'نفسية': '🧘', 'مسالك بولية': '💧',
  };
  return map[p.specialty] ?? '🩺';
}

class _PatternPainter extends CustomPainter {
  final int seed;
  _PatternPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(seed);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.10);
    for (var i = 0; i < 7; i++) {
      canvas.drawCircle(
        Offset(r.nextDouble() * size.width, r.nextDouble() * size.height),
        10 + r.nextDouble() * size.shortestSide * 0.35,
        paint,
      );
    }
    final cross = Paint()..color = Colors.white.withValues(alpha: 0.14);
    for (var i = 0; i < 4; i++) {
      final c =
          Offset(r.nextDouble() * size.width, r.nextDouble() * size.height);
      final s = 8 + r.nextDouble() * 14;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: c, width: s, height: s / 3),
              Radius.circular(s)),
          cross);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: c, width: s / 3, height: s),
              Radius.circular(s)),
          cross);
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) => old.seed != seed;
}

/// Round avatar: the logo when there is one, otherwise initials.
class PlaceAvatar extends StatelessWidget {
  final Place place;
  final double size;
  final bool ring;

  const PlaceAvatar(
      {super.key, required this.place, this.size = 56, this.ring = true});

  String get _initials {
    final words = place.name
        .replaceFirst('د. ', '')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    return words.take(2).map((w) => w.characters.first).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final url = place.logoUrl;
    final inner = ClipOval(
      child: url != null && url.isNotEmpty
          ? NetImage(url, width: size, height: size, fit: BoxFit.cover)
          : Container(
              width: size,
              height: size,
              decoration: BoxDecoration(gradient: place.kind.gradient),
              alignment: Alignment.center,
              child: place.kind == PlaceKind.doctor
                  ? Text(
                      _initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: size * 0.3,
                      ),
                    )
                  : Text(place.kind.emoji,
                      style: TextStyle(fontSize: size * 0.45)),
            ),
    );
    if (!ring) return inner;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(colors: [
          place.kind.colors[0],
          place.kind.colors[1],
          const Color(0xFFFFC107),
          place.kind.colors[0],
        ]),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: inner,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small pieces

class OpenStatusBadge extends StatelessWidget {
  final Place place;
  final bool compact;

  const OpenStatusBadge({super.key, required this.place, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final open = place.isOpenNow;
    if (open == null) return const SizedBox.shrink();
    final color = open ? kBrandSuccess : const Color(0xFFE53935);
    final text =
        place.open24h ? 'مفتوح 24 ساعة' : (open ? 'مفتوح الآن' : 'مغلق الآن');
    return Container(
      padding: EdgeInsetsDirectional.only(
          start: 2, end: compact ? 8 : 10, top: 2, bottom: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          open ? PulsingDot(color: color, size: 6) : const SizedBox(width: 8),
          if (!open) Icon(Icons.circle, size: 6, color: color),
          if (!open) const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  color: color,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class RatingPill extends StatelessWidget {
  final Place place;
  final bool dark;

  const RatingPill({super.key, required this.place, this.dark = false});

  @override
  Widget build(BuildContext context) {
    if (place.rating == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: dark
            ? Colors.black.withValues(alpha: 0.35)
            : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 15),
          const SizedBox(width: 3),
          Text(
            place.rating!.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: dark ? Colors.white : const Color(0xFF8D6E00),
            ),
          ),
        ],
      ),
    );
  }
}

class GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double size;

  const GlassButton(
      {super.key, required this.child, this.onTap, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? emoji;
  final VoidCallback? onSeeAll;

  const SectionHeader(
      {super.key, required this.title, this.emoji, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
      child: Row(
        children: [
          if (emoji != null) ...[
            Text(emoji!, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: kBrandText),
            ),
          ),
          if (onSeeAll != null)
            PressableScale(
              onTap: onSeeAll,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: kBrandSky,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('عرض الكل',
                        style: TextStyle(
                            color: kBrandPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5)),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_left_rounded,
                        color: kBrandPrimary, size: 18),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Horizontally scrolling single-select chips with an animated selection.
class ChoiceChipsRow<T> extends StatelessWidget {
  final List<T?> values;
  final T? selected;
  final String Function(T?) label;
  final String Function(T?)? emoji;
  final ValueChanged<T?> onSelected;
  final List<Color> activeColors;

  const ChoiceChipsRow({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.emoji,
    this.activeColors = const [kBrandPrimary, kBrandLight],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final v = values[i];
          final active = v == selected;
          return PressableScale(
            onTap: () => onSelected(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: active ? LinearGradient(colors: activeColors) : null,
                color: active ? null : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color:
                        active ? Colors.transparent : const Color(0xFFE2EAF5)),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: activeColors.first.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        )
                      ]
                    : null,
              ),
              child: Text(
                '${emoji == null ? '' : '${emoji!(v)} '}${label(v)}',
                style: TextStyle(
                  color: active ? Colors.white : kBrandText,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cards

/// Full-width list card for any listing.
class PlaceCard extends StatelessWidget {
  final Place place;

  const PlaceCard({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final isFav =
        context.select<FavoriteProvider, bool>((f) => f.isFavorite(place.id));
    final isDoctor = place.kind == PlaceKind.doctor;

    return PressableScale(
      pressedScale: 0.97,
      onTap: () => openPlace(context, place),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: softShadow(place.kind.colors.first),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'cover-${place.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: 92,
                  height: 104,
                  child: isDoctor
                      ? Container(
                          decoration:
                              BoxDecoration(gradient: place.kind.gradient),
                          alignment: Alignment.center,
                          child:
                              PlaceAvatar(place: place, size: 64, ring: false),
                        )
                      : PlaceCover(place: place, emojiSize: 40),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: kBrandText),
                        ),
                      ),
                      if (place.verified)
                        const Padding(
                          padding: EdgeInsetsDirectional.only(start: 4),
                          child: Icon(Icons.verified_rounded,
                              size: 17, color: kBrandLight),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place.subtitle,
                    style: TextStyle(
                        color: place.kind.colors.first,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 15, color: kBrandMuted),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          place.address.isNotEmpty ? place.address : place.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(color: kBrandMuted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      RatingPill(place: place),
                      if (place.rating != null) const SizedBox(width: 6),
                      Flexible(
                          child: OpenStatusBadge(place: place, compact: true)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                HeartBurstButton(
                  active: isFav,
                  size: 22,
                  inactiveColor: const Color(0xFFB0BCCD),
                  onTap: () => toggleFavorite(context, place),
                ),
                const SizedBox(height: 12),
                if (place.phone.isNotEmpty)
                  PressableScale(
                    onTap: () => callNumber(place.phone),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF16A34A), Color(0xFF4ADE80)]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: kBrandSuccess.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.call_rounded,
                          color: Colors.white, size: 19),
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

class PlaceCardSkeleton extends StatelessWidget {
  const PlaceCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: const Row(
          children: [
            SkeletonBox(width: 92, height: 104, radius: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 150, height: 14),
                  SizedBox(height: 10),
                  SkeletonBox(width: 90, height: 11),
                  SizedBox(height: 10),
                  SkeletonBox(width: 180, height: 11),
                  SizedBox(height: 14),
                  SkeletonBox(width: 110, height: 20, radius: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tall card for horizontal carousels of doctors.
class DoctorSpotlightCard extends StatelessWidget {
  final Place place;

  const DoctorSpotlightCard({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    return TiltOnTouch(
      child: PressableScale(
        pressedScale: 0.96,
        onTap: () => openPlace(context, place),
        child: Container(
          width: 172,
          margin: const EdgeInsetsDirectional.only(end: 14, bottom: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: softShadow(kBrandPrimary),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 120,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(28)),
                        child: Hero(
                          tag: 'cover-${place.id}',
                          child: PlaceCover(place: place, showEmoji: false),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: 10,
                      start: 10,
                      child: RatingPill(place: place, dark: true),
                    ),
                    Positioned(
                      bottom: -30,
                      left: 0,
                      right: 0,
                      child: Center(child: PlaceAvatar(place: place, size: 64)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 38),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: kBrandText),
                ),
              ),
              Text(
                place.subtitle,
                style: const TextStyle(
                    color: kBrandPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 13, color: kBrandMuted),
                  Text(place.city,
                      style:
                          const TextStyle(color: kBrandMuted, fontSize: 11.5)),
                  if (place.experience != null) ...[
                    const Text('  •  ',
                        style: TextStyle(color: kBrandMuted, fontSize: 11.5)),
                    Text('${place.experience} سنة',
                        style: const TextStyle(
                            color: kBrandMuted, fontSize: 11.5)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows skeleton cards while loading, an empty state, or the list.
Widget placesSliver(AsyncSnapshot<List<Place>> snap, {String? emptyTitle}) {
  if (snap.connectionState != ConnectionState.done) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, __) => const PlaceCardSkeleton(),
        childCount: 5,
      ),
    );
  }
  final list = snap.data ?? const <Place>[];
  if (list.isEmpty) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: emptyTitle == null
          ? const EmptyState()
          : EmptyState(title: emptyTitle),
    );
  }
  return SliverList(
    delegate: SliverChildBuilderDelegate(
      (context, i) =>
          FadeSlideIn.item(index: i, child: PlaceCard(place: list[i])),
      childCount: list.length,
    ),
  );
}
