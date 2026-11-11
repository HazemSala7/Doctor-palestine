import 'package:clinic_dr_alla/data/models.dart';

/// Advertisement `type` (as the dashboard stores it) => the listing it opens.
const _adKinds = {
  'doctor': PlaceKind.doctor,
  'hospital': PlaceKind.hospital,
  'pharmacy': PlaceKind.pharmacy,
  'lab': PlaceKind.laboratory,
  'radiology': PlaceKind.radiology,
  'beauty_center': PlaceKind.beauty,
  'warehouse': PlaceKind.warehouse,
  'nutrition': PlaceKind.nutrition,
  'optic': PlaceKind.optics,
  'treatment_center': PlaceKind.physio,
};

class Ad {
  final int id;
  final String title;
  final String image;

  /// Set when the ad opens a doctor, hospital, pharmacy, ...
  final Place? place;

  /// Set when the ad opens the jobs list ("job") or a city ("city").
  final String? type;
  final int? cityId;

  /// Premium: a full-screen window on app open, and [place] is pinned as
  /// "sponsored" at the top of its list.
  final bool premium;

  /// VIP ("مميز جداً"): everything [premium] does, and [place] gets its own
  /// section on the home screen instead of the ordinary carousel.
  final bool vip;
  final String description;

  const Ad({
    required this.id,
    required this.title,
    required this.image,
    this.place,
    this.type,
    this.cityId,
    this.premium = false,
    this.vip = false,
    this.description = '',
  });

  factory Ad.fromJson(Map<String, dynamic> j) {
    final type = j['type'] as String?;
    final raw = j['target'];
    final target = raw is Map<String, dynamic> ? raw : null;
    final kind = _adKinds[type];
    return Ad(
      id: j['id'] ?? 0,
      title: j['title'] ?? '',
      image: j['image'] ?? '',
      type: type,
      place: kind != null && target != null ? Place.fromApi(kind, target) : null,
      cityId: type == 'city' ? (target?['id'] as int?) : null,
      premium: j['placement'] == 'premium' || j['placement'] == 'vip',
      vip: j['placement'] == 'vip',
      description: j['description'] ?? '',
    );
  }
}

/// Settings, counts and running ads from `/app-config`, managed on the dashboard.
class AppConfig {
  final Map<String, String> settings;
  final Map<String, int> counts;
  final Map<int, int> doctorsByCity;
  final Map<int, int> doctorsByCategory;
  final List<Ad> ads;

  const AppConfig({
    this.settings = const {},
    this.counts = const {},
    this.doctorsByCity = const {},
    this.doctorsByCategory = const {},
    this.ads = const [],
  });

  static Map<int, int> _byId(dynamic m) => m is Map
      ? {for (final e in m.entries) int.parse('${e.key}'): (e.value as num).toInt()}
      : {};

  factory AppConfig.fromJson(Map<String, dynamic> j) => AppConfig(
        settings: {
          for (final e in (j['settings'] as Map? ?? {}).entries)
            '${e.key}': '${e.value ?? ''}'
        },
        counts: {
          for (final e in (j['counts'] as Map? ?? {}).entries)
            '${e.key}': (e.value as num).toInt()
        },
        doctorsByCity: _byId(j['doctors_by_city']),
        doctorsByCategory: _byId(j['doctors_by_category']),
        ads: [
          for (final a in (j['advertisements'] as List? ?? []))
            if ((a['image'] ?? '').toString().isNotEmpty) Ad.fromJson(a)
        ],
      );

  /// Premium ads that open a doctor or centre.
  List<Ad> get premiumAds =>
      [for (final a in ads) if (a.premium && a.place != null) a];

  /// VIP ads for the home screen's own section; each shows its doctor or centre.
  List<Ad> get vipAds => [for (final a in ads) if (a.vip && a.place != null) a];

  /// '' when the dashboard left it empty.
  String setting(String key) => settings[key]?.trim() ?? '';

  String get tagline => setting('tagline').isEmpty
      ? 'دليلك الطبي الشامل في فلسطين'
      : setting('tagline');
  String get aboutUs => setting('about_us');
  String get privacyPolicy => setting('privacy_policy');
  String get supportWhatsApp =>
      setting('support_whatsapp').isEmpty ? '0594606276' : setting('support_whatsapp');
  String get supportPhone => setting('support_phone');
  String get supportEmail => setting('support_email');
  String get facebook => setting('facebook_url');
  String get instagram => setting('instagram_url');
  String get tiktok => setting('tiktok_url');
  String get website => setting('website_url');
}
