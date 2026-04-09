import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _shimmerController;
  late final AnimationController _bgController;
  late final AnimationController _dotsController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleOffset;
  late final Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.75, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_logoController);

    _logoOpacity = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );

    _titleOpacity = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );

    _titleOffset = Tween<Offset>(
      begin: const Offset(0, 0.32),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    ));

    _glowPulse = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _dotsController, curve: Curves.easeInOut),
    );

    _logoController.forward();

    Timer(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 850),
          pageBuilder: (_, __, ___) => const MainShell(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _shimmerController.dispose();
    _bgController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF040508),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _logoController,
          _shimmerController,
          _bgController,
          _dotsController,
        ]),
        builder: (context, _) {
          return Stack(
            children: [
              Positioned.fill(child: _CinematicBackground(progress: _bgController.value)),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(.08),
                        Colors.black.withOpacity(.18),
                        Colors.black.withOpacity(.84),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _logoOpacity,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: _PremiumLogo(shimmerValue: _shimmerController.value),
                      ),
                    ),
                    const SizedBox(height: 26),
                    FadeTransition(
                      opacity: _titleOpacity,
                      child: SlideTransition(
                        position: _titleOffset,
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) {
                                return const LinearGradient(
                                  colors: [
                                    Color(0xFFF4D77A),
                                    Color(0xFFD6A72F),
                                    Color(0xFFFFE9A3),
                                  ],
                                ).createShader(bounds);
                              },
                              child: const Text(
                                'AsMovies',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'مشاهدة سينمائية في مكان واحد',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    Transform.scale(
                      scale: _glowPulse.value,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          3,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: index == (_dotsController.value * 3).floor() % 3
                                  ? const Color(0xFFD5B13E)
                                  : Colors.white24,
                              shape: BoxShape.circle,
                              boxShadow: index == (_dotsController.value * 3).floor() % 3
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFD5B13E).withOpacity(.55),
                                        blurRadius: 12,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PremiumLogo extends StatelessWidget {
  final double shimmerValue;

  const _PremiumLogo({required this.shimmerValue});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFD5B13E).withOpacity(.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF151A24), Color(0xFF090C12)],
              ),
              border: Border.all(
                color: const Color(0xFFD5B13E).withOpacity(.22),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.35),
                  blurRadius: 26,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
          ),
          ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment(-1 + (shimmerValue * 2), -1),
                end: Alignment(1 + (shimmerValue * 2), 1),
                colors: const [
                  Color(0xFFF9E9A6),
                  Color(0xFFD5B13E),
                  Color(0xFFB7871B),
                  Color(0xFFFFF3C8),
                ],
                stops: const [0.0, 0.33, 0.7, 1.0],
              ).createShader(bounds);
            },
            child: const Text(
              'AS',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CinematicBackground extends StatelessWidget {
  final double progress;

  const _CinematicBackground({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF090B11),
            const Color(0xFF05060A),
            Colors.black,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120 + (progress * 50),
            left: -80,
            child: _glowOrb(
              size: 300,
              colors: [
                const Color(0xFFD5B13E).withOpacity(.16),
                Colors.transparent,
              ],
            ),
          ),
          Positioned(
            bottom: -160,
            right: -120 + (math.sin(progress * math.pi * 2) * 26),
            child: _glowOrb(
              size: 360,
              colors: [
                const Color(0xFF7C5A13).withOpacity(.18),
                Colors.transparent,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowOrb({required double size, required List<Color> colors}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}
