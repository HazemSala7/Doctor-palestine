import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/brand_widgets.dart';
import 'package:clinic_dr_alla/Components/ui_kit.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/Pages/booking/book_appointment_page.dart';
import 'package:clinic_dr_alla/Pages/booking/booking_widgets.dart';
import 'package:clinic_dr_alla/Pages/places/place_details_page.dart';
import 'package:clinic_dr_alla/data/app_config.dart';
import 'package:clinic_dr_alla/data/models.dart';
import 'package:clinic_dr_alla/data/repository.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _seenKey = 'premium_ads_seen';
const _sponsorSeenKey = 'sponsor_ads_seen';
const gold = [Color(0xFFFFE082), Color(0xFFE0A800), Color(0xFFB8860B)];

/// The home screen can be rebuilt (after a login, say) without the user
/// having left the app; that isn't a new entry.
bool _sponsorShownThisLaunch = false;
bool _sponsorOpen = false;

/// On every entry to the app: a VIP («مميز جداً») ad opens as the app's
/// exclusive sponsor, at launch and each time the user comes back to the app
/// ([returning]). Without one, a premium ad opens at launch, at most once a
/// day per ad. With several, the one shown least recently goes first.
Future<void> maybeShowPremiumAd(BuildContext context, {bool returning = false}) async {
  final vip = Repository.config.vipAds;
  if (vip.isNotEmpty) {
    if (_sponsorOpen || (!returning && _sponsorShownThisLaunch)) return;
    return _showSponsor(context, vip);
  }
  if (returning) return;

  final ads = Repository.config.premiumAds;
  if (ads.isEmpty) return;

  final prefs = await SharedPreferences.getInstance();
  Map<String, dynamic> seen;
  try {
    seen = jsonDecode(prefs.getString(_seenKey) ?? '{}');
  } catch (_) {
    seen = {};
  }
  final now = DateTime.now();
  final today = '${now.year}-${now.month}-${now.day}';
  final due = ads.where((a) => seen['${a.id}'] != today).toList()
    ..sort((a, b) => '${seen['${a.id}'] ?? ''}'.compareTo('${seen['${b.id}'] ?? ''}'));
  if (due.isEmpty || !context.mounted) return;

  final ad = due.first;
  // Open with the picture already loaded; a slow network shouldn't show a blank card.
  try {
    await precacheImage(NetworkImage(ad.image), context)
        .timeout(const Duration(seconds: 5));
  } catch (_) {}
  if (!context.mounted) return;

  seen['${ad.id}'] = today;
  await prefs.setString(_seenKey, jsonEncode(seen));
  if (!context.mounted) return;

  await showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 450),
    pageBuilder: (_, __, ___) => PremiumAdWindow(ad: ad),
    transitionBuilder: (_, a, __, child) {
      final c = CurvedAnimation(parent: a, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(c), child: child),
      );
    },
  );
}

Future<void> _showSponsor(BuildContext context, List<Ad> ads) async {
  _sponsorShownThisLaunch = true;
  _sponsorOpen = true;
  try {
    await _openSponsor(context, ads);
  } finally {
    _sponsorOpen = false;
  }
}

Future<void> _openSponsor(BuildContext context, List<Ad> ads) async {
  final prefs = await SharedPreferences.getInstance();
  Map<String, dynamic> seen;
  try {
    seen = jsonDecode(prefs.getString(_sponsorSeenKey) ?? '{}');
  } catch (_) {
    seen = {};
  }
  // Least recently shown first; never-shown ones (0) lead.
  int last(Ad a) => (seen['${a.id}'] as num?)?.toInt() ?? 0;
  final ad = ([...ads]..sort((a, b) => last(a).compareTo(last(b)))).first;
  if (!context.mounted) return;

  // Open with the pictures already loaded; a slow network shouldn't show blanks.
  final photo = ad.place!.logoUrl;
  try {
    await Future.wait([
      // A picture that fails to load just shows its fallback; nothing to report.
      precacheImage(NetworkImage(ad.image), context, onError: (_, __) {}),
      if (photo != null)
        precacheImage(NetworkImage(photo), context, onError: (_, __) {}),
    ]).timeout(const Duration(seconds: 5));
  } catch (_) {}
  if (!context.mounted) return;

  seen['${ad.id}'] = DateTime.now().millisecondsSinceEpoch;
  await prefs.setString(_sponsorSeenKey, jsonEncode(seen));
  if (!context.mounted) return;

  await showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (_, __, ___) => SponsorWindow(ad: ad),
    transitionBuilder: (_, a, __, child) {
      final c = CurvedAnimation(parent: a, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(c), child: child),
      );
    },
  );
}

