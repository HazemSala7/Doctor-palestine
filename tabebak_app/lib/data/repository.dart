import 'dart:convert';

import 'package:clinic_dr_alla/data/app_config.dart';
import 'package:clinic_dr_alla/data/demo_data.dart';
import 'package:clinic_dr_alla/data/models.dart';
import 'package:clinic_dr_alla/services/apis.dart';
import 'package:clinic_dr_alla/services/functions.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// false -> screens load from the backend API, managed on the dashboard.
/// true  -> screens use the local test data in [DemoData]
///          (`--dart-define=DEMO_DATA=true`). Booking needs real data.
const bool kUseDemoData = bool.fromEnvironment('DEMO_DATA', defaultValue: false);

class Repository {
  Repository._();

  static const _latency = Duration(milliseconds: 650);
  static const _maxPages = 100;

  /// Dashboard settings, counts and ads, loaded by [preload].
  static AppConfig config = const AppConfig();
  static List<Specialty> _specialties = [];

  /// Loads what the screens read synchronously. Called during the splash;
  /// a slow or failed load leaves empty defaults rather than blocking.
  static Future<void> preload() async {
    if (kUseDemoData) return;
    await Future.wait([_loadConfig(), _loadSpecialties()])
        .timeout(const Duration(seconds: 8), onTimeout: () => []);
  }

  /// Picks up dashboard changes while the app stays open. If it fails, the
  /// screens keep what they already have.
  static Future<void> reloadConfig() => preload();

  static Future<void> _loadConfig() async {
    try {
      final res = await http.get(Uri.parse('${URL}app-config'),
          headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        config = AppConfig.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
      }
    } catch (e) {
      debugPrint('Error loading app config: $e');
    }
  }

  static String _bare(String name) =>
      name.trim().startsWith('ال') ? name.trim().substring(2) : name.trim();

  static Future<void> _loadSpecialties() async {
    try {
      final res = await http.get(Uri.parse(urlDoctorCategories), headers: headers);
      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      _specialties = [
        for (var i = 0; i < list.length; i++) _specialtyFromApi(i, list[i])
      ];
    } catch (e) {
      debugPrint('Error loading specialties: $e');
    }
  }

  /// Reuses the built-in emoji and colour when the name matches one.
  static Specialty _specialtyFromApi(int index, Map j) {
    final name = '${j['name']}';
    final known =
        DemoData.specialties.where((s) => _bare(s.name) == _bare(name)).firstOrNull;
    final color = (known ??
            DemoData.specialties[index % DemoData.specialties.length])
        .color;
    return Specialty(name, known?.emoji ?? '🩺', color,
        id: j['id'], imageUrl: mediaUrl(j['image']));
  }

  static bool _matches(Place p, String q) {
    final s = q.trim();
    if (s.isEmpty) return true;
    return p.name.contains(s) ||
        (p.specialty?.contains(s) ?? false) ||
        p.city.contains(s) ||
        p.kind.plural.contains(s) ||
        p.tags.any((t) => t.contains(s));
  }

  static Future<List<Place>> places(
    PlaceKind kind, {
    int? cityId,
    String? specialty,
    String query = '',
  }) async {
    if (kUseDemoData) {
      await Future.delayed(_latency);
      final source =
          kind == PlaceKind.doctor ? DemoData.doctors : DemoData.places[kind]!;
      return source
          .where((p) =>
              (cityId == null || p.cityId == cityId) &&
              (specialty == null || p.specialty == specialty) &&
              _matches(p, query))
          .toList();
    }
    final list = await _fetchPlaces(kind,
        cityId: cityId,
        categoryId: specialty == null ? null : _specialtyId(specialty),
        query: query);
    return _pinSponsored(kind, list,
        unfiltered: cityId == null && specialty == null && query.isEmpty);
  }

  /// Is [p] the target of a running premium ad?
  static bool isSponsored(Place p) => config.premiumAds
      .any((a) => a.place!.kind == p.kind && a.place!.id == p.id);

  /// Moves sponsored listings to the top. On an unfiltered list they're
  /// added even if they fell outside the pages loaded.
  static List<Place> _pinSponsored(PlaceKind kind, List<Place> list,
      {required bool unfiltered}) {
    final pinned = <Place>[];
    for (final ad in config.premiumAds.where((a) => a.place!.kind == kind)) {
      final inList = list.where((p) => p.id == ad.place!.id).firstOrNull;
      if (inList != null) {
        pinned.add(inList);
      } else if (unfiltered) {
        pinned.add(ad.place!);
      }
    }
    if (pinned.isEmpty) return list;
    final ids = {for (final p in pinned) p.id};
    return [...pinned, ...list.where((p) => !ids.contains(p.id))];
  }

  static int? _specialtyId(String name) {
    for (final s in _specialties) {
      if (s.name == name) return s.id;
    }
    return null;
  }

