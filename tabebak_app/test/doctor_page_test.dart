import 'dart:convert';
import 'dart:io';

import 'package:clinic_dr_alla/Pages/doctor_portal/doctor_page_editor.dart';
import 'package:clinic_dr_alla/Pages/doctor_portal/doctor_reels_page.dart';
import 'package:clinic_dr_alla/Pages/doctor_portal/doctor_team_page.dart';
import 'package:clinic_dr_alla/data/booking.dart' show ApiException;
import 'package:clinic_dr_alla/data/doctor_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
    utf8.encode(jsonEncode(body)), status,
    headers: {'content-type': 'application/json'});

final _pageJson = {
  'doctor': {
    'name': 'د. علاء',
    'category_id': 3,
    'city_id': 1,
    'mobile': '0599357391',
    'address': 'الخليل',
    'description': 'نبذة',
    'facebook_url': null,
    'instagram_url': '',
    'image': 'https://x.ps/storage/',
    'coordinates': [
      {'lat': '31.5', 'lng': '35.1'}
    ],
  },
  'categories': [
    {'id': 3, 'name': 'الأسنان'},
    {'id': 4, 'name': 'الباطني'},
  ],
  'cities': [
    {'id': 1, 'name': 'الخليل'},
  ],
  'staff': [],
};

Map<String, dynamic> _member(int id, String name, {bool active = true}) => {
      'id': id,
      'name': name,
      'role': 'ممرضة',
      'bio': null,
      'image': null,
      'active': active,
    };

