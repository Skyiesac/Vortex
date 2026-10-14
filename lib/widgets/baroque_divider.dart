import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class BaroqueDivider extends StatelessWidget {
  const BaroqueDivider({super.key});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider(color: goldDark, thickness: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          '✦ ─────── ⚜ ─────── ✦',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: gold),
        ),
      ),
      const Expanded(child: Divider(color: goldDark, thickness: 1)),
    ],
  );
}