  static Future<List<Place>> _fetchPlaces(PlaceKind kind,
      {int? cityId, int? categoryId, String query = ''}) async {
    final result = <Place>[];
    var page = 1, last = 1;
    // Records added on the dashboard land on the last page, so stop only at
    // a limit far above any real list; it just guards against runaway loops.
    while (page <= last && page <= _maxPages) {
      var q = '?page=$page';
      if (cityId != null) q += '&city_id=$cityId';
      if (categoryId != null) q += '&category_id=$categoryId';
      if (query.isNotEmpty) q += '&key=${Uri.encodeComponent(query)}';
      try {
        final res = await http.get(Uri.parse('$URL${kind.apiPath}$q'),
            headers: headers);
        if (res.statusCode != 200) break;
        final json = jsonDecode(utf8.decode(res.bodyBytes));
        for (final e in json['data'] as List) {
          result.add(Place.fromApi(kind, e));
        }
        last = json['last_page'] ?? 1;
      } catch (e) {
        debugPrint('Error loading ${kind.apiPath}: $e');
        break;
      }
      page++;
    }
    return result;
  }

  static Future<List<City>> cities() async {
    if (kUseDemoData) return DemoData.cities;
    try {
      final res = await http.get(Uri.parse(urlCities), headers: headers);
      final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
      return [
        for (var i = 0; i < list.length; i++)
          City(
            list[i]['id'],
            list[i]['name'],
            '📍',
            DemoData.cities[i % DemoData.cities.length].color,
            imageUrl: mediaUrl(list[i]['image']),
          ),
      ];
    } catch (e) {
      debugPrint('Error loading cities: $e');
      return [];
    }
  }

  /// The dashboard's specialties (loaded by [preload]).
  static List<Specialty> specialties() =>
      kUseDemoData ? DemoData.specialties : _specialties;

  static Future<List<Job>> jobs({int? cityId}) async {
    if (kUseDemoData) {
      await Future.delayed(_latency);
      return DemoData.jobs
          .where((j) => cityId == null || j.cityId == cityId)
          .toList();
    }
    return _fetchJobs(cityId: cityId, maxPages: _maxPages);
  }

  /// The home banner's jobs: those chosen on the dashboard, or else the
  /// newest. The API lists chosen jobs first, so one page is enough.
  static Future<List<Job>> homeJobs() async {
    const shown = 6;
    if (kUseDemoData) return DemoData.jobs.take(shown).toList();
    final list = await _fetchJobs(maxPages: 1);
    final featured = list.where((j) => j.featured).toList();
    return (featured.isEmpty ? list : featured).take(shown).toList();
  }

  static int get jobsCount =>
      kUseDemoData ? DemoData.jobs.length : config.counts['jobs'] ?? 0;

  static Future<List<Job>> _fetchJobs(
      {int? cityId, required int maxPages}) async {
    final result = <Job>[];
    var page = 1, last = 1;
    while (page <= last && page <= maxPages) {
      var q = '?page=$page';
      if (cityId != null) q += '&city_id=$cityId';
      try {
        final res = await http.get(Uri.parse('$urlJobs$q'), headers: headers);
        if (res.statusCode != 200) break;
        final json = jsonDecode(utf8.decode(res.bodyBytes));
        result.addAll([for (final e in json['data'] as List) Job.fromApi(e)]);
        last = json['last_page'] ?? 1;
      } catch (e) {
        debugPrint('Error loading jobs: $e');
        break;
      }
      page++;
    }
    return result;
  }

  /// Searches every kind of listing.
  static Future<List<Place>> search(String query) async {
    if (query.trim().isEmpty) return [];
    if (kUseDemoData) {
      await Future.delayed(const Duration(milliseconds: 250));
      return DemoData.all.where((p) => _matches(p, query)).toList();
    }
    return _fetchPlaces(PlaceKind.doctor, query: query);
  }

  /// The home screen's doctors: those marked "featured" on the dashboard,
  /// or the first ones when none are marked yet.
  static Future<List<Place>> featuredDoctors() async {
    final list = await places(PlaceKind.doctor);
    if (kUseDemoData) {
      list.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
      return list.take(10).toList();
    }
    final featured = list.where((p) => p.featured).toList();
    return (featured.isEmpty ? list : featured).take(10).toList();
  }

  /// Pharmacies marked on duty on the dashboard (open now, for demo data).
  static Future<List<Place>> onDutyPharmacies() async {
    final list = await places(PlaceKind.pharmacy);
    return kUseDemoData
        ? list.where((p) => p.isOpenNow != false).toList()
        : list.where((p) => p.onDuty).toList();
  }

  static Place? byId(int id) {
    if (!kUseDemoData) return null;
    for (final p in DemoData.all) {
      if (p.id == id) return p;
    }
    return null;
  }

  static int countFor(PlaceKind kind, {int? cityId}) {
    if (!kUseDemoData) {
      if (cityId == null) return config.counts[kind.apiPath] ?? 0;
      return kind == PlaceKind.doctor ? config.doctorsByCity[cityId] ?? 0 : 0;
    }
    final source =
        kind == PlaceKind.doctor ? DemoData.doctors : DemoData.places[kind]!;
    return source.where((p) => cityId == null || p.cityId == cityId).length;
  }

  static int countForSpecialty(String specialty) {
    if (kUseDemoData) {
      return DemoData.doctors.where((d) => d.specialty == specialty).length;
    }
    final id = _specialtyId(specialty);
    return id == null ? 0 : config.doctorsByCategory[id] ?? 0;
  }

  static int get citiesCount =>
      kUseDemoData ? DemoData.cities.length : config.counts['cities'] ?? 0;
}