Widget _app(Widget page, {double scale = 1}) => MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Builder(
          builder: (c) => MediaQuery(
            data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
            child: page,
          ),
        ),
      ),
    );

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'doctor_token': 'tok'}));

  test('details are read from the API, an empty photo counts as none', () {
    final d = DoctorPageDetails.fromJson(_pageJson);
    expect(d.name, 'د. علاء');
    expect(d.categoryId, 3);
    expect(d.facebook, '');
    expect(d.imageUrl, isNull);
    expect(d.location?.lat, 31.5);
    expect(d.categories.length, 2);
  });

  testWidgets('the doctor edits the page and it is sent with the token',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    http.MultipartRequest? sent;
    final client = MockClient.streaming((request, body) async {
      if (request.method == 'GET') {
        return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode(_pageJson))), 200);
      }
      sent = request as http.MultipartRequest;
      await body.drain<void>();
      return http.StreamedResponse(Stream.value(utf8.encode('{}')), 200);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(_app(const DoctorPageEditor()));
      await _settle(tester);
      expect(find.widgetWithText(TextFormField, 'د. علاء'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'د. علاء'), 'د. علاء الشيخ');
      await tester.tap(find.text('حفظ التعديلات'));
      await _settle(tester);
    }, () => client);

    expect(sent, isNotNull);
    expect(sent!.url.path, endsWith('doctor/page'));
    expect(sent!.headers['Authorization'], 'Bearer tok');
    expect(sent!.fields['name'], 'د. علاء الشيخ');
    expect(sent!.fields['category_id'], '3');
    expect(sent!.fields['city_id'], '1');
    expect(sent!.fields.containsKey('coordinates'), isFalse,
        reason: 'the location is untouched');
    expect(sent!.fields.containsKey('image__remove'), isFalse);
  });

  testWidgets('a server error appears next to its field', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final client = MockClient.streaming((request, body) async {
      await body.drain<void>();
      final res = request.method == 'GET'
          ? _pageJson
          : {
              'message': 'bad',
              'errors': {
                'mobile': ['رقم الهاتف غير صحيح']
              }
            };
      return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode(res))), request.method == 'GET' ? 200 : 422);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(_app(const DoctorPageEditor()));
      await _settle(tester);
      await tester.tap(find.text('حفظ التعديلات'));
      await _settle(tester);
      expect(find.text('رقم الهاتف غير صحيح'), findsWidgets);
      expect(find.text('حفظ التعديلات'), findsOneWidget, reason: 'stays on the form');
    }, () => client);
  });

  for (final scale in [1.0, 1.6]) {
    testWidgets('the editor fits at text size $scale', (tester) async {
      await tester.binding.setSurfaceSize(const Size(340, 2600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final client = MockClient((_) async => _json(_pageJson));
      await http.runWithClient(() async {
        await tester.pumpWidget(_app(const DoctorPageEditor(), scale: scale));
        await _settle(tester);
        expect(tester.takeException(), isNull);
      }, () => client);
    });

    testWidgets('the team list fits at text size $scale', (tester) async {
      await tester.binding.setSurfaceSize(const Size(340, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final client = MockClient((_) async => _json({
            'data': [
              _member(1, 'سارة أحمد عبد الرحمن محمود الخطيب النتشة القواسمي'),
              _member(2, 'لينا', active: false),
            ]
          }));
      await http.runWithClient(() async {
        await tester.pumpWidget(_app(const DoctorTeamPage(), scale: scale));
        await _settle(tester);
        expect(tester.takeException(), isNull);
        expect(find.textContaining('مخفي عن المرضى'), findsOneWidget);
      }, () => client);
    });
  }

  testWidgets('an empty team invites the first member, and adding one sends it',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final team = <Map<String, dynamic>>[];
    final sent = <http.MultipartRequest>[];
    final client = MockClient.streaming((request, body) async {
      await body.drain<void>();
      if (request.method == 'POST') {
        sent.add(request as http.MultipartRequest);
        team.add(_member(9, request.fields['name']!));
      }
      return http.StreamedResponse(
          Stream.value(utf8.encode(jsonEncode({'data': team}))), 200);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(_app(const DoctorTeamPage()));
      await _settle(tester);
      expect(find.text('لا يوجد موظفون بعد'), findsOneWidget);

      await tester.tap(find.text('إضافة موظف'));
      await _settle(tester);
      await tester.tap(find.text('إضافة'));
      await _settle(tester);
      expect(find.text('أدخل الاسم'), findsOneWidget);
      expect(sent, isEmpty, reason: 'an empty form is not sent');

      await tester.enterText(find.widgetWithText(TextFormField, 'الاسم'), 'سارة');
      await tester.enterText(find.widgetWithText(TextFormField, 'الوظيفة'), 'ممرضة');
      await tester.tap(find.text('إضافة'));
      await _settle(tester);

      expect(sent.single.url.path, endsWith('doctor/staff'));
      expect(sent.single.fields['name'], 'سارة');
      expect(sent.single.fields['role'], 'ممرضة');
      expect(sent.single.fields['active'], '1');
      expect(find.text('سارة'), findsOneWidget);
    }, () => client);
  });

  group('reels', () {
    Map<String, dynamic> reel(int id, String title, {bool active = true}) => {
          'id': id,
          'title': title,
          'description': null,
          'video': 'https://x.ps/storage/reels/a.mp4',
          'thumbnail': null,
          'active': active,
          'views': 12,
        };

    for (final scale in [1.0, 1.6]) {
      testWidgets('the list fits at text size $scale', (tester) async {
        await tester.binding.setSurfaceSize(const Size(340, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final client = MockClient((_) async => _json({
              'data': [
                reel(1, 'عنوان طويل جداً عن صحة الأسنان والعناية بها يومياً في البيت والعيادة'),
                reel(2, 'مخفي', active: false),
              ]
            }));
        await http.runWithClient(() async {
          await tester.pumpWidget(_app(const DoctorReelsPage(), scale: scale));
          await _settle(tester);
          expect(tester.takeException(), isNull);
          expect(find.text('12 مشاهدة'), findsNWidgets(2));
          expect(find.text('مخفي عن المرضى'), findsOneWidget);
        }, () => client);
      });
    }

    testWidgets('a new reel cannot be sent without a video', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final posts = <String>[];
      final client = MockClient.streaming((request, body) async {
        await body.drain<void>();
        if (request.method == 'POST') posts.add(request.url.path);
        return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({'data': []}))), 200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(_app(const DoctorReelsPage()));
        await _settle(tester);
        expect(find.text('لا توجد فيديوهات بعد'), findsOneWidget);

        await tester.tap(find.text('إضافة ريل'));
        await _settle(tester);
        await tester.enterText(find.widgetWithText(TextFormField, 'العنوان'), 'نصيحة');
        await tester.tap(find.text('إضافة'));
        await _settle(tester);

        expect(find.text('اختر فيديو من المعرض'), findsOneWidget);
        expect(posts, isEmpty);
      }, () => client);
    });

    testWidgets('editing keeps the video unless a new one is chosen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      http.MultipartRequest? sent;
      final client = MockClient.streaming((request, body) async {
        await body.drain<void>();
        if (request.method == 'POST') sent = request as http.MultipartRequest;
        return http.StreamedResponse(
            Stream.value(utf8.encode(jsonEncode({
              'data': [reel(4, 'قديم')]
            }))),
            200);
      });

      await http.runWithClient(() async {
        await tester.pumpWidget(_app(const DoctorReelsPage()));
        await _settle(tester);
        await tester.tap(find.text('قديم'));
        await _settle(tester);
        await tester.enterText(find.widgetWithText(TextFormField, 'قديم'), 'جديد');
        await tester.tap(find.text('يظهر للمرضى في تبويب الريلز'));
        await _settle(tester);
        await tester.tap(find.text('حفظ التعديلات'));
        await _settle(tester);
      }, () => client);

      expect(sent!.url.path, endsWith('doctor/reels/4'));
      expect(sent!.fields['title'], 'جديد');
      expect(sent!.fields['active'], '0');
      expect(sent!.files, isEmpty);
    });

    test('the video and cover are sent under the names the server expects', () async {
      final dir = await Directory.systemTemp.createTemp('reel_test');
      addTearDown(() => dir.delete(recursive: true));
      final video = File('${dir.path}/clip.mp4')..writeAsBytesSync([1, 2, 3]);
      final cover = File('${dir.path}/cover.jpg')..writeAsBytesSync([4, 5]);
      http.MultipartRequest? sent;
      final client = MockClient.streaming((request, body) async {
        sent = request as http.MultipartRequest;
        await body.drain<void>();
        return http.StreamedResponse(Stream.value(utf8.encode('{}')), 201);
      });

      await http.runWithClient(
        () => DoctorPageApi.saveReel(
            title: ' نصيحة ',
            description: '',
            active: true,
            videoPath: video.path,
            coverPath: cover.path),
        () => client,
      );

      expect(sent!.url.path, endsWith('doctor/reels'));
      expect(sent!.fields['title'], 'نصيحة');
      expect([for (final f in sent!.files) f.field], ['video', 'thumbnail']);
    });

    test('a file the server refuses as too large gets a clear message', () async {
      final client = MockClient.streaming((request, body) async {
        await body.drain<void>();
        return http.StreamedResponse(Stream.value(utf8.encode('<html>413</html>')), 413);
      });
      await http.runWithClient(() async {
        await expectLater(
          DoctorPageApi.saveReel(title: 'x', description: '', active: true),
          throwsA(isA<ApiException>()
              .having((e) => e.message, 'message', contains('أكبر مما يقبله السيرفر'))),
        );
      }, () => client);
    });
  });

  testWidgets('deleting asks first, then removes the member', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final team = [_member(5, 'لينا')];
    final posts = <String>[];
    final client = MockClient((request) async {
      if (request.method == 'POST') {
        posts.add(request.url.path);
        team.clear();
        return http.Response('', 204);
      }
      return _json({'data': team});
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(_app(const DoctorTeamPage()));
      await _settle(tester);
      await tester.tap(find.text('لينا'));
      await _settle(tester);
      await tester.tap(find.text('حذف الموظف'));
      await _settle(tester);
      expect(posts, isEmpty, reason: 'nothing until confirmed');
      await tester.tap(find.widgetWithText(TextButton, 'حذف'));
      await _settle(tester);
      expect(posts.single, endsWith('doctor/staff/5/delete'));
      expect(find.text('لا يوجد موظفون بعد'), findsOneWidget);
    }, () => client);
  });
}
