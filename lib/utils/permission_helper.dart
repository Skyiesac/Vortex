import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

class PermissionHelper {
  static Future<permissions.PermissionStatus> requestAllPermissions() async {
    final statuses = <permissions.PermissionStatus>[
      await permissions.Permission.locationWhenInUse.request(),
      await permissions.Permission.locationAlways.request(),
      await permissions.Permission.notification.request(),
    ];
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      statuses.add(
        await permissions.Permission.ignoreBatteryOptimizations.request(),
      );
    }
    return statuses.reduce(_worstStatus);
  }

  static Future<bool> isPermanentlyDenied(
    permissions.Permission permission,
  ) async => (await permission.status).isPermanentlyDenied;

  static Future<void> openAppSettings() async {
    await permissions.openAppSettings();
  }

  static permissions.PermissionStatus _worstStatus(
    permissions.PermissionStatus first,
    permissions.PermissionStatus second,
  ) {
    final firstRank = _statusRank(first);
    final secondRank = _statusRank(second);
    return firstRank >= secondRank ? first : second;
  }

  static int _statusRank(permissions.PermissionStatus status) {
    if (status.isPermanentlyDenied) return 6;
    if (status.isRestricted) return 5;
    if (status.isDenied) return 4;
    if (status.isLimited) return 3;
    if (status.isProvisional) return 2;
    if (status.isGranted) return 1;
    return 0;
  }
}
