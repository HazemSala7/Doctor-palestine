import 'dart:math' as math;

import 'package:clinic_dr_alla/data/models.dart';
import 'package:flutter/material.dart';

/// Local test data so every screen can be exercised without the backend.
/// Names and phone numbers are fictional.
class DemoData {
  DemoData._();

  static const cities = <City>[
    City(1, 'القدس', '🕌', Color(0xFFF9A825)),
    City(2, 'رام الله', '🏙️', Color(0xFF1E88E5)),
    City(3, 'نابلس', '🏛️', Color(0xFF8E24AA)),
    City(4, 'الخليل', '🍇', Color(0xFF43A047)),
    City(5, 'بيت لحم', '⭐', Color(0xFFE53935)),
    City(6, 'جنين', '🌾', Color(0xFFFB8C00)),
    City(7, 'طولكرم', '🌳', Color(0xFF00897B)),
    City(8, 'غزة', '🌊', Color(0xFF039BE5)),
  ];

  // City centres, used for demo coordinates.
  static const _coords = <int, List<double>>{
    1: [31.7767, 35.2345],
    2: [31.9038, 35.2034],
    3: [32.2211, 35.2544],
    4: [31.5326, 35.0998],
    5: [31.7054, 35.2024],
    6: [32.4594, 35.3009],
    7: [32.3104, 35.0286],
    8: [31.5017, 34.4668],
  };

  static const specialties = <Specialty>[
    Specialty('باطنية', '🫀', Color(0xFFE53935)),
    Specialty('أطفال', '👶', Color(0xFFFB8C00)),
    Specialty('أسنان', '🦷', Color(0xFF00ACC1)),
    Specialty('نسائية وتوليد', '🤰', Color(0xFFD81B60)),
    Specialty('عيون', '👁️', Color(0xFF3949AB)),
    Specialty('قلب وشرايين', '❤️', Color(0xFFC62828)),
    Specialty('جلدية', '🧴', Color(0xFF8D6E63)),
    Specialty('عظام', '🦴', Color(0xFF546E7A)),
    Specialty('أنف وأذن وحنجرة', '👂', Color(0xFF7CB342)),
    Specialty('أعصاب', '🧠', Color(0xFF8E24AA)),
    Specialty('نفسية', '🧘', Color(0xFF26A69A)),
    Specialty('مسالك بولية', '💧', Color(0xFF1E88E5)),
  ];

  static const promos = <Promo>[
    Promo('فحص شامل بخصم 30٪', 'باقة الفحوصات السنوية في مختبرات مختارة', '🧪',
        [Color(0xFF5E35B1), Color(0xFF42A5F5)], PlaceKind.laboratory),
    Promo('صيدليات مناوبة 24 ساعة', 'اعثر على أقرب صيدلية مفتوحة الآن', '💊',
        [Color(0xFF00897B), Color(0xFF26C6DA)], PlaceKind.pharmacy),
    Promo('ابتسامتك تهمنا', 'أفضل أطباء الأسنان في مدينتك', '🦷',
        [Color(0xFF1565C0), Color(0xFF00BCD4)], PlaceKind.doctor),
    Promo('نظارتك الجديدة', 'فحص نظر مجاني مع كل نظارة', '👓',
        [Color(0xFFEF6C00), Color(0xFFFFCA28)], PlaceKind.optics),
  ];

  static const _male = [
    'أحمد', 'محمد', 'خالد', 'يوسف', 'سامي', 'عمر', 'إبراهيم', 'رامي', //
    'باسل', 'مازن', 'طارق', 'نزار', 'وسيم', 'فادي', 'جهاد', 'كريم',
  ];
  static const _female = [
    'ليلى', 'سارة', 'رنا', 'هبة', 'دانة', 'نور', 'مي', 'ريم', 'لينا', //
    'سلمى', 'آية', 'ديما',
  ];
  static const _family = [
    'الخطيب', 'النتشة', 'عودة', 'حماد', 'الشريف', 'أبو عيشة', 'القواسمي', //
    'دويكات', 'الأغا', 'زيدان', 'منصور', 'سلامة', 'البرغوثي', 'الجعبري',
    'صوالحة', 'عابدين', 'التميمي', 'الحروب',
  ];

