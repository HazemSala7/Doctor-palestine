import 'dart:convert';

import 'package:clinic_dr_alla/services/apis.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Error from the booking API, with the server's Arabic message.
class ApiException implements Exception {
  final String message;
  final int status;
  final Map<String, String> fieldErrors;

  const ApiException(this.message,
      [this.status = 0, this.fieldErrors = const {}]);

  bool get unauthorized => status == 401;

  @override
  String toString() => message;
}

Future<dynamic> _send(String method, String path,
    {Map<String, dynamic>? body, String? token}) async {
  final headers = {
    'Accept': 'application/json',
    if (body != null) 'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
  final uri = Uri.parse('$URL$path');
  http.Response res;
  try {
    res = await (method == 'GET'
            ? http.get(uri, headers: headers)
            : http.post(uri, headers: headers, body: jsonEncode(body ?? {})))
        .timeout(const Duration(seconds: 20));
  } catch (_) {
    throw const ApiException('تعذّر الاتصال، تحقق من الإنترنت وحاول مجدداً');
  }
  return _decode(res);
}

/// A form that can carry files ([files]: field name => path), sent as multipart.
Future<dynamic> _upload(String path, Map<String, String> fields,
    {Map<String, String> files = const {},
    Duration timeout = const Duration(seconds: 60),
    String? token}) async {
  final request = http.MultipartRequest('POST', Uri.parse('$URL$path'))
    ..headers['Accept'] = 'application/json'
    ..fields.addAll(fields);
  if (token != null) request.headers['Authorization'] = 'Bearer $token';
  http.Response res;
  try {
    for (final file in files.entries) {
      request.files
          .add(await http.MultipartFile.fromPath(file.key, file.value));
    }
    res = await http.Response.fromStream(await request.send().timeout(timeout));
  } catch (_) {
    throw const ApiException('تعذّر الاتصال، تحقق من الإنترنت وحاول مجدداً');
  }
  return _decode(res);
}

dynamic _decode(http.Response res) {
  dynamic json;
  try {
    json = jsonDecode(utf8.decode(res.bodyBytes));
  } catch (_) {
    json = null;
  }
  if (res.statusCode >= 200 && res.statusCode < 300) return json;
  if (res.statusCode == 413) {
    throw const ApiException(
        'الملف أكبر مما يقبله السيرفر، جرّب ملفاً أصغر', 413);
  }

  final errors = <String, String>{};
  if (json is Map && json['errors'] is Map) {
    (json['errors'] as Map).forEach((k, v) =>
        errors['$k'] = v is List && v.isNotEmpty ? '${v.first}' : '$v');
  }
  final message = json is Map && json['message'] is String
      ? json['message'] as String
      : res.statusCode == 429
          ? 'محاولات كثيرة، انتظر دقيقة ثم حاول مجدداً'
          : 'حدث خطأ غير متوقع (${res.statusCode})';
  throw ApiException(message, res.statusCode, errors);
}

/// The same request helper for the other API clients (e.g. reviews).
Future<dynamic> apiRequest(String method, String path,
        {Map<String, dynamic>? body, String? token}) =>
    _send(method, path, body: body, token: token);

/// Server timestamps are UTC, written either "2026-11-07 10:00:00" or ISO 8601.
DateTime? parseServerTime(dynamic v) {
  if (v is! String || v.isEmpty) return null;
  var s = v.replaceFirst(' ', 'T');
  if (!RegExp(r'(Z|[+-]\d\d:?\d\d)$').hasMatch(s)) s = '${s}Z';
  return DateTime.tryParse(s)?.toLocal();
}

String _ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseYmd(String s) {
  final p = s.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

// ---------------------------------------------------------------- models

class Slot {
  final String time;
  final bool available;

  const Slot(this.time, this.available);
}

class Availability {
  final bool enabled;
  final Set<int> workDays;
  final DateTime today;
  final int daysAhead;
  final List<Slot> slots;

  const Availability({
    required this.enabled,
    this.workDays = const {},
    required this.today,
    this.daysAhead = 30,
    this.slots = const [],
  });

  factory Availability.fromJson(Map<String, dynamic> j) => Availability(
        enabled: j['enabled'] == true,
        workDays: {for (final d in (j['work_days'] as List? ?? [])) d as int},
        today: j['today'] != null ? parseYmd(j['today']) : DateTime.now(),
        daysAhead: j['days_ahead'] ?? 30,
        slots: [
          for (final s in (j['slots'] as List? ?? []))
            Slot(s['time'], s['available'] == true)
        ],
      );
}

enum AppointmentStatus {
  pending('بانتظار التأكيد'),
  confirmed('مؤكد'),
  completed('تمت الزيارة'),
  cancelled('ملغي');

  final String label;
  const AppointmentStatus(this.label);

  static AppointmentStatus parse(String? s) => AppointmentStatus.values
      .firstWhere((v) => v.name == s, orElse: () => AppointmentStatus.pending);
}

class Appointment {
  final int id;
  final int doctorId;
  final DateTime date;
  final String time;
  final AppointmentStatus status;
  final String patientName;
  final String patientPhone;
  final String? notes;

  /// Patient side only: the secret that identifies this booking.
  final String? code;
  final String? doctorName;
  final String? doctorImage;
  final String? doctorPhone;
  final String? doctorAddress;

  const Appointment({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.time,
    required this.status,
    this.patientName = '',
    this.patientPhone = '',
    this.notes,
    this.code,
    this.doctorName,
    this.doctorImage,
    this.doctorPhone,
    this.doctorAddress,
  });

  factory Appointment.fromJson(Map<String, dynamic> j, {String? code}) {
    final doctor = j['doctor'] is Map ? j['doctor'] as Map : const {};
    return Appointment(
      id: j['id'] ?? 0,
      doctorId: j['doctor_id'] ?? 0,
      date: parseYmd(j['date']),
      time: j['time'] ?? '',
      status: AppointmentStatus.parse(j['status']),
      patientName: j['patient_name'] ?? '',
      patientPhone: j['patient_phone'] ?? '',
      notes: j['notes'],
      code: j['code'] ?? code,
      doctorName: doctor['name'],
      doctorImage: doctor['image'],
      doctorPhone: doctor['mobile'],
      doctorAddress: doctor['address'],
    );
  }

  DateTime get startsAt {
    final p = time.split(':').map(int.parse).toList();
    return DateTime(date.year, date.month, date.day, p[0], p[1]);
  }

  bool get isActive =>
      status == AppointmentStatus.pending ||
      status == AppointmentStatus.confirmed;

  bool get isUpcoming => startsAt.isAfter(DateTime.now());
}

class DoctorSchedule {
  final bool bookingEnabled;
  final Set<int> workDays;
  final String workStart;
  final String workEnd;
  final int slotMinutes;

  const DoctorSchedule({
    required this.bookingEnabled,
    required this.workDays,
    required this.workStart,
    required this.workEnd,
    required this.slotMinutes,
  });

  factory DoctorSchedule.fromJson(Map<String, dynamic> j) => DoctorSchedule(
        bookingEnabled: j['booking_enabled'] == true,
        workDays: {for (final d in (j['work_days'] as List? ?? [])) d as int},
        workStart: j['work_start'] ?? '09:00',
        workEnd: j['work_end'] ?? '17:00',
        slotMinutes: j['slot_minutes'] ?? 30,
      );

  Map<String, dynamic> toJson() => {
        'booking_enabled': bookingEnabled,
        'work_days': workDays.toList()..sort(),
        'work_start': workStart,
        'work_end': workEnd,
        'slot_minutes': slotMinutes,
      };

  /// Slots offered on each working day.
  int get slotsPerDay {
    int minutes(String t) {
      final p = t.split(':').map(int.parse).toList();
      return p[0] * 60 + p[1];
    }

    final span = minutes(workEnd) - minutes(workStart);
    return span <= 0 ? 0 : span ~/ slotMinutes;
  }
}

class DoctorProfile {
  final String name;
  final String? image;
  final String? specialty;
  final String phone;
  final DoctorSchedule schedule;

  const DoctorProfile({
    required this.name,
    this.image,
    this.specialty,
    required this.phone,
    required this.schedule,
  });

  factory DoctorProfile.fromJson(Map<String, dynamic> j) {
    final doctor = j['doctor'] is Map ? j['doctor'] as Map : const {};
    return DoctorProfile(
      name: doctor['name'] ?? '',
      image: doctor['image'],
      specialty: doctor['specialty'],
      phone: j['account']?['phone'] ?? '',
      schedule: DoctorSchedule.fromJson(j['account'] ?? {}),
    );
  }
}

class AppointmentSummary {
  final int today;
  final int pending;
  final int confirmed;

  const AppointmentSummary(this.today, this.pending, this.confirmed);
}

// ---------------------------------------------------------- patient API

class BookingApi {
  BookingApi._();

  static Future<Availability> availability(int doctorId,
      [DateTime? date]) async {
    final q = date == null ? '' : '?date=${_ymd(date)}';
    return Availability.fromJson(
        await _send('GET', 'doctors/$doctorId/booking$q'));
  }

  static Future<Appointment> book({
    required int doctorId,
    required DateTime date,
    required String time,
    required String name,
    required String phone,
    String? notes,
  }) async {
    final json = await _send('POST', 'doctors/$doctorId/appointments', body: {
      'patient_name': name.trim(),
      'patient_phone': phone.trim(),
      'date': _ymd(date),
      'time': time,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    });
    final appointment = Appointment.fromJson(json);
    await MyBookings.add(appointment.code!);
    await MyBookings.rememberPatient(name, phone);
    return appointment;
  }

  static Future<Appointment> fetch(String code) async =>
      Appointment.fromJson(await _send('GET', 'appointments/$code'),
          code: code);

  static Future<Appointment> cancel(String code) async =>
      Appointment.fromJson(await _send('POST', 'appointments/$code/cancel'),
          code: code);
}

/// Bookings made from this phone. Patients have no account, so the secret
/// codes are kept on the device.
class MyBookings {
  MyBookings._();

  static const _codesKey = 'booking_codes';
  static const _nameKey = 'booking_patient_name';
  static const _phoneKey = 'booking_patient_phone';

  static Future<List<String>> codes() async =>
      (await SharedPreferences.getInstance()).getStringList(_codesKey) ?? [];

  static Future<void> add(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_codesKey) ?? [];
    await prefs
        .setStringList(_codesKey, [code, ...list.where((c) => c != code)]);
  }

  static Future<void> remove(String code) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_codesKey) ?? [];
    await prefs.setStringList(_codesKey, list.where((c) => c != code).toList());
  }

  /// Every booking still on the server, newest first.
  static Future<List<Appointment>> load() async {
    final result = <Appointment>[];
    for (final code in await codes()) {
      try {
        result.add(await BookingApi.fetch(code));
      } on ApiException catch (e) {
        if (e.status == 404) {
          await remove(code); // deleted from the dashboard
        } else {
          rethrow;
        }
      }
    }
    result.sort((a, b) => b.startsAt.compareTo(a.startsAt));
    return result;
  }

  static Future<void> rememberPatient(String name, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name.trim());
    await prefs.setString(_phoneKey, phone.trim());
  }

  static Future<(String, String)> lastPatient() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_nameKey) ?? '', prefs.getString(_phoneKey) ?? '');
  }
}

