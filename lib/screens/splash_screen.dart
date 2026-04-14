import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/as_logo.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _shineController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textOffset;
  late final Animation<double> _lineScale;
  late final Animation<double> _lineOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _logoScale = Tween<double>(begin: .76, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, .40)),
    );

    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(.34, .84)),
    );

    _textOffset = Tween<Offset>(
      begin: const Offset(0, .18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _lineScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(.46, .90)),
    );

    _lineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(.48, .92)),
    );

    _start();
  }

  Future<void> _start() async {
    await _controller.forward();
    await _shineController.forward();

    await Future.delayed(const Duration(milliseconds: 180));

    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: const MainShell(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _shineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _CleanBackground(),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _logoOpacity,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: SizedBox(
                      width: 180,
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const AsLogo(size: 150, glow: true),
                          ClipOval(
                            child: AnimatedBuilder(
                              animation: _shineController,
                              builder: (_, __) {
                                return Transform.translate(
                                  offset: Offset(
                                    -120 + (_shineController.value * 240),
                                    0,
                                  ),
                                  child: Container(
                                    width: 36,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0),
                                          Colors.white.withOpacity(0.05),
                                          Colors.white.withOpacity(0.22),
                                          Colors.white.withOpacity(0.05),
                                          Colors.white.withOpacity(0),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                FadeTransition(
                  opacity: _textOpacity,
                  child: SlideTransition(
                    position: _textOffset,
                    child: const Column(
                      children: [
                        Text(
                          'AsMovies',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'مكانك الافضل للمشاهدة',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                FadeTransition(
                  opacity: _lineOpacity,
                  child: ScaleTransition(
                    scale: _lineScale,
                    child: Container(
                      width: 110,
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFFE3BA4E),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CleanBackground extends StatelessWidget {
  const _CleanBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -.1),
          radius: 1.2,
          colors: [
            Color(0xFF15120A),
            Color(0xFF070707),
            Color(0xFF010101),
          ],
        ),
      ),
    );
  }
}
