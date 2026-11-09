import 'package:flutter/material.dart';

/// A record with no picture comes back from the API as the bare ".../storage/"
/// folder; the screens must see that as "no image" and show their fallback.
String? mediaUrl(dynamic value) {
  final url = value is String ? value.trim() : '';
  return url.isEmpty || url.endsWith('/storage/') ? null : url;
}

/// Every kind of listing the app shows.
enum PlaceKind {
  doctor('طبيب', 'الأطباء', '🩺', 'doctors',
      [Color(0xFF1565C0), Color(0xFF42A5F5)], 'assets/images/medical-team.png'),
  hospital('مستشفى', 'المستشفيات', '🏥', 'hospitals',
      [Color(0xFF0D47A1), Color(0xFF26C6DA)], 'assets/images/medical.png'),
  pharmacy('صيدلية', 'الصيدليات', '💊', 'pharmacies',
      [Color(0xFF00897B), Color(0xFF4DD0E1)], 'assets/images/shop.png'),
  laboratory('مختبر', 'المختبرات', '🧪', 'laboratories',
      [Color(0xFF5E35B1), Color(0xFF9575CD)], 'assets/images/check.png'),
  radiology('مركز أشعة', 'مراكز الأشعة', '🩻', 'radiology_centers',
      [Color(0xFF283593), Color(0xFF5C6BC0)], 'assets/images/x-ray.png'),
  beauty(
      'مركز تجميل',
      'مراكز التجميل',
      '✨',
      'beauty_centers',
      [Color(0xFFD81B60), Color(0xFFF48FB1)],
      'assets/images/hair-treatment.png'),
  warehouse('مستودع طبي', 'المستودعات الطبية', '📦', 'medical_warehouses',
      [Color(0xFFEF6C00), Color(0xFFFFB74D)], 'assets/images/warehouse.png'),
  nutrition(
      'أخصائي تغذية',
      'التغذية',
      '🥗',
      'nutrition_centers',
      [Color(0xFF43A047), Color(0xFFAED581)],
      'assets/images/nutrition-plan.png'),
  optics('بصريات', 'البصريات', '👓', 'optics',
      [Color(0xFF00838F), Color(0xFF80DEEA)], 'assets/images/vision.png'),
  physio('مركز علاج طبيعي', 'العلاج الطبيعي', '🦴', 'medical_treatment_centers',
      [Color(0xFF3949AB), Color(0xFF00BCD4)], null);

  final String label;
  final String plural;
  final String emoji;
  final String apiPath;
  final List<Color> colors;
  final String? asset;

  const PlaceKind(this.label, this.plural, this.emoji, this.apiPath,
      this.colors, this.asset);

  /// Label short enough for small tiles.
  String get short => switch (this) {
        PlaceKind.warehouse => 'مستودعات',
        PlaceKind.physio => 'علاج طبيعي',
        PlaceKind.radiology => 'الأشعة',
        PlaceKind.beauty => 'التجميل',
        _ => plural,
      };

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: colors,
      );

  /// The backend's name for this section in reviews and ad targets.
  String get apiType => switch (this) {
        PlaceKind.doctor => 'doctor',
        PlaceKind.hospital => 'hospital',
        PlaceKind.pharmacy => 'pharmacy',
        PlaceKind.laboratory => 'lab',
        PlaceKind.radiology => 'radiology',
        PlaceKind.beauty => 'beauty_center',
        PlaceKind.warehouse => 'warehouse',
        PlaceKind.nutrition => 'nutrition',
        PlaceKind.optics => 'optic',
        PlaceKind.physio => 'treatment_center',
      };

  static PlaceKind byName(String name) => PlaceKind.values
      .firstWhere((k) => k.name == name, orElse: () => PlaceKind.doctor);
}

class City {
  final int id;
  final String name;
  final String emoji;
  final Color color;
  final String? imageUrl;

  const City(this.id, this.name, this.emoji, this.color, {this.imageUrl});
}

class Specialty {
  final String name;
  final String emoji;
  final Color color;

  /// From the dashboard's doctor-categories (null for demo data).
  final int? id;
  final String? imageUrl;

  const Specialty(this.name, this.emoji, this.color, {this.id, this.imageUrl});
}

/// A doctor, hospital, pharmacy, ... — one shape for every listing.
class Place {
  final int id;
  final PlaceKind kind;
  final String name;
  final String? specialty;
  final int? cityId;
  final String city;
  final String address;
  final String description;
  final String phone;
  final double? rating;
  final int? reviews;
  final int? experience;
  final int? fee;

  /// Opening hour and closing hour (24h). Null when unknown.
  final int? opensAt;
  final int? closesAt;

  /// Working days, 0 = Saturday ... 6 = Friday.
  final Set<int> workDays;
  final bool open24h;
  final double? lat;
  final double? lng;
  final String? coverUrl;
  final String? logoUrl;
  final List<String> tags;
  final bool verified;

  /// The doctor has an account and takes bookings in the app.
  final bool bookingEnabled;

  /// Dashboard switches: shown in the home screen's featured doctors /
  /// on-duty pharmacies.
  final bool featured;
  final bool onDuty;

  /// Social links from the dashboard; null when not set.
  final String? facebookUrl;
  final String? instagramUrl;

