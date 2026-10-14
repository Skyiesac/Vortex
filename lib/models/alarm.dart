import 'alarm_status.dart';

class Alarm {
  const Alarm({
    required this.id,
    required this.targetLat,
    required this.targetLng,
    required this.radiusInMeters,
    this.name = '',
    this.address = '',
    this.isActive = true,
    this.alarmStatus = AlarmStatus.active,
    this.triggeredAt,
    this.soundAsset = 'assets/sounds/default_alarm.mp3',
    this.vibrate = true,
    this.createdAt,
  });

  final String id;
  final double targetLat;
  final double targetLng;
  final double radiusInMeters;
  final String name;
  final String address;
  final bool isActive;
  final AlarmStatus alarmStatus;
  final DateTime? triggeredAt;
  final String soundAsset;
  final bool vibrate;
  final DateTime? createdAt;

  bool get isMonitoring => isActive && alarmStatus == AlarmStatus.active;

  Alarm copyWith({
    String? name,
    String? address,
    double? targetLat,
    double? targetLng,
    double? radiusInMeters,
    bool? isActive,
    AlarmStatus? alarmStatus,
    DateTime? triggeredAt,
    bool clearTriggeredAt = false,
    String? soundAsset,
    bool? vibrate,
    DateTime? createdAt,
  }) {
    return Alarm(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      targetLat: targetLat ?? this.targetLat,
      targetLng: targetLng ?? this.targetLng,
      radiusInMeters: radiusInMeters ?? this.radiusInMeters,
      isActive: isActive ?? this.isActive,
      alarmStatus: alarmStatus ?? this.alarmStatus,
      triggeredAt: clearTriggeredAt ? null : (triggeredAt ?? this.triggeredAt),
      soundAsset: soundAsset ?? this.soundAsset,
      vibrate: vibrate ?? this.vibrate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'address': address,
    'targetLat': targetLat,
    'targetLng': targetLng,
    'radiusInMeters': radiusInMeters,
    'isActive': isActive,
    'alarmStatus': alarmStatus.index,
    'triggeredAt': triggeredAt?.toIso8601String(),
    'soundAsset': soundAsset,
    'vibrate': vibrate,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory Alarm.fromMap(Map<dynamic, dynamic> map) => Alarm(
    id: map['id'] as String,
    name: (map['name'] as String?) ?? '',
    address: (map['address'] as String?) ?? '',
    targetLat: (map['targetLat'] as num).toDouble(),
    targetLng: (map['targetLng'] as num).toDouble(),
    radiusInMeters: (map['radiusInMeters'] as num).toDouble(),
    isActive: (map['isActive'] as bool?) ?? true,
    alarmStatus: AlarmStatus.values[(map['alarmStatus'] as int?) ?? 0],
    triggeredAt: map['triggeredAt'] == null
        ? null
        : DateTime.parse(map['triggeredAt'] as String),
    soundAsset:
        (map['soundAsset'] as String?) ?? 'assets/sounds/default_alarm.mp3',
    vibrate: (map['vibrate'] as bool?) ?? true,
    createdAt: map['createdAt'] == null
        ? null
        : DateTime.parse(map['createdAt'] as String),
  );
}
