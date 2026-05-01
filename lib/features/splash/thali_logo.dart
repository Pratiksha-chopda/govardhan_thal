import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

/// Professional Govardhan Thal brand logo.
/// A warm orange gradient icon with stylized "G" and thali accent.
/// Matches app theme (#FF6B00 family) and works at all sizes.
class ThaliLogo extends StatelessWidget {
  final double size;

  const ThaliLogo({
    super.key,
    this.size = 120.0,
  });

  @override
  Widget build(BuildContext context) {
    final double cornerRadius = size * 0.24;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        // Rich orange gradient matching app theme
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF8C00), // Warm amber top-left
            Color(0xFFFF6B00), // App primary orange
            Color(0xFFE85D00), // Deep orange bottom-right
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(cornerRadius),
        // Professional shadow system
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.4),
            blurRadius: size * 0.2,
            spreadRadius: size * 0.01,
            offset: Offset(0, size * 0.08),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: size * 0.1,
            offset: Offset(0, size * 0.04),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cornerRadius),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background subtle pattern — thali plate ring accent
            Positioned(
              right: -size * 0.12,
              bottom: -size * 0.12,
              child: CustomPaint(
                size: Size(size * 0.65, size * 0.65),
                painter: _ThaliRingPainter(
                  color: Colors.white.withValues(alpha: 0.08),
                  strokeWidth: size * 0.03,
                ),
              ),
            ),

            // Top-left glass shine for 3D depth
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: size * 0.7,
                height: size * 0.45,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(cornerRadius),
                    bottomRight: Radius.circular(size * 0.5),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Inner subtle border for premium feel
            Container(
              width: size - 2,
              height: size - 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cornerRadius - 1),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 0.8,
                ),
              ),
            ),

            // The bold "G" letter — brand mark
            Padding(
              padding: EdgeInsets.only(bottom: size * 0.02),
              child: Text(
                "G",
                style: GoogleFonts.poppins(
                  fontSize: size * 0.52,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      offset: Offset(0, size * 0.02),
                      blurRadius: size * 0.04,
                    ),
                  ],
                ),
              ),
            ),

            // Small leaf accent — food/freshness identity
            Positioned(
              top: size * 0.13,
              right: size * 0.16,
              child: CustomPaint(
                size: Size(size * 0.16, size * 0.16),
                painter: _LeafPainter(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws a subtle thali plate ring accent in the background
class _ThaliRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _ThaliRingPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    // Outer ring
    canvas.drawCircle(center, radius, paint);

    // Inner ring (like a thali edge)
    paint.strokeWidth = strokeWidth * 0.5;
    paint.color = color.withValues(alpha: 0.5);
    canvas.drawCircle(center, radius * 0.72, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Draws a small decorative leaf — represents freshness & food
class _LeafPainter extends CustomPainter {
  final Color color;

  _LeafPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    // Leaf shape
    path.moveTo(size.width * 0.5, 0);
    path.quadraticBezierTo(
      size.width * 1.1, size.height * 0.3,
      size.width * 0.5, size.height,
    );
    path.quadraticBezierTo(
      -size.width * 0.1, size.height * 0.3,
      size.width * 0.5, 0,
    );
    path.close();

    // Rotate the leaf slightly for natural look
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-math.pi / 6); // -30 degrees
    canvas.translate(-size.width / 2, -size.height / 2);
    canvas.drawPath(path, paint);

    // Center vein of the leaf
    final veinPaint = Paint()
      ..color = const Color(0xFFFF6B00).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.15),
      Offset(size.width * 0.5, size.height * 0.8),
      veinPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
