import 'package:clinic_dr_alla/Pages/home_page/tabs/main_screen/jobs_banner.dart';
import 'package:clinic_dr_alla/data/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Job _job(int id, String title,
        {String type = 'دوام كامل',
        bool featured = false,
        int? days = 1,
        String phone = ''}) =>
    Job(
      id: id,
      title: title,
      employer: 'مستشفى الأهلي في مدينة الخليل - قسم الموارد البشرية',
      type: type,
      city: 'الخليل',
      description: 'تفاصيل الوظيفة $id',
      phone: phone,
      postedDaysAgo: days,
      featured: featured,
    );

Widget _app(List<Job> jobs, {double scale = 1, VoidCallback? onSeeAll, int total = 12}) =>
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: MediaQueryData(
              size: const Size(360, 700),
              textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: JobsHomeBanner(
                  jobs: jobs, total: total, onSeeAll: onSeeAll ?? () {}),
            ),
          ),
        ),
      ),
    );

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 5));
}

void main() {
  testWidgets('rotates through the jobs and loops back', (tester) async {
    await tester.pumpWidget(_app([_job(1, 'ممرض'), _job(2, 'صيدلاني')]));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('ممرض'), findsOneWidget);
    expect(find.text('12 وظيفة'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('صيدلاني'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('ممرض'), findsOneWidget);
    await _finish(tester);
  });

  testWidgets('long text fits at large text sizes', (tester) async {
    final long = 'أخصائي تصوير بالرنين المغناطيسي والأشعة المقطعية ' * 3;
    for (final scale in [1.0, 1.3, 1.6]) {
      await tester.pumpWidget(_app(
          [_job(1, long, type: long, featured: true), _job(2, long)],
          scale: scale));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull, reason: 'text scale $scale');
    }
    await _finish(tester);
  });

  testWidgets('a single job does not rotate; tapping shows its details',
      (tester) async {
    await tester.pumpWidget(_app([_job(7, 'فني مختبر')], total: 1));
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('فني مختبر'), findsOneWidget);
    expect(find.text('وظيفة واحدة'), findsOneWidget);

    await tester.tap(find.text('فني مختبر'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('تفاصيل الوظيفة 7'), findsOneWidget);
    expect(find.text('قدّم الآن عبر واتساب'), findsNothing);
    await _finish(tester);
  });

  testWidgets('a job with a contact number offers WhatsApp', (tester) async {
    await tester.pumpWidget(
        _app([_job(8, 'فني أشعة', phone: '0591234567')], total: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('فني أشعة'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('قدّم الآن عبر واتساب'), findsOneWidget);
    await _finish(tester);
  });

  test('the contact number is read from the API row', () {
    expect(Job.fromApi({'id': 1, 'mobile': ' 0591234567 '}).phone, '0591234567');
    expect(Job.fromApi({'id': 2, 'mobile': null}).phone, '');
    expect(Job.fromApi({'id': 3}).phone, '');
  });

  testWidgets('the header opens the full list', (tester) async {
    var opened = 0;
    await tester.pumpWidget(_app([_job(1, 'ممرض')], onSeeAll: () => opened++));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('عرض الكل'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(opened, 1);
    await _finish(tester);
  });

  test('a record with no picture is treated as having none', () {
    expect(mediaUrl('https://x.ps/storage/'), isNull);
    expect(mediaUrl(''), isNull);
    expect(mediaUrl(null), isNull);
    expect(mediaUrl('https://x.ps/storage/a.jpg'), 'https://x.ps/storage/a.jpg');
    final doctor = Place.fromApi(PlaceKind.doctor,
        {'id': 1, 'name': 'د. علاء', 'image': 'https://x.ps/storage/'});
    expect(doctor.logoUrl, isNull);
    expect(doctor.coverUrl, isNull);
  });

  test('API rows get Arabic types and their real age', () {
    final j = Job.fromApi({
      'id': 1,
      'title': 'ممرض',
      'type': 'part-time',
      'featured': 1,
      'created_at':
          DateTime.now().subtract(const Duration(days: 10)).toUtc().toIso8601String(),
    });
    expect(j.type, 'دوام جزئي');
    expect(j.featured, isTrue);
    expect(j.postedDaysAgo, 10);
    expect(j.isNew, isFalse);

    final noDate = Job.fromApi({'id': 2, 'title': 'x', 'type': 'أخرى'});
    expect(noDate.type, 'أخرى');
    expect(noDate.postedDaysAgo, isNull);
    expect(noDate.isNew, isFalse);
    expect(noDate.featured, isFalse);
  });
}
