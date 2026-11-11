import 'package:clinic_dr_alla/Components/animations/animations.dart';
import 'package:clinic_dr_alla/Components/brand_widgets.dart';
import 'package:clinic_dr_alla/Components/ui_kit.dart';
import 'package:clinic_dr_alla/Constants/app_theme.dart';
import 'package:clinic_dr_alla/Pages/booking/book_appointment_page.dart';
import 'package:clinic_dr_alla/Pages/home_page/tabs/main_screen/home_ad_carousel.dart';
import 'package:clinic_dr_alla/data/app_config.dart';
import 'package:clinic_dr_alla/data/models.dart';
import 'package:flutter/material.dart';

const _gold = [Color(0xFFFFE082), Color(0xFFE0A800), Color(0xFFB8860B)];
const _coverHeight = 118.0;
const _avatarSize = 68.0;

/// The home screen's own section for VIP («مميز جداً») ads: each one shows the
/// doctor or centre itself (photo, name, specialty, city, rating) with the
/// ad's offer and buttons to book or call. [ads] all have a place.
class VipSpotlight extends StatelessWidget {
  final List<Ad> ads;

  const VipSpotlight({super.key, required this.ads});

  @override
  Widget build(BuildContext context) {
    final t = MediaQuery.textScalerOf(context).scale(1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SponsorHeader(),
        AutoPager(
          count: ads.length,
          height: 214 + 112 * t,
          activeDot: const LinearGradient(colors: _gold),
          dotColor: const Color(0xFFF1E3B5),
          itemBuilder: (_, i) => VipCard(ad: ads[i]),
        ),
      ],
    );
  }
}

class VipCard extends StatelessWidget {
  final Ad ad;

  const VipCard({super.key, required this.ad});

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context, rootNavigator: true)
          .push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final place = ad.place!;
    final bookable = place.kind == PlaceKind.doctor && place.bookingEnabled;
    final accent = place.kind.colors.first;
    final rating = place.rating;
    final details = [
      place.subtitle,
      if (place.city.isNotEmpty) place.city,
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
      child: PressableScale(
        pressedScale: 0.98,
        onTap: () => openPlace(context, place),
        child: Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _gold,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: kSponsoredGold.withValues(alpha: 0.32),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25.5),
            child: ColoredBox(
              color: Colors.white,
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // The ad's picture, with the sponsored tag.
                      SizedBox(
                        height: _coverHeight,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            NetImage(ad.image, fit: BoxFit.cover),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Color(0x55000000),
                                    Colors.transparent
                                  ],
                                ),
                              ),
                            ),
                            PositionedDirectional(
                              top: 10,
                              end: 10,
                              child: ShimmerSweep(
                                period: const Duration(milliseconds: 2600),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient:
                                        const LinearGradient(colors: _gold),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text('👑 الراعي الحصري',
                                      style: TextStyle(
                                          color: Color(0xFF3E2C00),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w900)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name and details sit beside the photo.
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    start: _avatarSize + 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(place.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  color: kBrandText,
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 17)),
                                        ),
                                        if (place.verified) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.verified_rounded,
                                              color: kBrandPrimary, size: 17),
                                        ],
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(details,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                  color: accent,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12.5)),
                                        ),
                                        if (rating != null && rating > 0) ...[
                                          const SizedBox(width: 8),
                                          const Icon(Icons.star_rounded,
                                              color: kSponsoredGold, size: 16),
                                          Text(rating.toStringAsFixed(1),
                                              style: const TextStyle(
                                                  color: kBrandText,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12.5)),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // The offer: the ad's title and text.
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8E1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: BorderDirectional(
                                    start: BorderSide(
                                        color: kSponsoredGold, width: 3),
                                  ),
                                ),
                                child: Text.rich(
                                  TextSpan(children: [
                                    TextSpan(
                                        text: ad.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900)),
                                    if (ad.description.isNotEmpty)
                                      TextSpan(text: ' — ${ad.description}'),
                                  ]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Color(0xFF5A4300),
                                      fontSize: 12.5,
                                      height: 1.45),
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Expanded(
                                    child: _Button(
                                      label: bookable
                                          ? 'احجز موعدك'
                                          : 'عرض الصفحة',
                                      icon: bookable
                                          ? Icons.event_available_rounded
                                          : Icons.storefront_rounded,
                                      onTap: () => bookable
                                          ? _push(context,
                                              BookAppointmentPage(place: place))
                                          : openPlace(context, place),
                                    ),
                                  ),
                                  if (place.phone.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    PressableScale(
                                      onTap: () => callNumber(place.phone),
                                      child: Container(
                                        width: 46,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: kBrandSuccess,
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        child: const Icon(Icons.call_rounded,
                                            color: Colors.white, size: 21),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // The photo, half over the picture, in a gold ring.
                  PositionedDirectional(
                    top: _coverHeight - _avatarSize / 2,
                    start: 14,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: _gold),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                            color: Colors.white, shape: BoxShape.circle),
                        child: PlaceAvatar(
                            place: place, size: _avatarSize - 10, ring: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// «👑 الراعي الحصري لتطبيق طبيبك» between two gold rules.
class _SponsorHeader extends StatelessWidget {
  const _SponsorHeader();

  @override
  Widget build(BuildContext context) {
    Widget rule(bool leading) => Expanded(
          child: Container(
            height: 1.6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: leading
                    ? [Colors.transparent, kSponsoredGold]
                    : [kSponsoredGold, Colors.transparent],
              ),
            ),
          ),
        );
    // A heading, not reading text: past 1.2× it would crowd out the gold rules.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
        child: Column(
          children: [
            Row(
              children: [
                rule(true),
                const SizedBox(width: 10),
                _badge(),
                const SizedBox(width: 10),
                rule(false),
              ],
            ),
            const SizedBox(height: 4),
            const Text('لتطبيق طبيبك',
                style: TextStyle(
                    color: Color(0xFF8A6A00),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5)),
          ],
        ),
      ),
    );
  }

  Widget _badge() => ShimmerSweep(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: _gold),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: kSponsoredGold.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: const Text('👑 الراعي الحصري',
              style: TextStyle(
                  color: Color(0xFF3E2C00),
                  fontWeight: FontWeight.w900,
                  fontSize: 15)),
        ),
      );
}

class _Button extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _Button({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => PressableScale(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            gradient: kBrandGradient,
            borderRadius: BorderRadius.circular(15),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 19),
              const SizedBox(width: 6),
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
              ),
            ],
          ),
        ),
      );
}
