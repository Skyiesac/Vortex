import 'dart:math' as math;

class DistanceCalculator {
  static double calculateDistanceMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusMeters = 6371000.0;
    final latitudeDelta = _toRadians(lat2 - lat1);
    final longitudeDelta = _toRadians(lng2 - lng1);
    final latitude1 = _toRadians(lat1);
    final latitude2 = _toRadians(lat2);
    final haversine =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(latitude1) *
            math.cos(latitude2) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);
    final centralAngle =
        2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
    return earthRadiusMeters * centralAngle;
  }

  static String formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()}m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
