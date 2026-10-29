import 'dart:convert';

import 'package:clinic_dr_alla/data/demo_data.dart';
import 'package:clinic_dr_alla/data/models.dart';
import 'package:clinic_dr_alla/services/apis.dart';
import 'package:clinic_dr_alla/services/functions.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// true  -> screens use the local test data in [DemoData].
/// false -> screens load from the backend API.
/// Switch to false before publishing a release.
const bool kUseDemoData = true;

class Repository {
  Repository._();

  static const _latency = Duration(milliseconds: 650);

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
    return _fetchPlaces(kind, cityId: cityId, query: query);
  }

  static Future<List<Place>> _fetchPlaces(PlaceKind kind,
      {int? cityId, String query = ''}) async {
    final result = <Place>[];
    var page = 1, last = 1;
    // A few pages is plenty for browsing; avoids unbounded downloads.
    while (page <= last && page <= 5) {
      var q = '?page=$page';
      if (cityId != null) q += '&city_id=$cityId';
      if (query.isNotEmpty) q += '&key=${Uri.encodeComponent(query)}';
      try {
        final res = await http.get(Uri.parse('$URL${kind.apiPath}$q'),
            headers: headers);
        if (res.statusCode != 200) break;
        final json = jsonDecode(res.body);
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
      final list = jsonDecode(res.body) as List;
      return [
        for (var i = 0; i < list.length; i++)
          City(
            list[i]['id'],
            list[i]['name'],
            '📍',
            DemoData.cities[i % DemoData.cities.length].color,
            imageUrl: list[i]['image'],
          ),
      ];
    } catch (e) {
      debugPrint('Error loading cities: $e');
      return [];
    }
  }

  static List<Specialty> specialties() => DemoData.specialties;

  static Future<List<Job>> jobs({int? cityId}) async {
    if (kUseDemoData) {
      await Future.delayed(_latency);
      return DemoData.jobs
          .where((j) => cityId == null || j.cityId == cityId)
          .toList();
    }
    try {
      final q = cityId == null ? '' : '?city_id=$cityId';
      final res = await http.get(Uri.parse('$urlJobs$q'), headers: headers);
      final json = jsonDecode(res.body);
      return [for (final e in json['data'] as List) Job.fromApi(e)];
    } catch (e) {
      debugPrint('Error loading jobs: $e');
      return [];
    }
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

  /// Highest-rated doctors, for the home screen.
  static Future<List<Place>> featuredDoctors() async {
    final list = await places(PlaceKind.doctor);
    list.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    return list.take(10).toList();
  }

  /// Pharmacies open right now.
  static Future<List<Place>> onDutyPharmacies() async {
    final list = await places(PlaceKind.pharmacy);
    return list.where((p) => p.isOpenNow != false).toList();
  }

  static Place? byId(int id) {
    if (!kUseDemoData) return null;
    for (final p in DemoData.all) {
      if (p.id == id) return p;
    }
    return null;
  }

  static int countFor(PlaceKind kind, {int? cityId}) {
    if (!kUseDemoData) return 0;
    final source =
        kind == PlaceKind.doctor ? DemoData.doctors : DemoData.places[kind]!;
    return source.where((p) => cityId == null || p.cityId == cityId).length;
  }

  static int countForSpecialty(String specialty) => kUseDemoData
      ? DemoData.doctors.where((d) => d.specialty == specialty).length
      : 0;
}
