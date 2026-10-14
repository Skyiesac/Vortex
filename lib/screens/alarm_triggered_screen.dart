import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class AlarmTriggeredScreen extends StatefulWidget {
  const AlarmTriggeredScreen({super.key});

  @override
  State<AlarmTriggeredScreen> createState() => _AlarmTriggeredScreenState();
}

class _AlarmTriggeredScreenState extends State<AlarmTriggeredScreen> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    Vibration.vibrate(pattern: [0, 1000, 500, 1000], repeat: 0);
  }

  @override
  void dispose() {
    Vibration.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bell Ringing')),
    body: const Center(child: Text('Arrival notification will be shown here.')),
  );
}
