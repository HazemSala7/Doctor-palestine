import 'dart:convert';

import 'package:clinic_dr_alla/data/booking.dart';
import 'package:clinic_dr_alla/data/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A patient's rating of a doctor or centre, as published in the app.
class Review {
  final int id;
  final String name;

  /// Anonymous key for the reviewer (not their phone), used for blocking.
  final String? author;
  final int rating;
  final String? comment;

  /// Written after a visit booked in the app and marked completed.
  final bool verified;
  final String? reply;
  final DateTime? repliedAt;
  final DateTime? createdAt;

  const Review({
    required this.id,
    required this.name,
    this.author,
    required this.rating,
    this.comment,
    this.verified = false,
    this.reply,
    this.repliedAt,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: j['id'] ?? 0,
        name: j['name'] ?? '',
        author: j['author'],
        rating: int.tryParse('${j['rating']}') ?? 0,
        comment: (j['comment'] as String?)?.trim().isEmpty ?? true
            ? null
            : (j['comment'] as String).trim(),
        verified: j['verified'] == true,
        reply: (j['reply'] as String?)?.trim().isEmpty ?? true
            ? null
            : (j['reply'] as String).trim(),
        repliedAt: parseServerTime(j['replied_at']),
        createdAt: parseServerTime(j['created_at']),
      );

  /// Key in [Blocks] that hides this reviewer.
  String get blockKey => author != null ? 'review:$author' : 'review-id:$id';
}

class ReviewSummary {
  final double? average;
  final int count;

  /// Stars (1..5) => number of reviews.
  final Map<int, int> breakdown;

  const ReviewSummary({this.average, this.count = 0, this.breakdown = const {}});

  factory ReviewSummary.fromJson(Map<String, dynamic>? j) {
    final b = j?['breakdown'];
    return ReviewSummary(
      average: double.tryParse('${j?['average'] ?? ''}'),
      count: j?['count'] ?? 0,
      breakdown: {
        for (var s = 1; s <= 5; s++)
          s: b is Map ? int.tryParse('${b['$s'] ?? 0}') ?? 0 : 0,
      },
    );
  }

  /// Share of reviews that gave [stars], 0..1.
  double share(int stars) => count == 0 ? 0 : (breakdown[stars] ?? 0) / count;
}

class ReviewPage {
  final ReviewSummary summary;
  final List<Review> items;
  final int page;
  final int lastPage;
  final int total;

  const ReviewPage(this.summary, this.items, this.page, this.lastPage, this.total);

  bool get hasMore => page < lastPage;

  factory ReviewPage.fromJson(Map<String, dynamic> j) => ReviewPage(
        ReviewSummary.fromJson(j['summary']),
        [for (final r in (j['data'] as List? ?? [])) Review.fromJson(r)],
        j['current_page'] ?? 1,
        j['last_page'] ?? 1,
        j['total'] ?? 0,
      );
}

class ReviewResult {
  /// False while it waits for the dashboard's approval.
  final bool published;
  final bool updated;
  final String message;
  final Review review;

  const ReviewResult(this.published, this.updated, this.message, this.review);
}

/// Patients rate without an account; the phone (never shown) keeps it to one
/// review per person per place.
class ReviewsApi {
  ReviewsApi._();

  static Future<ReviewPage> list(PlaceKind kind, int id, {int page = 1}) async =>
      ReviewPage.fromJson(
          await apiRequest('GET', 'reviews/${kind.apiType}/$id?page=$page'));

  static Future<ReviewResult> submit({
    required PlaceKind kind,
    required int id,
    required int rating,
    required String name,
    required String phone,
    String? comment,
    String? appointmentCode,
  }) async {
    final json = await apiRequest('POST', 'reviews/${kind.apiType}/$id', body: {
      'name': name.trim(),
      'phone': phone.trim(),
      'rating': rating,
      if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      if (appointmentCode != null) 'appointment_code': appointmentCode,
    });
    await MyBookings.rememberPatient(name, phone);
    await MyReviews.save(kind, id, rating);
    return ReviewResult(
      json['status'] == 'approved',
      json['updated'] == true,
      json['message'] ?? 'شكراً لتقييمك',
      Review.fromJson(json['review']),
    );
  }

  // ------------------------------------------------ the signed-in doctor

  static Future<ReviewPage> mine({int page = 1}) async =>
      ReviewPage.fromJson(await DoctorApi.authed('GET', 'doctor/reviews?page=$page'));

  /// An empty [reply] removes it.
  static Future<Review> reply(int reviewId, String reply) async => Review.fromJson(
      await DoctorApi.authed('POST', 'doctor/reviews/$reviewId/reply',
          body: {'reply': reply.trim()}));
}

/// Stars this phone gave each place, so the app can say "your rating".
class MyReviews {
  MyReviews._();

  static const _key = 'my_reviews';

  static String _id(PlaceKind kind, int id) => '${kind.apiType}:$id';

  static Future<Map<String, dynamic>> _all() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    try {
      final v = raw == null ? null : jsonDecode(raw);
      return v is Map<String, dynamic> ? v : {};
    } catch (_) {
      return {};
    }
  }

  static Future<int?> ratingFor(PlaceKind kind, int id) async {
    final v = (await _all())[_id(kind, id)];
    return v is int ? v : null;
  }

  static Future<void> save(PlaceKind kind, int id, int rating) async {
    final all = await _all()..[_id(kind, id)] = rating;
    await (await SharedPreferences.getInstance()).setString(_key, jsonEncode(all));
  }
}

/// "اليوم", "منذ 3 أيام", ... for review dates.
String formatAgo(DateTime? t) {
  if (t == null) return '';
  final days = DateTime.now().difference(t).inDays;
  if (days <= 0) return 'اليوم';
  if (days == 1) return 'أمس';
  if (days == 2) return 'منذ يومين';
  if (days < 7) return 'منذ $days أيام';
  if (days < 14) return 'منذ أسبوع';
  if (days < 30) return 'منذ ${days ~/ 7} أسابيع';
  if (days < 60) return 'منذ شهر';
  if (days < 365) {
    final m = days ~/ 30;
    return m == 2 ? 'منذ شهرين' : 'منذ $m أشهر';
  }
  return '${t.day} ${monthName(t)} ${t.year}';
}
