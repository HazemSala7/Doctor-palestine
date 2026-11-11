import 'package:clinic_dr_alla/Pages/home_page/tabs/main_screen/home_ad_carousel.dart';
import 'package:clinic_dr_alla/Pages/home_page/tabs/main_screen/vip_spotlight.dart';
import 'package:clinic_dr_alla/data/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(List<AdSlide> slides) => MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: HomeAdCarousel(slides: slides)),
      ),
    );

const _three = [
  AdSlide('https://x.ps/1.jpg', title: 'أول'),
  AdSlide('https://x.ps/2.jpg', title: 'ثاني'),
  AdSlide('https://x.ps/3.jpg', title: 'ثالث'),
];

double _page(WidgetTester tester) =>
    tester.widget<PageView>(find.byType(PageView)).controller!.page!;

Future<void> _wait(WidgetTester tester, Duration time) async {
  await tester.pump(time);
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('moves by itself and keeps looping past the last slide', (tester) async {
    await tester.pumpWidget(_app(_three));
    await tester.pump();
    final start = _page(tester);

    for (var turn = 1; turn <= 4; turn++) {
      await _wait(tester, const Duration(seconds: 4));
      expect(_page(tester), closeTo(start + turn, 0.01));
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('holds still while a finger is on it', (tester) async {
    await tester.pumpWidget(_app(_three));
    await tester.pump();
    final start = _page(tester);

    final finger = await tester.startGesture(tester.getCenter(find.byType(PageView)));
    await _wait(tester, const Duration(seconds: 9));
    expect(_page(tester), closeTo(start, 0.01));

    await finger.up();
    await _wait(tester, const Duration(seconds: 4));
    expect(_page(tester), closeTo(start + 1, 0.01));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('one slide stays put', (tester) async {
    await tester.pumpWidget(_app(const [AdSlide('https://x.ps/1.jpg', title: 'وحيد')]));
    await tester.pump();
    await _wait(tester, const Duration(seconds: 9));
    expect(_page(tester), 0);
    expect(find.byType(AnimatedContainer), findsNothing, reason: 'no dots for one slide');
  });

  testWidgets('tapping a slide opens its target', (tester) async {
    var opened = 0;
    await tester.pumpWidget(_app([
      AdSlide('https://x.ps/1.jpg', title: 'أول', onTap: () => opened++),
      const AdSlide('https://x.ps/2.jpg', title: 'ثاني'),
    ]));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tapAt(tester.getCenter(find.byType(PageView)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(opened, 1);
    await tester.pumpWidget(const SizedBox());
  });

  group('VIP section', () {
    final doctor = _ad(1, 'ابتسامة هوليوود', 'doctor', {
      'id': 6,
      'name': 'د. علاء سالم',
      'category': {'name': 'طب الأسنان'},
      'city': {'id': 3, 'name': 'طولكرم'},
      'mobile': '0599000000',
      'rating_avg': 4.8,
      'rating_count': 12,
      'booking_enabled': true,
    }, description: 'خصم 20٪ على تبييض الأسنان');
    final centre = _ad(2, 'فحص شامل', 'radiology', {
      'id': 9,
      'name': 'مركز النور للأشعة',
      'city': {'id': 1, 'name': 'نابلس'},
    });

    for (final scale in [1.0, 1.6]) {
      testWidgets('shows the doctor itself and fits at text size $scale', (tester) async {
        tester.view.physicalSize = const Size(1080, 2340);
        tester.view.devicePixelRatio = 2.625;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_spotlight([doctor, centre], scale));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);

        expect(find.text('لتطبيق طبيبك'), findsOneWidget, reason: 'its own section header');
        expect(find.text('👑 الراعي الحصري'), findsWidgets);
        expect(find.text('د. علاء سالم'), findsWidgets);
        expect(find.text('طب الأسنان • طولكرم'), findsWidgets);
        expect(find.text('4.8'), findsWidgets);
        expect(find.textContaining('خصم 20٪ على تبييض الأسنان'), findsWidgets);
        expect(find.text('احجز موعدك'), findsWidgets, reason: 'the doctor takes bookings');
        expect(find.byIcon(Icons.call_rounded), findsWidgets);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('a centre without bookings offers its page, and the cards rotate', (tester) async {
      await tester.pumpWidget(_spotlight([centre, doctor], 1.0));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('مركز النور للأشعة'), findsWidgets);
      expect(find.text('عرض الصفحة'), findsWidgets);

      final start = _page(tester);
      await _wait(tester, const Duration(seconds: 4));
      expect(_page(tester), closeTo(start + 1, 0.01));
      await tester.pumpWidget(const SizedBox());
    });
  });

  test('a VIP ad is also premium, and gets the section only with a doctor or centre', () {
    final config = AppConfig.fromJson({
      'advertisements': [
        {'id': 1, 'title': 'نخبة', 'image': 'https://x.ps/v.jpg', 'placement': 'vip', 'type': 'doctor', 'target': {'id': 6, 'name': 'د. علاء'}},
        {'id': 4, 'title': 'محذوف', 'image': 'https://x.ps/d.jpg', 'placement': 'vip', 'type': 'doctor', 'target': null},
        {'id': 2, 'title': 'مميز', 'image': 'https://x.ps/p.jpg', 'placement': 'premium'},
        {'id': 3, 'title': 'عادي', 'image': 'https://x.ps/b.jpg', 'placement': 'banner'},
      ],
    });
    expect([for (final a in config.vipAds) a.title], ['نخبة']);
    expect(config.ads[0].premium, isTrue);
    expect(config.ads[2].vip, isFalse);
    expect(config.ads[3].premium, isFalse);
  });
}

Ad _ad(int id, String title, String type, Map<String, dynamic> target, {String description = ''}) =>
    Ad.fromJson({
      'id': id,
      'title': title,
      'image': 'https://x.ps/$id.jpg',
      'placement': 'vip',
      'description': description,
      'type': type,
      'target': target,
    });

Widget _spotlight(List<Ad> ads, double scale) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: SingleChildScrollView(child: VipSpotlight(ads: ads))),
        ),
      ),
    );
