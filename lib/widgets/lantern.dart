import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The paper lantern that stands in for a progress bar.
///
/// [lit] (0..1) is the fraction of the deck already opened; the light fills
/// the body from the bottom up, so the shape carries the number before the
/// numeral inside it is read. Deliberately not a ring: a ring's arc says
/// "percentage", while a lantern that is half dark says "there is more of
/// this to light", which is the same fact framed as an invitation.
///
/// Geometry is drawn in a 150x208 reference box and scaled to whatever it's
/// given, so the caller only picks a size.
class LanternPainter extends CustomPainter {
  /// 0 = unlit paper, 1 = fully lit.
  final double lit;

  /// The lantern's light - the theme's accent.
  final Color light;

  LanternPainter({required this.lit, required this.light});

  static const double _refWidth = 150;
  static const double _refHeight = 208;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _refWidth, size.height / _refHeight);

    final body = _bodyPath();

    // Unlit paper: a faint warm wash so the lantern is always visible,
    // even at lit == 0 on the darkest ground.
    canvas.drawPath(body, Paint()..color = light.withValues(alpha: 0.07));

    // The light itself, clipped to the body and rising from the bottom.
    if (lit > 0) {
      canvas.save();
      canvas.clipPath(body);
      const bodyTop = 26.0;
      const bodyBottom = 182.0;
      final level = bodyBottom - (bodyBottom - bodyTop) * lit;
      final glowRect = Rect.fromLTRB(0, level - 26, _refWidth, bodyBottom);
      canvas.drawRect(
        Rect.fromLTRB(0, level, _refWidth, bodyBottom),
        Paint()..color = light.withValues(alpha: 0.92),
      );
      // A soft edge where light meets unlit paper, so the fill reads as
      // glow rather than as a liquid level line.
      canvas.drawRect(
        glowRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [light.withValues(alpha: 0), light.withValues(alpha: 0.92)],
          ).createShader(glowRect),
      );
      canvas.restore();
    }

    // Bamboo ribs. Drawn over the light and clipped to the body, which is
    // what keeps this reading as paper stretched over a frame instead of a
    // filled vessel.
    canvas.save();
    canvas.clipPath(body);
    final ribPaint = Paint()
      ..color = const Color(0xFF14100F).withValues(alpha: 0.22)
      ..strokeWidth = 2.4;
    for (var y = 44.0; y < 182; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(_refWidth, y), ribPaint);
    }
    canvas.restore();

    // The paper's own outline.
    canvas.drawPath(
      body,
      Paint()
        ..color = light.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6,
    );

    // Cap and base - the wooden fittings the paper is stretched between.
    final fitting = Paint()..color = light.withValues(alpha: 0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(46, 8, 58, 13), const Radius.circular(3)),
      fitting,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(54, 180, 42, 12), const Radius.circular(3)),
      fitting,
    );
    // The cord it hangs from.
    canvas.drawLine(
      const Offset(_refWidth / 2, 0),
      const Offset(_refWidth / 2, 8),
      Paint()
        ..color = light.withValues(alpha: 0.5)
        ..strokeWidth = 2,
    );

    canvas.restore();
  }

  /// The classic chōchin silhouette: straight-ish shoulders, a belly that
  /// bulges past the fittings, drawn as two mirrored cubics.
  Path _bodyPath() {
    return Path()
      ..moveTo(75, 20)
      ..cubicTo(112, 20, 134, 54, 134, 104)
      ..cubicTo(134, 154, 112, 188, 75, 188)
      ..cubicTo(38, 188, 16, 154, 16, 104)
      ..cubicTo(16, 54, 38, 20, 75, 20)
      ..close();
  }

  @override
  bool shouldRepaint(covariant LanternPainter oldDelegate) =>
      oldDelegate.lit != lit || oldDelegate.light != light;
}

/// The warm pool of light the lantern throws onto whatever is behind it.
/// [intensity] (0..1) scales with how lit the lantern is - an unlit lantern
/// casts nothing.
class LanternGlowPainter extends CustomPainter {
  final Color color;
  final double intensity;

  /// Where the glow is centred, as a fraction of the canvas.
  final Alignment center;

  LanternGlowPainter({
    required this.color,
    required this.intensity,
    this.center = const Alignment(0, 0.15),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final origin = center.alongSize(size);
    final radius = math.max(size.width, size.height) * 0.62;
    final rect = Rect.fromCircle(center: origin, radius: radius);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.30 * intensity),
            color.withValues(alpha: 0.10 * intensity),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant LanternGlowPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.intensity != intensity ||
      oldDelegate.center != center;
}
