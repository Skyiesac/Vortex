import 'package:hive/hive.dart';

import '../config/app_constants.dart';
import '../models/alarm.dart';

class StorageService {
  Future<void> init() async {
    if (!Hive.isBoxOpen(hiveBoxName)) {
      await Hive.openBox<dynamic>(hiveBoxName);
    }
  }

  Box<dynamic> get _box => Hive.box<dynamic>(hiveBoxName);

  Future<List<Alarm>> getAllAlarms() async {
    return _box.values
        .whereType<Map>()
        .map(Alarm.fromMap)
        .toList(growable: false);
  }

  Future<void> saveAlarm(Alarm alarm) => _box.put(alarm.id, alarm.toMap());

  Future<void> deleteAlarm(String id) => _box.delete(id);

  Future<List<Alarm>> getActiveAlarms() async {
    final alarms = await getAllAlarms();
    return alarms.where((alarm) => alarm.isMonitoring).toList();
  }

  Future<Alarm?> getAlarmById(String id) async {
    final value = _box.get(id);
    if (value is Map) return Alarm.fromMap(value);
    return null;
  }

  Future<void> updateAlarm(Alarm alarm) => saveAlarm(alarm);
}
