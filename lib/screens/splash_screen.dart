import 'dart:async';
import 'package:flutter/material.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _ambientController;
  late final AnimationController _flashController;
  late final AnimationController _shineController;

  late final Animation<double> _screenOpacity;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoBlurGlow;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _progressOpacity;
  late final Animation<double> _lineOpacity;
  late final Animation<double> _flashOpacity;
  late final Animation<double> _logoYOffset;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    _screenOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 84),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeInOutCubic),
        ),
        weight: 16,
      ),
    ]).animate(_mainController);

    _logoOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 56),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeInCubic),
        ),
        weight: 24,
      ),
    ]).animate(_mainController);

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.68, end: 1.0).chain(
          CurveTween(curve: Curves.easeOutBack),
        ),
        weight: 28,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 44),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.06).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 28,
      ),
    ]).animate(_mainController);

    _logoBlurGlow = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.10, end: 0.42).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.42, end: 0.28).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.28, end: 0.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 30,
      ),
    ]).animate(_mainController);

    _taglineOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 24),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 18,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 24),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 34,
      ),
    ]).animate(_mainController);

    _progressOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 18),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 18,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 24,
      ),
    ]).animate(_mainController);

    _lineOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 16),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 18,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 38),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 28,
      ),
    ]).animate(_mainController);

    _flashOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 0.95).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 38,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 0.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 62,
      ),
    ]).animate(_flashController);

    _logoYOffset = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 20.0, end: 0.0).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 34,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 42),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -8.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 24,
      ),
    ]).animate(_mainController);

    _start();
  }

  Future<void> _start() async {
    unawaited(_ambientController.repeat(reverse: true));

    await Future.delayed(const Duration(milliseconds: 120));
    if (mounted) {
      unawaited(_flashController.forward(from: 0));
    }

    await Future.delayed(const Duration(milliseconds: 350));
    if (mounted) {
      unawaited(_shineController.forward(from: 0));
    }

    await _mainController.forward();

    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _ambientController.dispose();
    _flashController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFD4AF37);
    const goldLight = Color(0xFFF2DA82);
    const goldDark = Color(0xFF8A6A12);

    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _screenOpacity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: Colors.black),

            AnimatedBuilder(
              animation: _ambientController,
              builder: (context, child) {
                final pulse = 0.08 + (_ambientController.value * 0.07);

                return Stack(
                  children: [
                    Positioned(
                      top: -170,
                      left: -120,
                      child: _glowBlob(
                        size: 350,
                        color: gold.withOpacity(pulse),
                      ),
                    ),
                    Positioned(
                      bottom: -190,
                      right: -140,
                      child: _glowBlob(
                        size: 390,
                        color: goldDark.withOpacity(pulse * 0.85),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 0.80,
                            colors: [
                              gold.withOpacity(0.05 + (_ambientController.value * 0.03)),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF000000),
                      Color(0xFF0A0A0A),
                      Color(0xFF000000),
                    ],
                  ),
                ),
              ),
            ),

            FadeTransition(
              opacity: _flashOpacity,
              child: Container(color: Colors.white),
            ),

            Center(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _logoYOffset.value),
                    child: Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 240,
                                  height: 240,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: gold.withOpacity(_logoBlurGlow.value),
                                        blurRadius: 100,
                                        spreadRadius: 14,
                                      ),
                                    ],
                                  ),
                                ),
                                ShaderMask(
                                  shaderCallback: (bounds) {
                                    return const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        goldLight,
                                        gold,
                                        goldDark,
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: const Text(
                                    'AS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 96,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 6,
                                      height: 1,
                                    ),
                                  ),
                                ),

                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: ClipRect(
                                      child: AnimatedBuilder(
                                        animation: _shineController,
                                        builder: (context, child) {
                                          final width = MediaQuery.of(context).size.width;
                                          final dx = -220 + (width + 440) * _shineController.value;

                                          return Transform.translate(
                                            offset: Offset(dx, 0),
                                            child: Transform.rotate(
                                              angle: -0.35,
                                              child: Container(
                                                width: 80,
                                                height: 220,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.white.withOpacity(0.0),
                                                      Colors.white.withOpacity(0.06),
                                                      Colors.white.withOpacity(0.18),
                                                      Colors.white.withOpacity(0.06),
                                                      Colors.white.withOpacity(0.0),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            FadeTransition(
                              opacity: _lineOpacity,
                              child: Container(
                                width: 165,
                                height: 3.4,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      gold.withOpacity(0.98),
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: gold.withOpacity(0.34),
                                      blurRadius: 16,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            FadeTransition(
                              opacity: _taglineOpacity,
                              child: Text(
                                'مكانك الافضل للمشاهدة',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.78),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            Positioned(
              left: 28,
              right: 28,
              bottom: 42,
              child: FadeTransition(
                opacity: _progressOpacity,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 2600),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 3.4,
                            backgroundColor: Colors.white.withOpacity(0.08),
                            valueColor: const AlwaysStoppedAnimation(gold),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'جارِ التحميل...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glowBlob({
    required double size,
    required Color color,
  }) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 160,
              spreadRadius: 36,
            ),
          ],
        ),
      ),
    );
  }
}