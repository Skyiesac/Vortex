import 'package:flutter_test/flutter_test.dart';
import 'package:arrival_bell/utils/distance_calculator.dart';

void main() {
  test('calculates the approximate distance from NYC to London', () {
    final distance = DistanceCalculator.calculateDistanceMeters(
      40.7128,
      -74.0060,
      51.5074,
      -0.1278,
    );
    expect(distance / 1000, closeTo(5570, 15));
  });

  test('formats distances in meters and kilometers', () {
    expect(DistanceCalculator.formatDistance(450), '450m');
    expect(DistanceCalculator.formatDistance(2300), '2.3 km');
  });
}
