import 'dart:convert';

import 'package:clinic_dr_alla/Pages/doctor_portal/doctor_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(Object body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status,
        headers: {'content-type': 'application/json'});

/// A button that opens the dialog and keeps what it pops with.
Widget _host(void Function(int?) onResult, {double scale = 1}) => MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Builder(
          builder: (c) => MediaQuery(
            data:
                MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async => onResult(await showDialog<int>(
                      context: c, builder: (_) => const DeleteAccountDialog())),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'doctor_token': 'tok'}));

  for (final scale in [1.0, 1.6]) {
    testWidgets('says what goes and what stays, and fits at text size $scale',
        (tester) async {
      await tester.pumpWidget(_host((_) {}, scale: scale));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('حذف حسابي نهائياً'), findsOneWidget);
      expect(find.textContaining('تبقى صفحتك في دليل الأطباء'), findsOneWidget);
      expect(find.textContaining('تُلغى الحجوزات القادمة'), findsOneWidget);
      expect(find.text('احذف حسابي'), findsOneWidget);
    });
  }

  testWidgets(
      'asks for the password, shows a wrong one, then deletes and signs out',
      (tester) async {
    final sent = <Map<String, dynamic>>[];
    final client = MockClient((request) async {
      expect(request.url.path, endsWith('doctor/account/delete'));
      expect(request.headers['Authorization'], 'Bearer tok');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      sent.add(body);
      if (body['password'] != 'secret1') {
        return _json({
          'message': 'كلمة المرور غير صحيحة',
          'errors': {
            'password': ['كلمة المرور غير صحيحة']
          },
        }, 422);
      }
      return _json({'deleted': true, 'cancelled_appointments': 2});
    });

    int? result = -1;
    await http.runWithClient(() async {
      await tester.pumpWidget(_host((r) => result = r));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Nothing is sent without a password.
      await tester.tap(find.text('احذف حسابي'));
      await tester.pump();
      expect(find.text('اكتب كلمة المرور لتأكيد الحذف'), findsOneWidget);
      expect(sent, isEmpty);

      await tester.enterText(find.byType(TextField), 'wrong');
      await tester.tap(find.text('احذف حسابي'));
      await tester
          .runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
      expect(find.text('كلمة المرور غير صحيحة'), findsOneWidget);
      expect(find.byType(DeleteAccountDialog), findsOneWidget,
          reason: 'still open');

      await tester.enterText(find.byType(TextField), 'secret1');
      await tester.tap(find.text('احذف حسابي'));
      await tester
          .runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
    }, () => client);

    expect(sent.map((b) => b['password']), ['wrong', 'secret1']);
    expect(find.byType(DeleteAccountDialog), findsNothing);
    expect(result, 2);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('doctor_token'), isNull, reason: 'signed out');
  });

  testWidgets('going back deletes nothing', (tester) async {
    var calls = 0;
    int? result = -1;
    await http.runWithClient(() async {
      await tester.pumpWidget(_host((r) => result = r));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تراجع'));
      await tester.pumpAndSettle();
    },
        () => MockClient((_) async {
              calls++;
              return _json({});
            }));
    expect(calls, 0);
    expect(result, isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('doctor_token'), 'tok');
  });
}