// ----------------------------------------------------------- doctor API

/// The signed-in doctor. The token lives in shared preferences.
class DoctorApi {
  DoctorApi._();

  static const _tokenKey = 'doctor_token';

  static Future<String?> token() async =>
      (await SharedPreferences.getInstance()).getString(_tokenKey);

  static Future<bool> get signedIn async => (await token()) != null;

  static Future<void> _saveToken(String token) async =>
      (await SharedPreferences.getInstance()).setString(_tokenKey, token);

  static Future<void> logout() async =>
      (await SharedPreferences.getInstance()).remove(_tokenKey);

  /// A request as the signed-in doctor. Signs out on a 401 so the next
  /// screen asks for the password again.
  static Future<dynamic> authed(String method, String path,
      {Map<String, dynamic>? body}) async {
    try {
      return await _send(method, path, body: body, token: await token());
    } on ApiException catch (e) {
      if (e.unauthorized) await logout();
      rethrow;
    }
  }

  /// Like [authed], for a form that can carry files ([files]: field name => path).
  static Future<dynamic> authedUpload(String path, Map<String, String> fields,
      {Map<String, String> files = const {},
      Duration timeout = const Duration(seconds: 60)}) async {
    try {
      return await _upload(path, fields,
          files: files, timeout: timeout, token: await token());
    } on ApiException catch (e) {
      if (e.unauthorized) await logout();
      rethrow;
    }
  }

