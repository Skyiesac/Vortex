import 'package:flutter/material.dart';

import '../config/app_theme.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();
  late final AnimationController _ambientTrain = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);
  late final AnimationController _departure = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );
  bool _boarding = false;

  @override
  void dispose() {
    _intro.dispose();
    _ambientTrain.dispose();
    _departure.dispose();
    super.dispose();
  }

  Future<void> _boardTrain() async {
    if (_boarding) return;
    setState(() => _boarding = true);
    _ambientTrain.stop();
    await _departure.forward();
    if (mounted) Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF17243E),
    body: SafeArea(
      child: AnimatedBuilder(
        animation: Listenable.merge([_intro, _ambientTrain, _departure]),
        builder: (context, _) => Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final trainWidth = constraints.maxWidth * 1.28;
                  final trainLeft = _boarding
                      ? constraints.maxWidth * .55 -
                            Curves.easeInOutCubic.transform(_departure.value) *
                                (constraints.maxWidth + trainWidth)
                      : constraints.maxWidth * .55 + _ambientTrain.value * 22;
                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                          child: ClipRect(
                            child: Image.asset(
                              'assets/images/pixel_station.png',
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: constraints.maxHeight * .16,
                        child: FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _intro,
                            curve: Curves.easeOut,
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'ARRIVAL BELL',
                                style: TextStyle(
                                  color: Color(0xFFFFF5DD),
                                  fontSize: 12,
                                  letterSpacing: 4.5,
                                  fontWeight: FontWeight.w800,
                                  shadows: [
                                    Shadow(
                                      color: Color(0x44233A68),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'YOUR STOP',
                                style: Theme.of(context).textTheme.displayLarge
                                    ?.copyWith(
                                      color: const Color(0xFFFFF5DD),
                                      fontSize: 33,
                                      letterSpacing: 4,
                                      fontWeight: FontWeight.w800,
                                      shadows: const [
                                        Shadow(
                                          color: Color(0x55304870),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                              ),
                              const Text(
                                'IS WAITING',
                                style: TextStyle(
                                  color: Color(0xFFFFF5DD),
                                  fontSize: 13,
                                  letterSpacing: 5,
                                  fontWeight: FontWeight.w700,
                                  shadows: [
                                    Shadow(
                                      color: Color(0x55304870),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: trainLeft,
                        bottom: -8,
                        width: trainWidth,
                        child: Image.asset(
                          'assets/images/pixel_train.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
              child: SizedBox(
                height: 58,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _boarding ? null : _boardTrain,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF5DD),
                    disabledBackgroundColor: const Color(0xFFFFF5DD),
                    foregroundColor: const Color(0xFF163B72),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _boarding ? 'DEPARTING…' : 'TAP TO BOARD',
                        style: const TextStyle(
                          fontSize: 13,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
