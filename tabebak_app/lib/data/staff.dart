import 'package:clinic_dr_alla/data/booking.dart';
import 'package:clinic_dr_alla/data/models.dart';
import 'package:clinic_dr_alla/data/repository.dart' show kUseDemoData;
import 'package:flutter/widgets.dart' show StringCharacters;

/// Someone on a doctor's or centre's team, as entered on the dashboard.
class StaffMember {
  final int id;
  final String name;
  final String role;
  final String? imageUrl;
  final String? bio;

  /// Set when the member is also a doctor listed in the app.
  final Place? doctor;

  const StaffMember({
    required this.id,
    required this.name,
    required this.role,
    this.imageUrl,
    this.bio,
    this.doctor,
  });

  factory StaffMember.fromJson(Map<String, dynamic> j) {
    final doctor = j['doctor'];
    final bio = (j['bio'] as String?)?.trim();
    return StaffMember(
      id: j['id'] ?? 0,
      name: j['name'] ?? '',
      role: j['role'] ?? '',
      imageUrl: j['image'],
      bio: bio == null || bio.isEmpty ? null : bio,
      doctor: doctor is Map<String, dynamic>
          ? Place.fromApi(PlaceKind.doctor, doctor)
          : null,
    );
  }

  String get initials {
    final words = name
        .replaceFirst('د. ', '')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    return words.take(2).map((w) => w.characters.first).join(' ');
  }
}

class StaffApi {
  StaffApi._();

  /// The place's visible team, in the dashboard's order.
  static Future<List<StaffMember>> list(PlaceKind kind, int id) async {
    if (kUseDemoData) return _demo(kind, id);
    final json = await apiRequest('GET', 'staff/${kind.apiType}/$id');
    return [
      for (final e in (json['data'] as List? ?? const []))
        StaffMember.fromJson(Map<String, dynamic>.from(e as Map)),
    ];
  }

  static const _demoRoles = <PlaceKind, List<String>>{
    PlaceKind.doctor: ['ممرضة العيادة', 'سكرتير العيادة', 'مساعدة الطبيب'],
    PlaceKind.hospital: ['المدير الطبي', 'أخصائي طب الطوارئ', 'رئيسة قسم التمريض', 'أخصائية المختبر'],
    PlaceKind.pharmacy: ['الصيدلاني المسؤول', 'صيدلانية', 'مساعد صيدلي'],
    PlaceKind.laboratory: ['أخصائي مختبرات طبية', 'فنية سحب الدم', 'موظف الاستقبال'],
    PlaceKind.radiology: ['طبيب الأشعة', 'فني تصوير الرنين المغناطيسي', 'فنية الأشعة والألتراساوند'],
    PlaceKind.beauty: ['أخصائية العناية بالبشرة', 'أخصائية الليزر', 'خبيرة التجميل'],
    PlaceKind.warehouse: ['مدير المستودع', 'مندوب المبيعات', 'مسؤولة الحسابات'],
    PlaceKind.nutrition: ['أخصائية التغذية العلاجية', 'أخصائي تغذية رياضية', 'منسقة المتابعة'],
    PlaceKind.optics: ['أخصائي البصريات', 'فني تركيب العدسات', 'مستشارة الإطارات'],
    PlaceKind.physio: ['أخصائي العلاج الطبيعي', 'أخصائية العلاج الطبيعي', 'أخصائي العلاج الوظيفي'],
  };

  static const _demoNames = ['سارة أحمد', 'محمد خليل', 'لينا محمود', 'أحمد سعيد', 'نور خالد', 'يوسف ناصر'];

  static Future<List<StaffMember>> _demo(PlaceKind kind, int id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final roles = _demoRoles[kind] ?? const <String>[];
    return [
      for (var i = 0; i < roles.length; i++)
        StaffMember(
          id: id * 10 + i,
          name: _demoNames[(id + i) % _demoNames.length],
          role: roles[i],
          bio: 'عضو في فريق العمل، جاهز لخدمتكم والإجابة عن استفساراتكم.',
        ),
    ];
  }
}
