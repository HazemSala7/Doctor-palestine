import 'package:clinic_dr_alla/Pages/ads/premium_ad_window.dart';
import 'package:clinic_dr_alla/data/app_config.dart';
import 'package:clinic_dr_alla/data/repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _json(int id, String placement, Map<String, dynamic> target) => {
      'id': id,
      'title': 'ابتسامة هوليوود',
      'description': 'خصم 20٪ على تبييض الأسنان',
      'image': 'https://x.ps/$id.jpg',
      'placement': placement,
      'type': 'doctor',
      'target': target,
    };

const _doctor = {
  'id': 6,
  'name': 'د. علاء سالم',
  'category': {'name': 'طب الأسنان'},
  'city': {'id': 3, 'name': 'طولكرم'},
  'mobile': '0599000000',
  'rating_avg': 4.5,
  'rating_count': 12,
  'booking_enabled': true,
};

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
}

Widget _host(Widget child, [double scale = 1]) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    );

void main() {
  for (final scale in [1.0, 1.6]) {
    testWidgets('presents the exclusive sponsor and fits at text size $scale', (tester) async {
      _phone(tester);
      final ad = Ad.fromJson(_json(1, 'vip', _doctor));
      await tester.pumpWidget(_host(Scaffold(body: SponsorWindow(ad: ad)), scale));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);

      expect(find.text('👑 الراعي الحصري'), findsOneWidget);
      expect(find.text('لتطبيق طبيبك'), findsOneWidget);
      expect(find.text('د. علاء سالم'), findsOneWidget);
      expect(find.text('طب الأسنان • طولكرم'), findsOneWidget);
      expect(find.text('4.5 (12)'), findsOneWidget);
      expect(find.text('ابتسامة هوليوود'), findsOneWidget);
      expect(find.text('خصم 20٪ على تبييض الأسنان'), findsOneWidget);
      expect(find.text('احجز موعدك'), findsOneWidget);
      expect(find.byIcon(Icons.call_rounded), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });
  }

  testWidgets('opens on app start for a VIP ad, only once per launch, and closes after the countdown', (tester) async {
    _phone(tester);
    SharedPreferences.setMockInitialValues({});
    Repository.config = AppConfig.fromJson({
      'advertisements': [
        _json(2, 'premium', _doctor)..['title'] = 'مميز عادي',
        _json(1, 'vip', _doctor),
      ],
    });
    addTearDown(() => Repository.config = const AppConfig());

    late BuildContext ctx;
    await tester.pumpWidget(_host(Builder(builder: (c) {
      ctx = c;
      return const Scaffold();
    })));

    await tester.runAsync(() async {
      maybeShowPremiumAd(ctx);
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(SponsorWindow), findsOneWidget, reason: 'the VIP wins over the premium ad');
    expect(find.byType(PremiumAdWindow), findsNothing);

    // The close button waits three seconds.
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byIcon(Icons.close_rounded));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(SponsorWindow), findsNothing);

    // A rebuilt home screen in the same launch isn't a new entry.
    Future<void> enter({bool returning = false}) async {
      await tester.runAsync(() async {
        maybeShowPremiumAd(ctx, returning: returning);
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump(const Duration(milliseconds: 600));
    }

    await enter();
    expect(find.byType(SponsorWindow), findsNothing);

    // Coming back to the app is: it opens again, and only once even if asked twice.
    await enter(returning: true);
    expect(find.byType(SponsorWindow), findsOneWidget);
    await enter(returning: true);
    expect(find.byType(SponsorWindow), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });
}
