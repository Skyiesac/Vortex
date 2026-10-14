import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

import '../config/app_constants.dart';
import '../models/alarm.dart';
import '../models/alarm_status.dart';
import '../services/audio_service.dart';
import '../services/geofence_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final geofenceServiceProvider = Provider<GeofenceService>((ref) {
  return GeofenceService();
});

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class AlarmNotifier extends StateNotifier<AsyncValue<List<Alarm>>> {
  AlarmNotifier(this._storage, this._geofence, this._audio, this._notifications)
    : super(const AsyncValue.loading()) {
    unawaited(loadAlarms());
  }

  final StorageService _storage;
  final GeofenceService _geofence;
  final AudioService _audio;
  final NotificationService _notifications;

  Future<void> loadAlarms() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _storage.getAllAlarms());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addAlarm(Alarm alarm) async {
    await _storage.saveAlarm(alarm);
    if (alarm.isMonitoring) await _geofence.addGeofence(alarm);
    await loadAlarms();
  }

  Future<void> updateAlarm(Alarm alarm) async {
    final existing = _findAlarm(alarm.id);
    if (existing != null && existing.isMonitoring && !alarm.isMonitoring) {
      await _geofence.removeGeofence(alarm.id);
    } else if (alarm.isMonitoring) {
      await _geofence.addGeofence(alarm);
    }
    await _storage.saveAlarm(alarm);
    await loadAlarms();
  }

  Future<void> deleteAlarm(String id) async {
    await _geofence.removeGeofence(id);
    await _storage.deleteAlarm(id);
    await loadAlarms();
  }

  Future<void> toggleAlarm(String id, bool isActive) async {
    final alarm = _findAlarm(id);
    if (alarm == null) return;
    final updated = alarm.copyWith(isActive: isActive);
    if (updated.isMonitoring) {
      await _geofence.addGeofence(updated);
    } else {
      await _geofence.removeGeofence(id);
    }
    await _storage.saveAlarm(updated);
    await loadAlarms();
  }

  Future<void> markTriggered(String id) async {
    final alarm = _findAlarm(id);
    if (alarm == null) return;
    final updated = alarm.copyWith(
      alarmStatus: AlarmStatus.triggered,
      triggeredAt: DateTime.now(),
      isActive: false,
    );
    await _geofence.removeGeofence(id);
    await _storage.saveAlarm(updated);
    await loadAlarms();
  }

  Future<void> reRegisterGeofences() async {
    final alarms = await _storage.getAllAlarms();
    await _geofence.reRegisterAllGeofences(
      alarms.where((alarm) => alarm.isMonitoring).toList(),
    );
  }

  Future<void> handleGeofenceEntry(String alarmId) async {
    final alarm = _findAlarm(alarmId);
    if (alarm == null || !alarm.isMonitoring) return;
    if (alarm.triggeredAt != null &&
        DateTime.now().difference(alarm.triggeredAt!).inMinutes <
            alarmCooldownMinutes) {
      return;
    }
    await markTriggered(alarmId);
    await _audio.initialize();
    await _notifications.initialize();
    await _audio.playAlarmSound(alarm.soundAsset);
    if (_audio.consumeFallbackWarning()) {
      await _notifications.showSoundFallbackWarning();
    }
    await _notifications.showAlarmTriggeredNotification(
      alarmId: alarm.id,
      alarmName: alarm.name,
      address: alarm.address,
    );
    if (alarm.vibrate && await Vibration.hasVibrator()) {
      await Vibration.vibrate(pattern: [0, 1000, 500, 1000]);
    }
  }

  Alarm? _findAlarm(String id) {
    final alarms = state.valueOrNull;
    if (alarms == null) return null;
    for (final alarm in alarms) {
      if (alarm.id == id) return alarm;
    }
    return null;
  }
}

final alarmProvider =
    StateNotifierProvider<AlarmNotifier, AsyncValue<List<Alarm>>>((ref) {
      return AlarmNotifier(
        ref.watch(storageServiceProvider),
        ref.watch(geofenceServiceProvider),
        ref.watch(audioServiceProvider),
        ref.watch(notificationServiceProvider),
      );
    });

final activeAlarmsProvider = Provider<List<Alarm>>((ref) {
  final alarms = ref.watch(alarmProvider);
  return alarms.maybeWhen(
    data: (list) => list.where((alarm) => alarm.isMonitoring).toList(),
    orElse: () => [],
  );
});

final triggeredAlarmsProvider = Provider<List<Alarm>>((ref) {
  final alarms = ref.watch(alarmProvider);
  return alarms.maybeWhen(
    data: (list) => list
        .where((alarm) => alarm.alarmStatus == AlarmStatus.triggered)
        .toList(),
    orElse: () => [],
  );
});
