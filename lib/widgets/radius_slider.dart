import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_constants.dart';
import '../config/app_theme.dart';

class RadiusSlider extends StatelessWidget {
  const RadiusSlider({super.key, required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Alert Radius', style: Theme.of(context).textTheme.bodyLarge),
          Text(
            '${value.toInt()}m',
            style: GoogleFonts.jetBrainsMono(fontSize: 13, color: gold),
          ),
        ],
      ),
      Slider(
        value: value,
        min: minRadiusMeters,
        max: maxRadiusMeters,
        divisions: 39,
        activeColor: gold,
        inactiveColor: surfaceElevated,
        thumbColor: goldLight,
        onChanged: onChanged,
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('50m', style: Theme.of(context).textTheme.bodySmall),
          Text('2km', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ],
  );
}