  static const _streets = [
    'شارع القدس', 'دوار المنارة', 'شارع الإرسال', 'شارع عين سارة', //
    'شارع فيصل', 'وسط البلد', 'شارع الجامعة', 'شارع الشهداء', 'حي الماصيون',
  ];

  static const _placeNames = <PlaceKind, List<String>>{
    PlaceKind.hospital: [
      'مستشفى الأمل التخصصي', 'مستشفى الرحمة الجراحي', 'مركز النور الطبي', //
      'مستشفى السلام', 'مستشفى الحياة للولادة', 'المركز الطبي العربي',
    ],
    PlaceKind.pharmacy: [
      'صيدلية الشفاء', 'صيدلية النخبة', 'صيدلية الحياة', 'صيدلية ابن سينا', //
      'صيدلية الريان', 'صيدلية المركز',
    ],
    PlaceKind.laboratory: [
      'مختبرات الدقة الطبية', 'مختبر الحكمة', 'مختبرات بيوتك', //
      'مختبر المدينة', 'مختبرات الأمان', 'مختبر الرازي',
    ],
    PlaceKind.radiology: [
      'مركز الأشعة الحديث', 'مركز التصوير الرقمي', 'مركز الرنين المتقدم', //
      'أشعة المدينة', 'مركز بانوراما للتصوير',
    ],
    PlaceKind.beauty: [
      'مركز لمسة جمال', 'عيادة نضارة', 'مركز جلامور للتجميل', //
      'عيادة البشرة الذهبية', 'مركز روز للتجميل',
    ],
    PlaceKind.warehouse: [
      'مستودع الأدوية الوطني', 'مستودع ميديكال بلس', 'المستودع الطبي الحديث', //
      'مستودع الصحة', 'مستودع الرعاية',
    ],
    PlaceKind.nutrition: [
      'مركز توازن للتغذية', 'عيادة رشاقة', 'مركز الحياة الصحية', //
      'عيادة نيوترا', 'مركز وزن مثالي',
    ],
    PlaceKind.optics: [
      'بصريات الرؤية', 'نظارات فيجن', 'بصريات العين الذهبية', //
      'مركز النظر الحديث', 'بصريات لنس',
    ],
    PlaceKind.physio: [
      'مركز حركة للعلاج الطبيعي', 'مركز التأهيل الحديث', 'عيادة فيزيو كير', //
      'مركز العافية', 'مركز الشفاء الحركي',
    ],
  };

  static const _placeTags = <PlaceKind, List<String>>{
    PlaceKind.hospital: [
      'طوارئ 24 ساعة',
      'عناية مكثفة',
      'جراحة',
      'ولادة',
      'تأمين صحي'
    ],
    PlaceKind.pharmacy: [
      'توصيل للمنزل',
      'مناوبة ليلية',
      'مستحضرات تجميل',
      'قياس ضغط'
    ],
    PlaceKind.laboratory: ['سحب منزلي', 'نتائج أونلاين', 'فحوصات شاملة', 'PCR'],
    PlaceKind.radiology: [
      'رنين مغناطيسي',
      'طبقي محوري',
      'ألتراساوند',
      'ماموغرام'
    ],
    PlaceKind.beauty: ['ليزر', 'بشرة', 'فيلر', 'عناية بالشعر'],
    PlaceKind.warehouse: [
      'جملة',
      'مستلزمات جراحية',
      'أجهزة طبية',
      'توريد للمستشفيات'
    ],
    PlaceKind.nutrition: ['أنظمة غذائية', 'تحليل جسم', 'تغذية رياضية', 'سكري'],
    PlaceKind.optics: ['فحص نظر', 'عدسات لاصقة', 'نظارات شمسية', 'نظارات طبية'],
    PlaceKind.physio: [
      'إصابات رياضية',
      'تأهيل بعد العمليات',
      'علاج يدوي',
      'آلام الظهر'
    ],
  };

