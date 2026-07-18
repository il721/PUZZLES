import 'package:flutter/material.dart';
import 'package:module_digit_rebus/module_digit_rebus.dart';

/// Paints the book's cell-masking glyph marker for one [Glyph], scaled to
/// the painter's size (designed against a 50x50 cell):
///
///  * [Glyph.g1] — closed loop centered on the top edge;
///  * [Glyph.g2] — closed loop centered on the bottom edge;
///  * [Glyph.g3] — straight vertical stem at the bottom;
///  * [Glyph.g4] — open loop (gap facing the cell center) at the top;
///  * [Glyph.g5] — open hook (gap facing the cell center) at the bottom.
///
/// Only the marker is painted — the cell's box/border and digit are drawn
/// by the enclosing widget — so the same painter also serves the legend.
class GlyphMarkerPainter extends CustomPainter {
  /// The glyph whose marker to paint.
  final Glyph glyph;

  /// Stroke color of the marker.
  final Color color;

  /// Creates a glyph marker painter.
  const GlyphMarkerPainter({required this.glyph, required this.color});

  /// The gap (in radians) left open in the g4/g5 loops, facing the cell
  /// center, distinguishing them from the closed g1/g2 loops.
  static const double _gapSweep = 1.9;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.05
      ..strokeCap = StrokeCap.round;

    final r = size.shortestSide * 0.14;
    final cx = size.width / 2;
    final topCenter = Offset(cx, r + size.height * 0.06);
    final bottomCenter = Offset(cx, size.height - r - size.height * 0.06);
    const fullCircle = 3.14159265 * 2;

    switch (glyph) {
      case Glyph.g1:
        canvas.drawCircle(topCenter, r, paint);
      case Glyph.g2:
        canvas.drawCircle(bottomCenter, r, paint);
      case Glyph.g3:
        canvas.drawLine(
          Offset(cx, size.height - size.height * 0.06),
          Offset(cx, size.height - size.height * 0.06 - r * 2.2),
          paint,
        );
      case Glyph.g4:
        // Gap centered at 90 deg (pointing down, toward the cell center).
        canvas.drawArc(
          Rect.fromCircle(center: topCenter, radius: r),
          3.14159265 / 2 + _gapSweep / 2,
          fullCircle - _gapSweep,
          false,
          paint,
        );
      case Glyph.g5:
        // Gap centered at -90 deg (pointing up, toward the cell center).
        canvas.drawArc(
          Rect.fromCircle(center: bottomCenter, radius: r),
          -3.14159265 / 2 + _gapSweep / 2,
          fullCircle - _gapSweep,
          false,
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(GlyphMarkerPainter oldDelegate) =>
      oldDelegate.glyph != glyph || oldDelegate.color != color;
}
