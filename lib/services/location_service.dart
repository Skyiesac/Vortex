import 'dart:io';

import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  Stream<geo.ServiceStatus> get serviceStatusStream =>
      geo.Geolocator.getServiceStatusStream();

  Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  Future<void> openLocationSettings() async {
    await geo.Geolocator.openLocationSettings();
  }

  Future<bool> checkPermission() async {
    final whenInUse = await Permission.locationWhenInUse.status;
    if (!whenInUse.isGranted) {
      final requestedWhenInUse = await Permission.locationWhenInUse.request();
      if (!requestedWhenInUse.isGranted) return false;
    }

    final always = await Permission.locationAlways.status;
    if (always.isGranted) return true;

    final requestedAlways = await Permission.locationAlways.request();
    return requestedAlways.isGranted;
  }

  Future<bool> isLocationEnabled() => geo.Geolocator.isLocationServiceEnabled();

  Future<geo.Position?> getCurrentPosition() async {
    try {
      if (!await isLocationEnabled() || !await checkPermission()) return null;
      return await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on Exception {
      return null;
    }
  }

  Future<void> requestBatteryOptimizationExemption() async {
    if (Platform.isAndroid) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }
}
