import 'dart:async';

import 'package:geolocator/geolocator.dart' as geo;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

import '../config/app_constants.dart';
import '../config/app_theme.dart';
import '../models/alarm.dart';
import '../providers/alarm_provider.dart';
import '../services/location_service.dart';
import '../utils/permission_helper.dart';
import '../widgets/alarm_card.dart';
import '../widgets/gold_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final _locationService = LocationService();
  StreamSubscription<geo.ServiceStatus>? _locationSubscription;
  bool _gpsDisabled = false;
  bool _permissionWarning = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshLocationState();
    if (!kIsWeb) {
      _locationSubscription = _locationService.serviceStatusStream.listen((
        status,
      ) {
        if (mounted) {
          setState(() => _gpsDisabled = status == geo.ServiceStatus.disabled);
        }
      });
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _requestOnFirstLaunch(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(alarmProvider.notifier).loadAlarms();
      _refreshLocationState(showPermissionDialog: true);
      if (!kIsWeb) {
        ref.read(alarmProvider.notifier).reRegisterGeofences();
      }
    }

    if (state == AppLifecycleState.paused && !kIsWeb) {
      ref.read(alarmProvider.notifier).reRegisterGeofences();
    }
  }

  Future<void> _refreshLocationState({
    bool showPermissionDialog = false,
  }) async {
    try {
      final gpsEnabled = await _locationService.isLocationEnabled();
      final permissionGranted = await _locationService.hasLocationPermission();
      if (!mounted) return;
      setState(() {
        _gpsDisabled = !gpsEnabled;
        _permissionWarning = !permissionGranted;
      });
      if (showPermissionDialog && !permissionGranted) {
        await _showPermissionRevokedDialog();
      }
    } on Exception {
      if (mounted) setState(() => _gpsDisabled = true);
    }
  }

  Future<void> _showPermissionRevokedDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceElevated,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: gold),
          borderRadius: BorderRadius.circular(10),
        ),
        title: const Text('⚜ Location Access Required ⚜'),
        content: const Text(
          'Your alarms cannot monitor your location without permission.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _permissionWarning = true);
              Navigator.pop(context);
            },
            child: const Text('Dismiss'),
          ),
          FilledButton(
            onPressed: () async {
              await PermissionHelper.openAppSettings();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Grant Access'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestOnFirstLaunch() async {
    if (!mounted || kIsWeb) return;
    final box = Hive.box<dynamic>(hiveBoxName);
    if (box.get('permissionsExplained', defaultValue: false) == true) return;
    await box.put('permissionsExplained', true);
    if (!mounted) return;
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceElevated,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: gold),
          borderRadius: BorderRadius.circular(10),
        ),
        title: const Text('⚜ Permission Required ⚜'),
        content: const Text(
          'vortex needs continuous location access to monitor your '
          'destinations and alert you upon arrival, even when the app is closed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Grant Access'),
          ),
        ],
      ),
    );
    if (shouldRequest != true || !mounted) return;
    final status = await PermissionHelper.requestAllPermissions();
    if (!mounted || !status.isPermanentlyDenied) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceElevated,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: gold),
          borderRadius: BorderRadius.circular(10),
        ),
        title: const Text('Permissions Needed'),
        content: const Text(
          'Location access is permanently denied. Open settings to enable '
          'background monitoring for vortex.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () async {
              await PermissionHelper.openAppSettings();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final alarms = ref.watch(alarmProvider);
    return Scaffold(
      backgroundColor: backgroundDark,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(
              Icons.notifications_active_outlined,
              color: gold,
              size: 21,
            ),
            const SizedBox(width: 9),
            const Text('vortex'),
            const Spacer(),
            const Icon(Icons.more_horiz_rounded, color: ivoryMuted),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_gpsDisabled || _permissionWarning)
            _LocationWarningBanner(
              permissionWarning: _permissionWarning,
              onEnable: () async {
                if (_gpsDisabled) {
                  await _locationService.openLocationSettings();
                } else {
                  await PermissionHelper.openAppSettings();
                }
              },
            ),
          Expanded(
            child: alarms.when(
              loading: () => const Center(child: _GoldLoader()),
              error: (error, _) => _ErrorState(
                onRetry: () => ref.read(alarmProvider.notifier).loadAlarms(),
              ),
              data: (items) => _AlarmList(alarms: items),
            ),
          ),
        ],
      ),
      floatingActionButton: _AddAlarmFab(
        onPressed: () => Navigator.pushNamed(context, '/add-alarm'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _AlarmList extends StatelessWidget {
  const _AlarmList({required this.alarms});
  final List<Alarm> alarms;

  @override
  Widget build(BuildContext context) {
    if (alarms.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 100),
        children: const [
          _JourneyHeader(),
          _SectionHeader(title: 'YOUR ROUTE'),
          _EmptyState(),
        ],
      );
    }
    final active = alarms.where((alarm) => alarm.isMonitoring).toList();
    final triggered = alarms
        .where((alarm) => alarm.alarmStatus.name == 'triggered')
        .toList();
    final disabled = alarms
        .where(
          (alarm) =>
              !alarm.isMonitoring && alarm.alarmStatus.name != 'triggered',
        )
        .toList();
    final sections = <Widget>[
      const _JourneyHeader(),
      _SectionHeader(title: 'MONITORING', count: active.length),
      ...active.asMap().entries.map(
        (entry) => _CardPadding(
          alarm: entry.value,
          first: entry.key == 0,
          last: entry.key == active.length - 1,
        ),
      ),
    ];
    sections.addAll([
      const SizedBox(height: 28),
      const _SectionHeader(title: 'JUST LANDED'),
      if (triggered.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Text('Arrivals will appear here.'),
        )
      else
        ...triggered.asMap().entries.map(
          (entry) => _CardPadding(
            alarm: entry.value,
            dimmed: true,
            first: entry.key == 0,
            last: entry.key == triggered.length - 1,
          ),
        ),
    ]);
    if (disabled.isNotEmpty) {
      sections.addAll([
        const SizedBox(height: 28),
        const _SectionHeader(title: 'ON PAUSE'),
        ...disabled.asMap().entries.map(
          (entry) => _CardPadding(
            alarm: entry.value,
            dimmed: true,
            first: entry.key == 0,
            last: entry.key == disabled.length - 1,
          ),
        ),
      ]);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 100),
      children: sections,
    );
  }
}