  static const _doctorAbout = [
    'يقدم رعاية طبية متكاملة تعتمد على أحدث البروتوكولات العلاجية، مع الحرص على شرح الحالة للمريض بوضوح ومتابعته بعد العلاج.',
    'حاصل على البورد في التخصص وخبرة طويلة في المستشفيات الحكومية والخاصة، ويؤمن بأن الوقاية خير من قنطار علاج.',
    'يستقبل المرضى بمواعيد مسبقة لتقليل وقت الانتظار، ويوفر استشارات متابعة عبر الهاتف.',
    'عضو في نقابة الأطباء الفلسطينية، شارك في العديد من المؤتمرات الطبية المحلية والدولية.',
  ];

  static const _placeAbout = {
    PlaceKind.hospital:
        'يضم أقساماً متخصصة وطاقماً طبياً على مدار الساعة، مع أجهزة تشخيص حديثة وغرف عمليات مجهزة بالكامل.',
    PlaceKind.pharmacy:
        'تشكيلة واسعة من الأدوية والمكملات ومستحضرات العناية، مع صيدلاني مختص لتقديم الاستشارة الدوائية.',
    PlaceKind.laboratory:
        'فحوصات مخبرية دقيقة بأجهزة معتمدة، ونتائج سريعة يمكن استلامها إلكترونياً.',
    PlaceKind.radiology:
        'خدمات تصوير طبي متقدمة بإشراف أخصائيي أشعة، مع تقارير مفصلة في نفس اليوم.',
    PlaceKind.beauty:
        'جلسات عناية وتجميل بإشراف طبي وأحدث تقنيات الليزر والعناية بالبشرة.',
    PlaceKind.warehouse:
        'توريد الأدوية والمستلزمات الطبية للصيدليات والمراكز الصحية بأسعار الجملة.',
    PlaceKind.nutrition:
        'برامج تغذية مصممة حسب احتياجك مع متابعة أسبوعية وقياسات دقيقة لمكونات الجسم.',
    PlaceKind.optics:
        'فحص نظر بالكمبيوتر وتشكيلة كبيرة من الإطارات والعدسات العالمية.',
    PlaceKind.physio:
        'برامج علاج طبيعي وتأهيل حركي لمختلف الإصابات بأجهزة حديثة وأخصائيين معتمدين.',
  };

  static String _phone(math.Random r) =>
      '05${r.nextBool() ? 9 : 6}${List.generate(7, (_) => r.nextInt(10)).join()}';

  static List<double> _near(int cityId, math.Random r) {
    final c = _coords[cityId]!;
    return [
      c[0] + (r.nextDouble() - 0.5) * 0.03,
      c[1] + (r.nextDouble() - 0.5) * 0.03,
    ];
  }

  static City cityById(int id) => cities.firstWhere((c) => c.id == id);

  static final List<Place> doctors = _buildDoctors();
  static final Map<PlaceKind, List<Place>> places = _buildPlaces();
  static final List<Place> all = [
    ...doctors,
    for (final list in places.values) ...list,
  ];

  static List<Place> _buildDoctors() {
    final r = math.Random(42);
    final result = <Place>[];
    var id = 1000;
    for (var i = 0; i < 72; i++) {
      final female = i % 3 == 1;
      final first = female
          ? _female[(i * 5) % _female.length]
          : _male[(i * 7) % _male.length];
      final family = _family[(i * 11 + 3) % _family.length];
      final spec = specialties[i % specialties.length];
      final city = cities[(i * 3 + i ~/ 12) % cities.length];
      final pos = _near(city.id, r);
      final opens = [8, 9, 10, 15][r.nextInt(4)];
      result.add(Place(
        id: id++,
        kind: PlaceKind.doctor,
        name: 'د. $first $family',
        specialty: spec.name,
        cityId: city.id,
        city: city.name,
        address: '${city.name} - ${_streets[r.nextInt(_streets.length)]}',
        description: _doctorAbout[i % _doctorAbout.length],
        phone: _phone(r),
        rating: 3.9 + r.nextInt(12) / 10,
        reviews: 12 + r.nextInt(380),
        experience: 3 + r.nextInt(25),
        fee: [50, 70, 80, 100, 120, 150][r.nextInt(6)],
        opensAt: opens,
        closesAt: math.min(opens + 5 + r.nextInt(4), 21),
        workDays: r.nextBool() ? {0, 1, 2, 3, 4} : {0, 1, 2, 3, 4, 5},
        lat: pos[0],
        lng: pos[1],
        tags: [
          if (r.nextBool()) 'استشارة هاتفية',
          if (r.nextInt(3) == 0) 'زيارات منزلية',
          if (r.nextBool()) 'يقبل التأمين',
        ],
        verified: r.nextInt(4) != 0,
      ));
    }
    return result;
  }