/// The app's exclusive sponsor: the doctor's or centre's photo, name and
/// details up front, under the ad's picture, with the offer and a way to book.
class SponsorWindow extends StatelessWidget {
  final Ad ad;

  const SponsorWindow({super.key, required this.ad});

  static const _headerHeight = 150.0;
  static const _photo = 116.0;

  @override
  Widget build(BuildContext context) {
    final place = ad.place!;
    final bookable = place.kind == PlaceKind.doctor && place.bookingEnabled;
    final rating = place.rating;
    final details = [place.subtitle, if (place.city.isNotEmpty) place.city].join(' • ');

    void go([Widget? page]) {
      final nav = Navigator.of(context);
      nav.pop();
      if (page != null) nav.push(MaterialPageRoute(builder: (_) => page));
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gold),
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: [
                    BoxShadow(color: kSponsoredGold.withValues(alpha: 0.45), blurRadius: 30),
                  ],
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(31),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // The ad's picture under a deep tint, with the title.
                            SizedBox(
                              height: _headerHeight,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  NetImage(ad.image, fit: BoxFit.cover),
                                  const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Color(0xE60B1F44), Color(0x990B1F44)],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        FadeSlideIn(
                                          child: ShimmerSweep(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 5),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(colors: gold),
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: const Text('👑 الراعي الحصري',
                                                  style: TextStyle(
                                                      color: Color(0xFF3E2C00),
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 13)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        FadeSlideIn(
                                          delay: const Duration(milliseconds: 100),
                                          child: Text('لتطبيق طبيبك',
                                              style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.85),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PositionedDirectional(
                                    top: 12,
                                    end: 12,
                                    child: _CountdownClose(onClose: go),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: _photo / 2 + 12),
                            // Who it is.
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              child: Column(
                                children: [
                                  FadeSlideIn(
                                    delay: const Duration(milliseconds: 200),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(place.name,
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  color: kBrandText,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 21,
                                                  height: 1.3)),
                                        ),
                                        if (place.verified) ...[
                                          const SizedBox(width: 5),
                                          const Icon(Icons.verified_rounded,
                                              color: kBrandPrimary, size: 20),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  FadeSlideIn(
                                    delay: const Duration(milliseconds: 260),
                                    child: Text(details,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: place.kind.colors.first,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14)),
                                  ),
                                  if (rating != null && rating > 0) ...[
                                    const SizedBox(height: 6),
                                    FadeSlideIn(
                                      delay: const Duration(milliseconds: 300),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          for (var i = 1; i <= 5; i++)
                                            Icon(
                                              rating >= i - 0.25
                                                  ? Icons.star_rounded
                                                  : rating >= i - 0.75
                                                      ? Icons.star_half_rounded
                                                      : Icons.star_outline_rounded,
                                              color: kSponsoredGold,
                                              size: 20,
                                            ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${rating.toStringAsFixed(1)}'
                                            '${place.reviews != null ? ' (${place.reviews})' : ''}',
                                            style: const TextStyle(
                                                color: kBrandText,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  // The offer.
                                  FadeSlideIn(
                                    delay: const Duration(milliseconds: 340),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF8E1),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color: kSponsoredGold.withValues(alpha: 0.45)),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(ad.title,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  color: Color(0xFF4A3500),
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 15.5)),
                                          if (ad.description.isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Text(ad.description,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                    color: Color(0xFF5A4300),
                                                    height: 1.55,
                                                    fontSize: 13.5)),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  FadeSlideIn(
                                    delay: const Duration(milliseconds: 400),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: GradientButton(
                                            label: bookable ? 'احجز موعدك' : 'عرض الصفحة',
                                            icon: bookable
                                                ? Icons.event_available_rounded
                                                : Icons.storefront_rounded,
                                            onTap: () => go(bookable
                                                ? BookAppointmentPage(place: place)
                                                : PlaceDetailsPage(place: place)),
                                          ),
                                        ),
                                        if (place.phone.isNotEmpty) ...[
                                          const SizedBox(width: 10),
                                          PressableScale(
                                            onTap: () => callNumber(place.phone),
                                            child: Container(
                                              width: 56,
                                              height: 56,
                                              decoration: BoxDecoration(
                                                color: kBrandSuccess,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: const Icon(Icons.call_rounded,
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (bookable) ...[
                                    const SizedBox(height: 6),
                                    TextButton(
                                      onPressed: () => go(PlaceDetailsPage(place: place)),
                                      child: const Text('عرض الصفحة',
                                          style: TextStyle(
                                              color: kBrandMuted,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  ] else
                                    const SizedBox(height: 18),
                                ],
                              ),
                            ),
                          ],
                        ),
                        // The photo, big, in a gold ring, half over the picture.
                        Positioned(
                          top: _headerHeight - _photo / 2,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: FadeSlideIn(
                              fromScale: 0.6,
                              delay: const Duration(milliseconds: 120),
                              child: GestureDetector(
                                onTap: () => go(PlaceDetailsPage(place: place)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(colors: gold),
                                    boxShadow: [
                                      BoxShadow(
                                          color: kSponsoredGold.withValues(alpha: 0.5),
                                          blurRadius: 18),
                                    ],
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                        color: Colors.white, shape: BoxShape.circle),
                                    child: PlaceAvatar(
                                        place: place, size: _photo - 14, ring: false),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumAdWindow extends StatelessWidget {
  final Ad ad;

  const PremiumAdWindow({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    final place = ad.place!;
    final size = MediaQuery.of(context).size;
    final bookable = place.kind == PlaceKind.doctor && place.bookingEnabled;

    /// Leaves the window, then opens [page] (if any) in its place.
    void go([Widget? page]) {
      final nav = Navigator.of(context);
      nav.pop();
      if (page != null) nav.push(MaterialPageRoute(builder: (_) => page));
    }

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                clipBehavior: Clip.antiAlias,
                elevation: 24,
                shadowColor: kSponsoredGold.withValues(alpha: 0.5),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Picture with the gold tag and the close countdown.
                      SizedBox(
                        height: (size.height * 0.42).clamp(220.0, 380.0),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            PressableScale(
                              pressedScale: 0.98,
                              onTap: () => go(PlaceDetailsPage(place: place)),
                              child: NetImage(ad.image, fit: BoxFit.cover),
                            ),
                            const IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color(0x66000000), Colors.transparent, Colors.transparent],
                                    stops: [0, 0.35, 1],
                                  ),
                                ),
                              ),
                            ),
                            PositionedDirectional(
                              top: 14,
                              start: 14,
                              child: ShimmerSweep(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFFFFE082), kSponsoredGold]),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(color: kSponsoredGold.withValues(alpha: 0.5), blurRadius: 12),
                                    ],
                                  ),
                                  child: const Text('⭐ إعلان مميز',
                                      style: TextStyle(
                                          color: Color(0xFF4A3500),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 12.5)),
                                ),
                              ),
                            ),
                            PositionedDirectional(top: 12, end: 12, child: _CountdownClose(onClose: go)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 150),
                              child: Text(ad.title,
                                  style: const TextStyle(
                                      fontSize: 21, fontWeight: FontWeight.w900, color: kBrandText)),
                            ),
                            if (ad.description.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              FadeSlideIn(
                                delay: const Duration(milliseconds: 220),
                                child: Text(ad.description,
                                    style: const TextStyle(
                                        color: Color(0xFF3B4A63), height: 1.6, fontSize: 14.5)),
                              ),
                            ],
                            const SizedBox(height: 14),
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 290),
                              child: PressableScale(
                                pressedScale: 0.97,
                                onTap: () => go(PlaceDetailsPage(place: place)),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: kBrandSurface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: kSponsoredGold.withValues(alpha: 0.45)),
                                  ),
                                  child: Row(
                                    children: [
                                      PlaceAvatar(place: place, size: 48),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(place.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w800, color: kBrandText)),
                                            Text(
                                              [place.subtitle, if (place.city.isNotEmpty) place.city].join(' • '),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: place.kind.colors.first,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12.5),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.chevron_left_rounded, color: place.kind.colors.first),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 360),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GradientButton(
                                      label: bookable ? 'احجز موعدك' : 'عرض الصفحة',
                                      icon: bookable
                                          ? Icons.event_available_rounded
                                          : Icons.open_in_new_rounded,
                                      onTap: () => go(bookable
                                          ? BookAppointmentPage(place: place)
                                          : PlaceDetailsPage(place: place)),
                                    ),
                                  ),
                                  if (place.phone.isNotEmpty) ...[
                                    const SizedBox(width: 10),
                                    PressableScale(
                                      onTap: () => callNumber(place.phone),
                                      child: Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: kBrandSuccess,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Icon(Icons.call_rounded, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
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
      ),
    );
  }
}

/// A ring that fills over three seconds, then turns into the close button.
class _CountdownClose extends StatefulWidget {
  final VoidCallback onClose;

  const _CountdownClose({required this.onClose});

  @override
  State<_CountdownClose> createState() => _CountdownCloseState();
}

class _CountdownCloseState extends State<_CountdownClose> {
  static const _wait = 3;
  int _left = _wait;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _left <= 0;
    return PressableScale(
      onTap: ready ? widget.onClose : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (!ready)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(seconds: _wait),
                builder: (_, v, __) => CircularProgressIndicator(
                    value: v, strokeWidth: 2.5, color: Colors.white),
              ),
            ready
                ? const Icon(Icons.close_rounded, color: Colors.white, size: 22)
                : Text('$_left',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