class _CardPadding extends StatelessWidget {
  const _CardPadding({
    required this.alarm,
    this.dimmed = false,
    this.first = false,
    this.last = false,
  });
  final Alarm alarm;
  final bool dimmed;
  final bool first;
  final bool last;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 0),
    child: Opacity(
      opacity: dimmed ? .62 : 1,
      child: AlarmCard(
        alarm: alarm,
        first: first,
        last: last,
        onTap: () =>
            Navigator.pushNamed(context, '/alarm-detail', arguments: alarm.id),
      ),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.count});
  final String title;
  final int? count;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 2),
    child: Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: ivoryMuted,
            letterSpacing: 1.8,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: surfaceElevated,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: gold),
            ),
          ),
        ],
      ],
    ),
  );
}

class _JourneyHeader extends StatelessWidget {
  const _JourneyHeader();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 29, 0, 27),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your\nstops',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: 48,
            height: .94,
            letterSpacing: -2.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Set a place. We’ll let you know when you’re close.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: ivoryMuted),
        ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_location_alt_outlined, size: 32, color: gold),
          const SizedBox(height: 12),
          Text('No stops yet', style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: burgundy,
          border: Border.all(color: gold),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Unable to open your alarm book',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              GoldButton(
                label: 'Retry',
                icon: Icons.refresh,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LocationWarningBanner extends StatelessWidget {
  const _LocationWarningBanner({
    required this.permissionWarning,
    required this.onEnable,
  });
  final bool permissionWarning;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: burgundy,
    padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
    child: Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: gold),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            permissionWarning
                ? 'Location access is required. Alarms will not trigger.'
                : '⚠ Location services are disabled. Alarms will not trigger.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: ivory),
          ),
        ),
        TextButton(
          onPressed: onEnable,
          child: Text(permissionWarning ? 'Grant Access' : 'Enable GPS'),
        ),
      ],
    ),
  );
}

class _GoldLoader extends StatefulWidget {
  const _GoldLoader();
  @override
  State<_GoldLoader> createState() => _GoldLoaderState();
}

class _GoldLoaderState extends State<_GoldLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
    turns: _controller,
    child: const Text('⚜', style: TextStyle(color: gold, fontSize: 42)),
  );
}

class _AddAlarmFab extends StatelessWidget {
  const _AddAlarmFab({required this.onPressed});
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
    onPressed: onPressed,
    elevation: 4,
    backgroundColor: gold,
    foregroundColor: Colors.white,
    icon: const Icon(Icons.add_rounded),
    label: const Text('Add a stop'),
  );
}