  static Map<PlaceKind, List<Place>> _buildPlaces() {
    final r = math.Random(7);
    final result = <PlaceKind, List<Place>>{};
    var id = 5000;
    for (final entry in _placeNames.entries) {
      final kind = entry.key;
      final tags = _placeTags[kind]!;
      final list = <Place>[];
      for (var i = 0; i < entry.value.length; i++) {
        final city = cities[(i * 2 + kind.index) % cities.length];
        final pos = _near(city.id, r);
        final h24 = kind == PlaceKind.hospital ||
            (kind == PlaceKind.pharmacy && i % 3 == 0);
        final opens = [7, 8, 9][r.nextInt(3)];
        list.add(Place(
          id: id++,
          kind: kind,
          name: entry.value[i],
          cityId: city.id,
          city: city.name,
          address: '${city.name} - ${_streets[r.nextInt(_streets.length)]}',
          description: _placeAbout[kind]!,
          phone: _phone(r),
          rating: 3.8 + r.nextInt(13) / 10,
          reviews: 20 + r.nextInt(600),
          experience: 2 + r.nextInt(30),
          open24h: h24,
          opensAt: h24 ? null : opens,
          closesAt: h24 ? null : opens + 10 + r.nextInt(4),
          workDays: const {0, 1, 2, 3, 4, 5},
          lat: pos[0],
          lng: pos[1],
          tags: (List.of(tags)..shuffle(r)).take(2 + r.nextInt(2)).toList(),
          verified: r.nextInt(3) != 0,
        ));
      }
      result[kind] = list;
    }
    return result;
  }

  static final List<Job> jobs = _buildJobs();

  static List<Job> _buildJobs() {
    final r = math.Random(99);
    const data = [
      [
        'ممرض/ة قانوني/ة',
        'مستشفى الأمل التخصصي',
        'دوام كامل',
        '👩‍⚕️',
        '4500 - 5500 ₪'
      ],
      ['صيدلاني/ة', 'صيدلية الشفاء', 'مناوبات', '💊', '4000 - 5000 ₪'],
      [
        'فني/ة مختبر',
        'مختبرات الدقة الطبية',
        'دوام كامل',
        '🧪',
        '3500 - 4500 ₪'
      ],
      ['طبيب/ة عام', 'مركز النور الطبي', 'دوام جزئي', '🩺', 'حسب الخبرة'],
      [
        'أخصائي/ة أشعة',
        'مركز التصوير الرقمي',
        'دوام كامل',
        '🩻',
        '5000 - 6500 ₪'
      ],
      ['موظف/ة استقبال', 'عيادة نضارة', 'دوام جزئي', '🛎️', '2500 ₪'],
      [
        'أخصائي/ة علاج طبيعي',
        'مركز حركة للعلاج الطبيعي',
        'دوام كامل',
        '🦴',
        '4000 - 5200 ₪'
      ],
      [
        'مندوب/ة مبيعات طبية',
        'مستودع ميديكال بلس',
        'دوام كامل',
        '📦',
        'راتب + عمولة'
      ],
      ['أخصائي/ة تغذية', 'مركز توازن للتغذية', 'عن بعد', '🥗', '3000 - 4000 ₪'],
    ];
    return [
      for (var i = 0; i < data.length; i++)
        Job(
          id: 9000 + i,
          title: data[i][0],
          employer: data[i][1],
          type: data[i][2],
          emoji: data[i][3],
          salary: data[i][4],
          cityId: cities[i % cities.length].id,
          city: cities[i % cities.length].name,
          description:
              'نبحث عن شخص متحمس للانضمام إلى فريقنا. المتطلبات: شهادة في التخصص، مزاولة مهنة سارية، مهارات تواصل ممتازة، والقدرة على العمل ضمن فريق. نوفر بيئة عمل محفزة وفرص تدريب وتطوير مستمرة.',
          phone: _phone(r),
          postedDaysAgo: r.nextInt(14),
        ),
    ];
  }
}
