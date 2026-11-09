import 'dart:convert';

import 'package:clinic_dr_alla/data/models.dart';
import 'package:clinic_dr_alla/services/apis.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Reel {
  final int id;
  final String title;
  final String description;
  final String videoUrl;
  final String? thumbnail;
  final int views;

  /// The doctor the reel promotes, ready to open with [openPlace].
  final Place? doctor;

  const Reel({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    this.thumbnail,
    this.views = 0,
    this.doctor,
  });

  factory Reel.fromJson(Map<String, dynamic> j) => Reel(
        id: j['id'] ?? 0,
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        videoUrl: j['video'] ?? '',
        thumbnail: j['thumbnail'],
        views: j['views'] ?? 0,
        doctor: j['doctor'] is Map<String, dynamic>
            ? Place.fromApi(PlaceKind.doctor, j['doctor'])
            : null,
      );
}

/// One page of reels from the API.
class ReelBatch {
  final List<Reel> items;
  final bool hasMore;

  const ReelBatch(this.items, this.hasMore);
}

/// Reels always come from the server, also when the app runs on demo data.
class ReelsApi {
  ReelsApi._();

  static Future<ReelBatch> fetch(int page) async {
    final res = await http
        .get(Uri.parse('${URL}reels?page=$page'),
            headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw Exception('reels: ${res.statusCode}');
    }
    final json = jsonDecode(utf8.decode(res.bodyBytes));
    return ReelBatch(
      [
        for (final r in json['data'] as List)
          if ((r['video'] ?? '').toString().isNotEmpty) Reel.fromJson(r)
      ],
      (json['current_page'] ?? 1) < (json['last_page'] ?? 1),
    );
  }

  /// Counts a view; failures don't matter to the viewer.
  static Future<void> markViewed(int id) async {
    try {
      await http.post(Uri.parse('${URL}reels/$id/view'),
          headers: {'Accept': 'application/json'});
    } catch (e) {
      debugPrint('reel view not counted: $e');
    }
  }
}
