import 'dart:convert';

import 'package:clinic_dr_alla/data/booking.dart';
import 'package:clinic_dr_alla/data/models.dart' show mediaUrl;

class NamedOption {
  final int id;
  final String name;

  const NamedOption(this.id, this.name);

  static List<NamedOption> listFrom(dynamic rows) => [
        for (final r in (rows as List? ?? const []))
          NamedOption(int.tryParse('${r['id']}') ?? 0, '${r['name'] ?? ''}'),
      ];
}

class GeoPoint {
  final double lat;
  final double lng;

  const GeoPoint(this.lat, this.lng);

  static GeoPoint? fromApi(dynamic coords) {
    final first = coords is List && coords.isNotEmpty ? coords.first : null;
    if (first is! Map) return null;
    final lat = double.tryParse('${first['lat']}');
    final lng = double.tryParse('${first['lng']}');
    return lat == null || lng == null ? null : GeoPoint(lat, lng);
  }
}

/// Someone on the signed-in doctor's team, hidden members included.
class TeamMember {
  final int id;
  final String name;
  final String role;
  final String bio;
  final String? imageUrl;
  final bool active;

  const TeamMember({
    required this.id,
    required this.name,
    required this.role,
    this.bio = '',
    this.imageUrl,
    this.active = true,
  });

  factory TeamMember.fromJson(Map<String, dynamic> j) => TeamMember(
        id: j['id'] ?? 0,
        name: j['name'] ?? '',
        role: j['role'] ?? '',
        bio: j['bio'] ?? '',
        imageUrl: mediaUrl(j['image']),
        active: j['active'] == true || j['active'] == 1,
      );
}

/// The server's limit for an uploaded reel.
const kMaxReelBytes = 100 * 1024 * 1024;

/// One of the signed-in doctor's reels, hidden ones included.
class DoctorReel {
  final int id;
  final String title;
  final String description;
  final String videoUrl;
  final String? coverUrl;
  final bool active;
  final int views;

  const DoctorReel({
    required this.id,
    required this.title,
    this.description = '',
    this.videoUrl = '',
    this.coverUrl,
    this.active = true,
    this.views = 0,
  });

  factory DoctorReel.fromJson(Map<String, dynamic> j) => DoctorReel(
        id: j['id'] ?? 0,
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        videoUrl: j['video'] ?? '',
        coverUrl: mediaUrl(j['thumbnail']),
        active: j['active'] == true || j['active'] == 1,
        views: j['views'] ?? 0,
      );
}

/// What the doctor can change on their page, and the choices for it.
class DoctorPageDetails {
  final String name;
  final int? categoryId;
  final int? cityId;
  final String mobile;
  final String address;
  final String description;
  final String facebook;
  final String instagram;
  final String? imageUrl;
  final GeoPoint? location;
  final List<NamedOption> categories;
  final List<NamedOption> cities;

  const DoctorPageDetails({
    required this.name,
    this.categoryId,
    this.cityId,
    this.mobile = '',
    this.address = '',
    this.description = '',
    this.facebook = '',
    this.instagram = '',
    this.imageUrl,
    this.location,
    this.categories = const [],
    this.cities = const [],
  });

  factory DoctorPageDetails.fromJson(Map<String, dynamic> j) {
    final d = j['doctor'] is Map ? j['doctor'] as Map : const {};
    return DoctorPageDetails(
      name: d['name'] ?? '',
      categoryId: int.tryParse('${d['category_id']}'),
      cityId: int.tryParse('${d['city_id']}'),
      mobile: d['mobile'] ?? '',
      address: d['address'] ?? '',
      description: d['description'] ?? '',
      facebook: d['facebook_url'] ?? '',
      instagram: d['instagram_url'] ?? '',
      imageUrl: mediaUrl(d['image']),
      location: GeoPoint.fromApi(d['coordinates']),
      categories: NamedOption.listFrom(j['categories']),
      cities: NamedOption.listFrom(j['cities']),
    );
  }
}

class DoctorPageApi {
  DoctorPageApi._();

  static Future<DoctorPageDetails> load() async => DoctorPageDetails.fromJson(
      Map<String, dynamic>.from(await DoctorApi.authed('GET', 'doctor/page')));

  /// [location] is only sent when [locationChanged]; null then clears it.
  static Future<void> save({
    required String name,
    required int categoryId,
    required int cityId,
    required String mobile,
    required String address,
    required String description,
    required String facebook,
    required String instagram,
    String? photoPath,
    bool removePhoto = false,
    bool locationChanged = false,
    GeoPoint? location,
  }) async {
    await DoctorApi.authedUpload(
      'doctor/page',
      {
        'name': name.trim(),
        'category_id': '$categoryId',
        'city_id': '$cityId',
        'mobile': mobile.trim(),
        'address': address.trim(),
        'description': description.trim(),
        'facebook_url': facebook.trim(),
        'instagram_url': instagram.trim(),
        if (removePhoto && photoPath == null) 'image__remove': '1',
        if (locationChanged)
          'coordinates': location == null
              ? ''
              : jsonEncode([
                  {'lat': '${location.lat}', 'lng': '${location.lng}'}
                ]),
      },
      files: {if (photoPath != null) 'image': photoPath},
    );
  }

  static Future<List<TeamMember>> team() async {
    final json = await DoctorApi.authed('GET', 'doctor/staff');
    return [
      for (final e in json['data'] as List)
        TeamMember.fromJson(Map<String, dynamic>.from(e as Map)),
    ];
  }

  /// Adds a member, or edits [id] when it is given.
  static Future<void> saveMember({
    int? id,
    required String name,
    required String role,
    required String bio,
    required bool active,
    String? photoPath,
    bool removePhoto = false,
  }) async {
    await DoctorApi.authedUpload(
      id == null ? 'doctor/staff' : 'doctor/staff/$id',
      {
        'name': name.trim(),
        'role': role.trim(),
        'bio': bio.trim(),
        'active': active ? '1' : '0',
        if (removePhoto && photoPath == null) 'image__remove': '1',
      },
      files: {if (photoPath != null) 'image': photoPath},
    );
  }

  static Future<void> deleteMember(int id) async {
    await DoctorApi.authed('POST', 'doctor/staff/$id/delete');
  }

  static Future<void> reorder(List<int> ids) async {
    await DoctorApi.authed('POST', 'doctor/staff/reorder', body: {'ids': ids});
  }

  static Future<List<DoctorReel>> reels() async {
    final json = await DoctorApi.authed('GET', 'doctor/reels');
    return [
      for (final e in json['data'] as List)
        DoctorReel.fromJson(Map<String, dynamic>.from(e as Map)),
    ];
  }

  /// Adds a reel, or edits [id] when it is given; no [videoPath] keeps the video.
  static Future<void> saveReel({
    int? id,
    required String title,
    required String description,
    required bool active,
    String? videoPath,
    String? coverPath,
    bool removeCover = false,
  }) async {
    await DoctorApi.authedUpload(
      id == null ? 'doctor/reels' : 'doctor/reels/$id',
      {
        'title': title.trim(),
        'description': description.trim(),
        'active': active ? '1' : '0',
        if (removeCover && coverPath == null) 'thumbnail__remove': '1',
      },
      files: {
        if (videoPath != null) 'video': videoPath,
        if (coverPath != null) 'thumbnail': coverPath,
      },
      timeout: const Duration(minutes: 15),
    );
  }

  static Future<void> deleteReel(int id) async {
    await DoctorApi.authed('POST', 'doctor/reels/$id/delete');
  }
}
