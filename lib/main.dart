import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as background_geolocation;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vibration/vibration.dart';
import 'config/app_theme.dart';
import 'config/app_constants.dart';
import 'models/alarm_status.dart';
import 'providers/alarm_provider.dart';
import 'screens/add_alarm_screen.dart';
import 'screens/alarm_detail_screen.dart';
import 'screens/alarm_triggered_screen.dart';
import 'screens/home_screen.dart';
import 'screens/launch_screen.dart';
import 'services/audio_service.dart';
import 'services/geofence_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final storageService = StorageService();
  await storageService.init();

  GeofenceService? geofenceService;
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    geofenceService = GeofenceService();
    await geofenceService.initialize();
    final notificationService = NotificationService();
    await notificationService.initialize();
    final audioService = AudioService();
    await audioService.initialize();
    await geofenceService.reRegisterAllGeofences(
      await storageService.getActiveAlarms(),
    );
    geofenceService.onGeofenceEvent(
      (alarmId) => handleGeofenceEntry(
        alarmId,
        storageService,
        geofenceService!,
        notificationService,
        audioService,
      ),
    );
  }
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    background_geolocation.BackgroundGeolocation.registerHeadlessTask(
      backgroundGeolocationHeadlessTask,
    );
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: backgroundDark,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: backgroundDark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
        if (geofenceService != null)
          geofenceServiceProvider.overrideWithValue(geofenceService),
      ],
      child: const ArrivalBellApp(),
    ),
  );
}

Future<void> handleGeofenceEntry(
  String alarmId,
  StorageService storage,
  GeofenceService geofence,
  NotificationService notifications,
  AudioService audio,
) async {
  try {
    final alarm = await storage.getAlarmById(alarmId);
    if (alarm == null || !alarm.isMonitoring) return;
    final triggeredAt = alarm.triggeredAt;
    if (triggeredAt != null &&
        DateTime.now().difference(triggeredAt).inMinutes <
            alarmCooldownMinutes) {
      debugPrint('Skipped geofence trigger for $alarmId during cooldown.');
      return;
    }
    await audio.playAlarmSound(alarm.soundAsset);
    if (audio.consumeFallbackWarning()) {
      await notifications.showSoundFallbackWarning();
    }
    await notifications.showAlarmTriggeredNotification(
      alarmId: alarm.id,
      alarmName: alarm.name,
      address: alarm.address.isEmpty ? 'Your destination' : alarm.address,
    );
    if (alarm.vibrate && await Vibration.hasVibrator()) {
      await Vibration.vibrate(pattern: [0, 1000, 500, 1000]);
    }
    await storage.updateAlarm(
      alarm.copyWith(
        isActive: false,
        alarmStatus: AlarmStatus.triggered,
        triggeredAt: DateTime.now(),
      ),
    );
    await geofence.removeGeofence(alarm.id);
  } on Exception {
    debugPrint('vortex could not complete the arrival alert.');
  }
}

@pragma('vm:entry-point')
Future<void> backgroundGeolocationHeadlessTask(
  background_geolocation.HeadlessEvent headlessEvent,
) async {
  if (headlessEvent.name != background_geolocation.Event.GEOFENCE) return;
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final storage = StorageService();
  await storage.init();
  final geofence = GeofenceService();
  await geofence.initialize();
  final notifications = NotificationService();
  await notifications.initialize();
  final audio = AudioService();
  await audio.initialize();
  final event = headlessEvent.event as background_geolocation.GeofenceEvent;
  if (event.action == 'ENTER') {
    await handleGeofenceEntry(
      event.identifier,
      storage,
      geofence,
      notifications,
      audio,
    );
  }
}

class ArrivalBellApp extends StatelessWidget {
  const ArrivalBellApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'vortex',
    debugShowCheckedModeBanner: false,
    theme: baroqueTheme,
    initialRoute: '/launch',
    routes: {
      '/launch': (_) => const LaunchScreen(),
      '/': (_) => const HomeScreen(),
      '/add-alarm': (_) => const AddAlarmScreen(),
      '/alarm-detail': (context) => AlarmDetailScreen(
        alarmId: ModalRoute.of(context)?.settings.arguments as String? ?? '',
      ),
      '/alarm-triggered': (_) => const AlarmTriggeredScreen(),
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) =>
      const ProviderScope(child: ArrivalBellApp());
}
