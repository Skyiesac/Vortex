import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_theme.dart';
import '../models/alarm.dart';
import '../providers/alarm_provider.dart';

class AlarmToggle extends ConsumerWidget {
  const AlarmToggle({super.key, required this.alarm});
  final Alarm alarm;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Switch(
    value: alarm.isActive,
    activeThumbColor: gold,
    activeTrackColor: burgundy,
    inactiveThumbColor: ivoryMuted,
    inactiveTrackColor: surfaceElevated,
    onChanged: alarm.alarmStatus.name == 'triggered'
        ? null
        : (isActive) {
            HapticFeedback.lightImpact();
            ref.read(alarmProvider.notifier).toggleAlarm(alarm.id, isActive);
          },
  );
}
