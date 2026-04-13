import 'package:flutter/material.dart';

class AsLogo extends StatelessWidget {
  final double size;
  final bool glow;
  final bool showBackground;
  final bool compact;

  const AsLogo({
    super.key,
    this.size = 120,
    this.glow = true,
    this.showBackground = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.28);

    final text = ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF2BF),
            Color(0xFFE6BC4A),
            Color(0xFF9E7315),
          ],
        ).createShader(bounds);
      },
      child: Text(
        'AS',
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? size * 0.47 : size * 0.43,
          fontWeight: FontWeight.w900,
          letterSpacing: compact ? 0.8 : 1.4,
          height: 1,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.32),
              blurRadius: size * 0.04,
              offset: Offset(size * 0.012, size * 0.018),
            ),
          ],
        ),
      ),
    );

    if (!showBackground) {
      return SizedBox(width: size, height: size, child: Center(child: text));
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF121212),
            Color(0xFF070707),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFD7B75C).withOpacity(0.45),
          width: size * 0.014,
        ),
        boxShadow: [
          if (glow)
            BoxShadow(
              color: const Color(0xFFFFD76A).withOpacity(0.20),
              blurRadius: size * 0.24,
              spreadRadius: size * 0.015,
            ),
          BoxShadow(
            color: Colors.black.withOpacity(0.38),
            blurRadius: size * 0.14,
            offset: Offset(0, size * 0.055),
          ),
        ],
      ),
      child: Center(child: text),
    );
  }
}
