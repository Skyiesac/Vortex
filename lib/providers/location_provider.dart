import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

import '../services/location_service.dart';
import '../utils/permission_helper.dart';

class LocationNotifier extends StateNotifier<AsyncValue<Position?>> {
  LocationNotifier(this._locationService) : super(const AsyncValue.loading());

  final LocationService _locationService;

  Future<void> fetchCurrentLocation() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _locationService.getCurrentPosition());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<bool> checkAndRequestPermissions() async {
    final status = await PermissionHelper.requestAllPermissions();
    return status == permissions.PermissionStatus.granted ||
        status == permissions.PermissionStatus.limited;
  }
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, AsyncValue<Position?>>((ref) {
      return LocationNotifier(LocationService());
    });
