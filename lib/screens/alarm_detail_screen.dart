import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../config/app_theme.dart';
import '../models/alarm.dart';
import '../models/alarm_status.dart';
import '../providers/alarm_provider.dart';
import '../widgets/baroque_divider.dart';
import '../widgets/gold_button.dart';
import '../widgets/ornate_card.dart';

class AlarmDetailScreen extends ConsumerWidget {
  const AlarmDetailScreen({super.key, required this.alarmId});
  final String alarmId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(alarmProvider);
    return state.when(
      loading: () => const _DetailScaffold(
        title: 'Alarm Details',
        body: Center(
          child: Text('⚜', style: TextStyle(color: gold, fontSize: 42)),
        ),
      ),
      error: (_, _) => _DetailScaffold(
        title: 'Alarm Details',
        body: const Center(
          child: Text('Unable to load this alarm. Please try again.'),
        ),
      ),
      data: (alarms) {
        Alarm? alarm;
        for (final item in alarms) {
          if (item.id == alarmId) alarm = item;
        }
        if (alarm == null) {
          return const _DetailScaffold(
            title: 'Alarm Details',
            body: Center(child: Text('This alarm no longer exists.')),
          );
        }
        return _AlarmDetailBody(alarm: alarm);
      },
    );
  }
}

class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({required this.title, required this.body});
  final String title;
  final Widget body;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: backgroundDark,
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: gold),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(title),
    ),
    body: body,
  );
}

class _AlarmDetailBody extends ConsumerWidget {
  const _AlarmDetailBody({required this.alarm});
  final Alarm alarm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final triggered = alarm.alarmStatus == AlarmStatus.triggered;
    final statusColor = alarm.isMonitoring
        ? emerald
        : triggered
        ? gold
        : ivoryMuted;
    return Scaffold(
      backgroundColor: backgroundDark,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: gold),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(alarm.name.isEmpty ? 'Alarm Details' : alarm.name),
        actions: [
          IconButton(
            tooltip: 'Delete alarm',
            icon: const Icon(Icons.delete_outline, color: burgundy),
            onPressed: () => _deleteAlarm(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: (MediaQuery.sizeOf(context).height * .35)
                  .clamp(220.0, 360.0)
                  .toDouble(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(alarm.targetLat, alarm.targetLng),
                    initialZoom: 14,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
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
                          point: LatLng(alarm.targetLat, alarm.targetLng),
                          radius: alarm.radiusInMeters,
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
                          point: LatLng(alarm.targetLat, alarm.targetLng),
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
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: BaroqueDivider(),
            ),
            OrnateCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '⚜ Alarm Details ⚜',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: gold),
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(
                    icon: Icons.location_on,
                    label: 'Location',
                    value: alarm.address.isEmpty
                        ? '${alarm.targetLat}, ${alarm.targetLng}'
                        : alarm.address,
                  ),
                  _InfoRow(
                    icon: Icons.radar,
                    label: 'Radius',
                    value: '${alarm.radiusInMeters.toInt()}m',
                  ),
                  _InfoRow(
                    icon: Icons.music_note,
                    label: 'Sound',
                    value: _soundName(alarm.soundAsset),
                  ),
                  _InfoRow(
                    icon: Icons.vibration,
                    label: 'Vibrate',
                    value: alarm.vibrate ? 'Yes' : 'No',
                  ),
                  _InfoRow(
                    icon: Icons.calendar_today,
                    label: 'Created',
                    value: _formatDate(alarm.createdAt),
                  ),
                  _InfoRow(
                    icon: Icons.timelapse,
                    label: 'Status',
                    value: _statusName(alarm),
                    valueColor: statusColor,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: BaroqueDivider(),
            ),
            if (triggered) ...[
              Text(
                '✓ You arrived here',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: emerald),
              ),
              const SizedBox(height: 6),
              Text(
                'Triggered ${_formatDate(alarm.triggeredAt)}',
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: ivoryMuted,
                ),
              ),
              const SizedBox(height: 16),
              GoldButton(
                label: 'Reset Alarm',
                icon: Icons.restart_alt,
                onPressed: () => ref
                    .read(alarmProvider.notifier)
                    .updateAlarm(
                      alarm.copyWith(
                        alarmStatus: AlarmStatus.active,
                        isActive: true,
                        clearTriggeredAt: true,
                      ),
                    ),
              ),
            ] else ...[
              _ActionButton(
                label: alarm.isMonitoring ? 'Disable Alarm' : 'Re-enable Alarm',
                outlined: alarm.isMonitoring,
                onPressed: () => ref
                    .read(alarmProvider.notifier)
                    .toggleAlarm(alarm.id, !alarm.isActive),
              ),
            ],
            const SizedBox(height: 16),
            _ActionButton(
              label: '🗑 Delete This Alarm',
              backgroundColor: burgundy,
              foregroundColor: ivory,
              onPressed: () => _deleteAlarm(context, ref),
            ),
            if (triggered) ...[
              const SizedBox(height: 22),
              Text(
                'You were within ${alarm.radiusInMeters.toInt()}m of this location',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: ivoryMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAlarm(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: gold, width: 1.2),
        ),
        title: Text(
          'Delete this alarm?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Are you sure? This cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          _DialogButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          _DialogButton(
            label: 'Delete',
            filled: true,
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(alarmProvider.notifier).deleteAlarm(alarm.id);
    if (context.mounted) Navigator.pop(context);
  }

  String _soundName(String asset) {
    if (asset.contains('royal')) return 'Royal Fanfare';
    if (asset.contains('gentle')) return 'Gentle Chime';
    return 'Default Bell';
  }

  String _formatDate(DateTime? value) => value == null
      ? 'Not recorded'
      : DateFormat.yMMMd().add_jm().format(value);

  String _statusName(Alarm alarm) {
    if (alarm.alarmStatus == AlarmStatus.triggered) return 'Triggered';
    return alarm.isActive ? 'Active' : 'Disabled';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: gold),
        const SizedBox(width: 10),
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: ivoryMuted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: valueColor ?? ivory),
          ),
        ),
      ],
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.outlined = false,
    this.backgroundColor,
    this.foregroundColor,
  });
  final String label;
  final VoidCallback onPressed;
  final bool outlined;
  final Color? backgroundColor;
  final Color? foregroundColor;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: outlined
            ? Colors.transparent
            : (backgroundColor ?? gold),
        foregroundColor: outlined ? gold : (foregroundColor ?? backgroundDark),
        elevation: outlined ? 0 : 8,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: outlined ? gold : Colors.transparent,
            width: 1.2,
          ),
        ),
      ),
      child: Text(label),
    ),
  );
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
  });
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      backgroundColor: filled ? burgundy : Colors.transparent,
      foregroundColor: filled ? ivory : gold,
      side: BorderSide(color: filled ? burgundy : gold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    child: Text(label),
  );
}
