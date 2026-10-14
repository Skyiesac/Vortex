import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  Future<void> showAlarmTriggeredNotification({
    required String alarmId,
    required String alarmName,
    required String address,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'arrival_alarm',
      'Arrival Alarms',
      channelDescription: 'Notifications when you reach your destination',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );
    await _plugin.show(
      _notificationId(alarmId),
      '⚜ You Have Arrived ⚜',
      '$alarmName — $address',
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: alarmId,
    );
  }

  Future<void> showSoundFallbackWarning() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'arrival_warnings',
        'vortex Warnings',
        channelDescription: 'Important vortex warnings',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      2147483000,
      'vortex',
      'The selected sound was unavailable. The default bell was used.',
      details,
    );
  }

  Future<void> cancelNotification(String alarmId) =>
      _plugin.cancel(_notificationId(alarmId));

  Future<void> cancelAllNotifications() => _plugin.cancelAll();

  int _notificationId(String alarmId) {
    var hash = 0;
    for (final codeUnit in alarmId.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash;
  }
}
