import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/app_constants.dart';
import '../config/app_theme.dart';
import '../models/alarm.dart';
import '../providers/alarm_provider.dart';
import '../services/location_service.dart';
import '../utils/distance_calculator.dart' as distance_utils;
import '../widgets/baroque_divider.dart';
import '../widgets/gold_button.dart';
import '../widgets/radius_slider.dart';

class AddAlarmScreen extends ConsumerStatefulWidget {
  const AddAlarmScreen({super.key});

  @override
  ConsumerState<AddAlarmScreen> createState() => _AddAlarmScreenState();
}

class _AddAlarmScreenState extends ConsumerState<AddAlarmScreen> {
  final MapController _mapController = MapController();
  LatLng _selectedLocation = const LatLng(40.7128, -74.0060);
  String _alarmName = '';
  double _radius = defaultRadiusMeters;
  String _selectedSound = 'assets/sounds/default_alarm.mp3';
  bool _vibrate = true;
  String? _address;
  String? _validationError;
  bool _isSaving = false;

  static const _soundOptions = <String, String>{
    'Default Bell': 'assets/sounds/default_alarm.mp3',
    'Royal Fanfare': 'assets/sounds/royal_fanfare.mp3',
    'Gentle Chime': 'assets/sounds/gentle_chime.mp3',
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    final position = await LocationService().getCurrentPosition();
    if (!mounted || position == null) return;
    final location = LatLng(position.latitude, position.longitude);
    setState(() => _selectedLocation = location);
    await _reverseGeocode(location);
    try {
      _mapController.move(location, 14);
    } on Exception {
      // The map may not be mounted yet; the selected location remains valid.
    }
  }

  Future<void> _reverseGeocode(LatLng location) async {
    try {
      final marks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (!mounted || marks.isEmpty) return;
      final mark = marks.first;
      final parts = [
        mark.name,
        mark.street,
        mark.locality,
        mark.administrativeArea,
      ].where((part) => part != null && part.trim().isNotEmpty).toSet();
      setState(() => _address = parts.join(', '));
    } on Exception {
      if (mounted) setState(() => _address = null);
    }
  }

