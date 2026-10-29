import 'package:flutter/material.dart';

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

  const Specialty(this.name, this.emoji, this.color);
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
  });

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
      lat: double.tryParse('${first?['lat'] ?? ''}'),
      lng: double.tryParse('${first?['lng'] ?? ''}'),
      coverUrl: kind == PlaceKind.doctor ? j['image'] : j['cover_image'],
      logoUrl: kind == PlaceKind.doctor ? j['image'] : j['logo_image'],
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
  final int postedDaysAgo;
  final String emoji;

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
  });

  factory Job.fromApi(Map<String, dynamic> j) => Job(
        id: j['id'] ?? 0,
        title: j['title'] ?? '',
        employer: j['location'] ?? '',
        type: j['type'] ?? '',
        city: j['city']?['name'] ?? '',
        cityId: j['city']?['id'],
        description: j['description'] ?? '',
        phone: '',
        postedDaysAgo: 0,
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
