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

    final content = Stack(
      alignment: Alignment.center,
      children: [
        if (showBackground)
          Positioned(
            top: size * 0.07,
            left: size * 0.12,
            right: size * 0.12,
            child: Container(
              height: size * 0.15,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.22),
                    Colors.white.withOpacity(0.02),
                  ],
                ),
              ),
            ),
          ),
        ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF7D3),
                Color(0xFFFFE082),
                Color(0xFFE6BC4A),
                Color(0xFFB27B12),
                Color(0xFFFFECB3),
              ],
              stops: [0.0, 0.24, 0.48, 0.78, 1.0],
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
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: size * 0.04,
                  offset: Offset(size * 0.012, size * 0.018),
                ),
              ],
            ),
          ),
        ),
        if (showBackground)
          Positioned(
            top: size * 0.18,
            left: size * 0.20,
            child: Container(
              width: size * 0.07,
              height: size * 0.07,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.85),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.30),
                    blurRadius: size * 0.055,
                    spreadRadius: size * 0.008,
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    if (!showBackground) {
      return SizedBox(width: size, height: size, child: content);
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
              color: const Color(0xFFFFD76A).withOpacity(0.22),
              blurRadius: size * 0.26,
              spreadRadius: size * 0.02,
            ),
          BoxShadow(
            color: Colors.black.withOpacity(0.38),
            blurRadius: size * 0.14,
            offset: Offset(0, size * 0.055),
          ),
        ],
      ),
      child: content,
    );
  }
}