  Future<void> _saveAlarm() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final generatedName = _address == null || _address!.trim().isEmpty
        ? 'Alarm at ${_selectedLocation.latitude.toStringAsFixed(5)}, '
              '${_selectedLocation.longitude.toStringAsFixed(5)}'
        : 'Alarm at $_address';
    setState(() {
      _validationError = null;
      _isSaving = true;
    });
    final alarm = Alarm(
      id: const Uuid().v4(),
      name: _alarmName.trim().isEmpty ? generatedName : _alarmName.trim(),
      address:
          _address ??
          'Unknown location (${_selectedLocation.latitude.toStringAsFixed(5)}, '
              '${_selectedLocation.longitude.toStringAsFixed(5)})',
      targetLat: _selectedLocation.latitude,
      targetLng: _selectedLocation.longitude,
      radiusInMeters: _radius,
      soundAsset: _selectedSound,
      vibrate: _vibrate,
      createdAt: DateTime.now(),
    );
    try {
      final alarms = ref.read(alarmProvider).valueOrNull ?? const <Alarm>[];
      final duplicate = alarms.any(
        (existing) =>
            existing.isMonitoring &&
            distance_utils.DistanceCalculator.calculateDistanceMeters(
                  existing.targetLat,
                  existing.targetLng,
                  alarm.targetLat,
                  alarm.targetLng,
                ) <=
                50,
      );
      if (duplicate && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: surfaceElevated,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: gold),
              borderRadius: BorderRadius.circular(10),
            ),
            title: const Text('Nearby Alarm'),
            content: const Text(
              'You already have an alarm near this location. Create anyway?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Create Anyway'),
              ),
            ],
          ),
        );
        if (proceed != true) {
          if (mounted) setState(() => _isSaving = false);
          return;
        }
      }
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final box = Hive.box<dynamic>(hiveBoxName);
        final askedAboutOptimization =
            box.get('batteryOptimizationAsked', defaultValue: false) == true;
        final optimization = await Permission.ignoreBatteryOptimizations.status;
        if (!mounted) return;
        if (!askedAboutOptimization && !optimization.isGranted) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: surfaceElevated,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: gold),
                borderRadius: BorderRadius.circular(10),
              ),
              title: const Text('⚜ Battery Optimization ⚜'),
              content: const Text(
                'Android may stop monitoring your alarms to save battery. '
                'Disable battery optimization for vortex for reliable alerts.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Skip'),
                ),
                FilledButton(
                  onPressed: () async {
                    await Permission.ignoreBatteryOptimizations.request();
                    if (context.mounted) Navigator.pop(context, true);
                  },
                  child: const Text('Disable'),
                ),
              ],
            ),
          );
          await box.put('batteryOptimizationAsked', true);
          if (proceed != true) {
            if (mounted) setState(() => _isSaving = false);
            return;
          }
        }
      }
      await ref.read(alarmProvider.notifier).addAlarm(alarm);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alarm set successfully ⚜'),
          backgroundColor: surfaceElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } on Exception {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The alarm could not be set. Please try again.'),
          backgroundColor: burgundy,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: backgroundDark,
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: gold),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('⚜ New Alarm ⚜'),
    ),
    body: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: (MediaQuery.sizeOf(context).height * .38).clamp(
              260.0,
              420.0,
            ),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation,
                    initialZoom: 14,
                    onTap: (_, location) {
                      setState(() => _selectedLocation = location);
                      _reverseGeocode(location);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.arrival_bell',
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _selectedLocation,
                          radius: _radius,
                          useRadiusInMeter: true,
                          color: gold.withValues(alpha: .15),
                          borderColor: gold,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation,
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.location_on,
                            color: gold,
                            size: 42,
                          ),
                        ),
                      ],
                    ),
                    RichAttributionWidget(
                      alignment: AttributionAlignment.bottomRight,
                      attributions: [
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          prependCopyright: false,
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _MapHint(text: 'Tap map to set location'),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: _MapHint(
                    text:
                        '${_selectedLocation.latitude.toStringAsFixed(5)}, ${_selectedLocation.longitude.toStringAsFixed(5)}',
                    mono: true,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: BaroqueDivider(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Alarm Details',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(color: gold),
                ),
                const SizedBox(height: 16),
                TextField(
                  style: GoogleFonts.cormorantGaramond(
                    color: ivory,
                    fontSize: 16,
                  ),
                  onChanged: (value) => _alarmName = value,
                  decoration: const InputDecoration(
                    labelText: 'Destination Name',
                    prefixIcon: Icon(Icons.castle, color: gold),
                  ),
                ),
                if (_validationError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _validationError!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: burgundy),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  _address == null
                      ? 'Unknown location (${_selectedLocation.latitude.toStringAsFixed(5)}, ${_selectedLocation.longitude.toStringAsFixed(5)})'
                      : '📍 $_address',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: ivoryMuted),
                ),
                const SizedBox(height: 16),
                RadiusSlider(
                  value: _radius,
                  onChanged: (value) => setState(() => _radius = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSound,
                  dropdownColor: surfaceElevated,
                  iconEnabledColor: gold,
                  style: GoogleFonts.cormorantGaramond(
                    color: ivory,
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Arrival Sound',
                    prefixIcon: Icon(Icons.music_note, color: gold),
                  ),
                  items: _soundOptions.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.value,
                          child: Text(entry.key),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedSound = value);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Vibrate on Arrival',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Switch(
                      value: _vibrate,
                      onChanged: (value) => setState(() => _vibrate = value),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: GoldButton(
                    label: '⚜ Set Alarm ⚜',
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _saveAlarm,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _MapHint extends StatelessWidget {
  const _MapHint({required this.text, this.mono = false});
  final String text;
  final bool mono;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: backgroundDark.withValues(alpha: .82),
      border: Border.all(color: goldDark),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Text(
        text,
        style: mono
            ? GoogleFonts.jetBrainsMono(fontSize: 11, color: ivory)
            : Theme.of(context).textTheme.bodySmall?.copyWith(color: ivory),
      ),
    ),
  );
}