  const Place({
    required this.id,
    required this.kind,
    required this.name,
    this.specialty,
    this.cityId,
    required this.city,
    required this.address,
    required this.description,
    required this.phone,
    this.rating,
    this.reviews,
    this.experience,
    this.fee,
    this.opensAt,
    this.closesAt,
    this.workDays = const {0, 1, 2, 3, 4, 5},
    this.open24h = false,
    this.lat,
    this.lng,
    this.coverUrl,
    this.logoUrl,
    this.tags = const [],
    this.verified = false,
    this.bookingEnabled = false,
    this.featured = false,
    this.onDuty = false,
    this.facebookUrl,
    this.instagramUrl,
  });

  bool get hasSocial => facebookUrl != null || instagramUrl != null;

  static String? _link(dynamic v) =>
      v is String && v.trim().startsWith('http') ? v.trim() : null;

  String get subtitle => specialty ?? kind.label;

  bool get hasHours => open24h || (opensAt != null && closesAt != null);

  static int _weekday(DateTime t) => (t.weekday + 1) % 7; // Sat = 0

  /// Null when hours are unknown.
  bool? get isOpenNow {
    if (open24h) return true;
    if (!hasHours) return null;
    final now = DateTime.now();
    if (!workDays.contains(_weekday(now))) return false;
    return now.hour >= opensAt! && now.hour < closesAt!;
  }

  static int get todayIndex => _weekday(DateTime.now());

  /// Builds a Place from the backend's JSON for [kind].
  factory Place.fromApi(PlaceKind kind, Map<String, dynamic> j) {
    final coords = j['coordinates'];
    final first = coords is List && coords.isNotEmpty ? coords[0] : null;
    // Approved reviews only; both stay null until the first one is published.
    final reviewCount = int.tryParse('${j['rating_count'] ?? ''}') ?? 0;
    return Place(
      id: j['id'] ?? 0,
      kind: kind,
      name: j['name'] ?? '',
      specialty: kind == PlaceKind.doctor ? (j['category']?['name']) : null,
      cityId: j['city']?['id'],
      city: j['city']?['name'] ?? '',
      address: j['address'] ?? '',
      description: j['description'] ?? '',
      phone: j['mobile'] ?? '',
      experience: j['experiance'] is int ? j['experiance'] : null,
      rating: reviewCount > 0 ? double.tryParse('${j['rating_avg']}') : null,
      reviews: reviewCount > 0 ? reviewCount : null,
      lat: double.tryParse('${first?['lat'] ?? ''}'),
      lng: double.tryParse('${first?['lng'] ?? ''}'),
      coverUrl: mediaUrl(kind == PlaceKind.doctor ? j['image'] : j['cover_image']),
      logoUrl: mediaUrl(kind == PlaceKind.doctor ? j['image'] : j['logo_image']),
      bookingEnabled: j['booking_enabled'] == true,
      featured: j['featured'] == true || j['featured'] == 1,
      onDuty: j['on_duty'] == true || j['on_duty'] == 1,
      facebookUrl: _link(j['facebook_url']),
      instagramUrl: _link(j['instagram_url']),
    );
  }
}

class Job {
  final int id;
  final String title;
  final String employer;
  final String type;
  final String city;
  final int? cityId;
  final String description;
  final String? salary;
  final String phone;

  /// Null when the dashboard row has no date.
  final int? postedDaysAgo;
  final String emoji;

  /// Chosen on the dashboard for the home screen's banner.
  final bool featured;

  const Job({
    required this.id,
    required this.title,
    required this.employer,
    required this.type,
    required this.city,
    this.cityId,
    required this.description,
    this.salary,
    required this.phone,
    required this.postedDaysAgo,
    this.emoji = '💼',
    this.featured = false,
  });

  bool get isNew => postedDaysAgo != null && postedDaysAgo! <= 7;

  /// The dashboard stores these keys; older rows may hold free text.
  static const _typeLabels = {
    'full-time': 'دوام كامل',
    'part-time': 'دوام جزئي',
    'shifts': 'مناوبات',
    'remote': 'عن بعد',
    'contract': 'عقد مؤقت',
  };

  static int? _daysSince(dynamic date) {
    final posted = DateTime.tryParse('$date');
    if (posted == null) return null;
    final days = DateTime.now().difference(posted).inDays;
    return days < 0 ? 0 : days;
  }

  factory Job.fromApi(Map<String, dynamic> j) => Job(
        id: j['id'] ?? 0,
        title: j['title'] ?? '',
        employer: j['location'] ?? '',
        type: _typeLabels[j['type']] ?? j['type'] ?? '',
        city: j['city']?['name'] ?? '',
        cityId: j['city']?['id'],
        description: j['description'] ?? '',
        phone: '${j['mobile'] ?? ''}'.trim(),
        postedDaysAgo: _daysSince(j['created_at']),
        featured: j['featured'] == true || j['featured'] == 1,
      );
}

class Promo {
  final String title;
  final String subtitle;
  final String emoji;
  final List<Color> colors;
  final PlaceKind? kind;

  const Promo(this.title, this.subtitle, this.emoji, this.colors, [this.kind]);
}
