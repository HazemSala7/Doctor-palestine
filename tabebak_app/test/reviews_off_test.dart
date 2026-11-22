import 'package:clinic_dr_alla/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('with reviews switched off, no place carries a rating', () {
    expect(kReviewsEnabled, isFalse);
    final p = Place.fromApi(PlaceKind.doctor, {
      'id': 6,
      'name': 'د. علاء',
      'rating_avg': 4.8,
      'rating_count': 12,
    });
    expect(p.rating, isNull);
    expect(p.reviews, isNull);
    // Demo data, built directly, is covered too.
    const demo = Place(
        id: 1,
        kind: PlaceKind.doctor,
        name: 'x',
        city: '',
        address: '',
        description: '',
        phone: '',
        rating: 4.9,
        reviews: 30);
    expect(demo.rating, isNull);
    expect(demo.reviews, isNull);
  });
}