  static Future<DoctorProfile> login(String phone, String password) async {
    final json = await _send('POST', 'doctor/login',
        body: {'phone': phone.trim(), 'password': password});
    await _saveToken(json['token']);
    return DoctorProfile.fromJson(json);
  }

  static Future<DoctorProfile> me() async =>
      DoctorProfile.fromJson(await authed('GET', 'doctor/me'));

  static Future<(List<Appointment>, AppointmentSummary)> appointments(
      String scope) async {
    final json = await authed('GET', 'doctor/appointments?scope=$scope');
    final s = json['summary'] ?? {};
    return (
      [for (final a in json['data'] as List) Appointment.fromJson(a)],
      AppointmentSummary(
          s['today'] ?? 0, s['pending'] ?? 0, s['confirmed'] ?? 0),
    );
  }

  static Future<Appointment> setStatus(
          int id, AppointmentStatus status) async =>
      Appointment.fromJson(await authed(
          'POST', 'doctor/appointments/$id/status',
          body: {'status': status.name}));

  static Future<DoctorProfile> saveSchedule(DoctorSchedule schedule) async =>
      DoctorProfile.fromJson(
          await authed('POST', 'doctor/schedule', body: schedule.toJson()));

  static Future<void> changePassword(String current, String next) async {
    final json = await authed('POST', 'doctor/password',
        body: {'current_password': current, 'password': next});
    await _saveToken(json['token']);
  }

  /// Deletes the signed-in doctor's account for good and signs out.
  /// Returns how many upcoming bookings were cancelled with it.
  static Future<int> deleteAccount(String password) async {
    final json = await authed('POST', 'doctor/account/delete',
        body: {'password': password});
    await logout();
    return (json['cancelled_appointments'] as num?)?.toInt() ?? 0;
  }
}

// ------------------------------------------------------------ formatting

const kWeekdays = [
  'السبت',
  'الأحد',
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة'
];

const _months = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر'
];

/// 0 = Saturday ... 6 = Friday, as the API and [Place.workDays] number days.
int weekdayIndex(DateTime d) => (d.weekday + 1) % 7;

String monthName(DateTime d) => _months[d.month - 1];

/// "الأحد 8 نوفمبر"
String formatDay(DateTime d) =>
    '${kWeekdays[weekdayIndex(d)]} ${d.day} ${monthName(d)}';

/// "16:30" -> "4:30 م"
String formatTime(String hhmm) {
  final p = hhmm.split(':').map(int.parse).toList();
  final h = p[0] % 12 == 0 ? 12 : p[0] % 12;
  return '$h:${p[1].toString().padLeft(2, '0')} ${p[0] < 12 ? 'ص' : 'م'}';
}
