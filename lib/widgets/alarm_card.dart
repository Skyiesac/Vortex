import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_theme.dart';
import '../models/alarm.dart';
import '../models/alarm_status.dart';
import '../providers/alarm_provider.dart';
import 'alarm_toggle.dart';

class AlarmCard extends ConsumerWidget {
  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onTap,
    this.first = false,
    this.last = false,
  });
  final Alarm alarm;
  final VoidCallback onTap;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context, WidgetRef ref) => GestureDetector(
    onTap: onTap,
    onLongPress: () => _confirmDelete(context, ref),
    child: Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2DDCF))),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 25,
              child: CustomPaint(
                painter: _StopLinePainter(first: first, last: last),
                child: Center(
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: alarm.isMonitoring ? gold : backgroundDark,
                      border: Border.all(
                        color: alarm.isMonitoring ? gold : ivoryMuted,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alarm.name.isEmpty ? 'Unnamed destination' : alarm.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                        letterSpacing: -.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      alarm.address.isEmpty
                          ? 'Address not specified'
                          : alarm.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_active_outlined,
                          size: 13,
                          color: gold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${alarm.radiusInMeters.toInt()}m heads-up zone',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusIndicator(
                  status: alarm.alarmStatus,
                  isActive: alarm.isMonitoring,
                ),
                const SizedBox(height: 5),
                AlarmToggle(alarm: alarm),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    HapticFeedback.heavyImpact();
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: gold, width: 1.2),
        ),
        title: Text(
          'Remove this bell?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'This destination and its arrival reminder will be removed.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Keep',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: gold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: burgundy,
              foregroundColor: ivory,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete == true && context.mounted) {
      await ref.read(alarmProvider.notifier).deleteAlarm(alarm.id);
    }
  }
}

class _StopLinePainter extends CustomPainter {
  const _StopLinePainter({required this.first, required this.last});
  final bool first;
  final bool last;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB6C4DF)
      ..strokeWidth = 2;
    final center = size.width / 2;
    if (!first)
      canvas.drawLine(
        Offset(center, 0),
        Offset(center, size.height / 2),
        paint,
      );
    if (!last)
      canvas.drawLine(
        Offset(center, size.height / 2),
        Offset(center, size.height),
        paint,
      );
  }

  @override
  bool shouldRepaint(covariant _StopLinePainter oldDelegate) =>
      first != oldDelegate.first || last != oldDelegate.last;
}

class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({required this.status, required this.isActive});
  final AlarmStatus status;
  final bool isActive;
  @override
  Widget build(BuildContext context) {
    final triggered = status == AlarmStatus.triggered;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          triggered ? Icons.star : Icons.circle,
          size: triggered ? 16 : 10,
          color: triggered ? gold : (isActive ? emerald : ivoryMuted),
        ),
        const SizedBox(width: 4),
        Text(
          triggered ? 'Arrived' : (isActive ? 'Active' : 'Paused'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: triggered ? gold : (isActive ? emerald : ivoryMuted),
          ),
        ),
      ],
    );
  }
}
