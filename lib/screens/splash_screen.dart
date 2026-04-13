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
  late final Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2550),
    )..forward();

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoScale = Tween<double>(begin: .78, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, .36)),
    );

    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(.28, .70)),
    );

    _textOffset = Tween<Offset>(
      begin: const Offset(0, .18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _lineScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(.42, .86)),
    );

    _lineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(.46, .90)),
    );

    _fadeOut = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(.84, 1.0, curve: Curves.easeInOut)),
    );

    _start();
  }

  Future<void> _start() async {
    await Future.delayed(const Duration(milliseconds: 280));
    if (mounted) {
      unawaited(_shineController.forward(from: 0));
    }

    await Future.delayed(const Duration(milliseconds: 2920));

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
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
      body: AnimatedBuilder(
        animation: Listenable.merge([_controller, _shineController]),
        builder: (context, _) {
          return Opacity(
            opacity: _fadeOut.value,
            child: Stack(
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
                            width: 190,
                            height: 190,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const AsLogo(size: 152, glow: true),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Transform.translate(
                                    offset: Offset(
                                      -150 + (_shineController.value * 300),
                                      0,
                                    ),
                                    child: Container(
                                      width: 38,
                                      height: 180,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.0),
                                            Colors.white.withOpacity(0.05),
                                            Colors.white.withOpacity(0.22),
                                            Colors.white.withOpacity(0.05),
                                            Colors.white.withOpacity(0.0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
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
                                  fontSize: 31,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .8,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'تجربة مشاهدة سينمائية',
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
                            width: 112,
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
        },
      ),
    );
  }
}

class _CleanBackground extends StatelessWidget {
  const _CleanBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -.12),
              radius: 1.18,
              colors: [
                Color(0xFF161107),
                Color(0xFF070707),
                Color(0xFF010101),
              ],
            ),
          ),
        ),
        Positioned(
          top: -100,
          left: -60,
          child: _GlowOrb(size: 220, opacity: .05),
        ),
        Positioned(
          right: -80,
          bottom: 50,
          child: _GlowOrb(size: 200, opacity: .04),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final double opacity;

  const _GlowOrb({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE3BA4E).withOpacity(opacity),
            blurRadius: size * 0.62,
            spreadRadius: size * 0.09,
          ),
        ],
      ),
    );
  }
}
