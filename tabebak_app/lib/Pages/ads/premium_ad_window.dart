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

/// Opens one running premium ad, at most once a day per ad. With several,
/// the one shown least recently goes first, so they take turns.
Future<void> maybeShowPremiumAd(BuildContext context) async {
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

class PremiumAdWindow extends StatefulWidget {
  final Ad ad;

  const PremiumAdWindow({super.key, required this.ad});

  @override
  State<PremiumAdWindow> createState() => _PremiumAdWindowState();
}

class _PremiumAdWindowState extends State<PremiumAdWindow> {
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

  /// Leaves the window, then opens [page] (if any) in its place.
  void _go([Widget? page]) {
    final nav = Navigator.of(context);
    nav.pop();
    if (page != null) nav.push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;
    final place = ad.place!;
    final size = MediaQuery.of(context).size;
    final bookable = place.kind == PlaceKind.doctor && place.bookingEnabled;

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
                              onTap: () => _go(PlaceDetailsPage(place: place)),
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
                            PositionedDirectional(top: 12, end: 12, child: _closeButton()),
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
                                onTap: () => _go(PlaceDetailsPage(place: place)),
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
                                      onTap: () => _go(bookable
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

  /// A ring that fills over three seconds, then turns into the close button.
  Widget _closeButton() {
    final ready = _left <= 0;
    return PressableScale(
      onTap: ready ? () => _go() : null,
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
