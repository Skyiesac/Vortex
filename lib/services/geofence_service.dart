import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as background_geolocation;

import '../config/app_constants.dart';
import '../models/alarm.dart';

class GeofenceService {
  Future<void> initialize() async {
    await background_geolocation.BackgroundGeolocation.ready(
      background_geolocation.Config(
        desiredAccuracy: background_geolocation.Config.DESIRED_ACCURACY_HIGH,
        distanceFilter: 10,
        stopOnTerminate: false,
        startOnBoot: true,
        enableHeadless: true,
        debug: false,
        logLevel: background_geolocation.Config.LOG_LEVEL_WARNING,
        notification: background_geolocation.Notification(
          title: 'vortex',
          text: 'Monitoring your alarms...',
        ),
      ),
    );
  }

  Future<void> addGeofence(Alarm alarm) async {
    await background_geolocation.BackgroundGeolocation.addGeofence(
      background_geolocation.Geofence(
        identifier: alarm.id,
        latitude: alarm.targetLat,
        longitude: alarm.targetLng,
        radius: alarm.radiusInMeters + geofenceBufferMeters,
        notifyOnEntry: true,
        notifyOnExit: false,
        notifyOnDwell: false,
      ),
    );
  }

  Future<void> removeGeofence(String alarmId) async {
    await background_geolocation.BackgroundGeolocation.removeGeofence(alarmId);
  }

  Future<void> removeAllGeofences() async {
    await background_geolocation.BackgroundGeolocation.removeGeofences();
  }

  Future<void> reRegisterAllGeofences(List<Alarm> activeAlarms) async {
    for (final alarm in activeAlarms) {
      await addGeofence(alarm);
    }
  }

  void onGeofenceEvent(void Function(String alarmId) onEntry) {
    background_geolocation.BackgroundGeolocation.onGeofence((event) {
      if (event.action == 'ENTER') {
        onEntry(event.identifier);
      }
    });
  }
}
