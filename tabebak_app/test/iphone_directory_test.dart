import 'package:clinic_dr_alla/Pages/home_page/tabs/account-screen/account-screen.dart';
import 'package:clinic_dr_alla/Pages/home_page/tabs/main_screen/vip_spotlight.dart';
import 'package:clinic_dr_alla/data/app_config.dart';
import 'package:clinic_dr_alla/data/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _doctor = {
  'id': 6,
  'name': 'د. علاء',
  'category': {'name': 'الأسنان'},
  'city': {'id': 3, 'name': 'طولكرم'},
  'mobile': '0599000000',
  'booking_enabled': true,
};

final _ios = TargetPlatformVariant.only(TargetPlatform.iOS);
final _android = TargetPlatformVariant.only(TargetPlatform.android);

Ad _sponsor() => Ad.fromJson({
      'id': 1,
      'title': 'عيادة د. علاء',
      'image': 'https://x.ps/1.jpg',
      'placement': 'vip',
      'type': 'doctor',
      'target': _doctor,
    });

Future<void> _show(WidgetTester tester, Widget child) async {
  // Tall enough that the whole More screen is built.
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Directionality(
        textDirection: TextDirection.rtl, child: Scaffold(body: child)),
  ));
  await tester.pump(const Duration(milliseconds: 800));
}

Widget _sponsorCard() =>
    SingleChildScrollView(child: VipSpotlight(ads: [_sponsor()]));

Widget _more() => Profile(
    changeTabIndex: (_) {}, onLanguageSelected: (_) {}, languageCode: 'ar');

void main() {
  group('iPhone: a directory, no booking or sign-in', () {
    test('no doctor takes bookings', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(kPatientFeatures, isFalse);
      expect(Place.fromApi(PlaceKind.doctor, _doctor).bookingEnabled, isFalse);
    });

    testWidgets('the sponsor card offers the page and a call, not booking',
        (tester) async {
      await _show(tester, _sponsorCard());
      expect(find.text('احجز موعدك'), findsNothing);
      expect(find.text('عرض الصفحة'), findsWidgets);
      expect(find.byIcon(Icons.call_rounded), findsWidgets);
      await tester.pumpWidget(const SizedBox());
    }, variant: _ios);

    testWidgets('the More screen has no appointments or doctors sign-in',
        (tester) async {
      await _show(tester, _more());
      expect(find.text('مواعيدي'), findsNothing);
      expect(find.text('دخول الأطباء'), findsNothing);
      expect(find.text('سياسة الخصوصية'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }, variant: _ios);
  });

  group('Android: everything stays', () {
    test('doctors that take bookings still do', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      expect(kPatientFeatures, isTrue);
      expect(Place.fromApi(PlaceKind.doctor, _doctor).bookingEnabled, isTrue);
    });

    testWidgets('the sponsor card offers booking', (tester) async {
      await _show(tester, _sponsorCard());
      expect(find.text('احجز موعدك'), findsWidgets);
      await tester.pumpWidget(const SizedBox());
    }, variant: _android);

    testWidgets('the More screen has appointments and doctors sign-in',
        (tester) async {
      await _show(tester, _more());
      expect(find.text('مواعيدي'), findsOneWidget);
      expect(find.text('دخول الأطباء'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }, variant: _android);
  });
}
