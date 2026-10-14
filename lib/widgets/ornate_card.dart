import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class OrnateCard extends StatelessWidget {
  const OrnateCard({
    super.key,
    required this.child,
    this.showFlourishes = true,
  });
  final Widget child;
  final bool showFlourishes;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: surfaceDark,
      border: Border.all(color: gold, width: 1.2),
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .65),
          blurRadius: 28,
          spreadRadius: 3,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Stack(
      children: [
        Padding(padding: const EdgeInsets.all(18), child: child),
        if (showFlourishes) ...[
          const Positioned(
            top: 5,
            left: 8,
            child: Text('❧', style: TextStyle(color: gold, fontSize: 18)),
          ),
          const Positioned(
            bottom: 3,
            right: 8,
            child: Text('❧', style: TextStyle(color: gold, fontSize: 18)),
          ),
        ],
      ],
    ),
  );
}
