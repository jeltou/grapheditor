part of '../graph.dart';

class EdgePreviewHandler extends CustomPainter {
  final Offset from;
  final Offset to;
  final Color color;
  final double strokeWidth;

  const EdgePreviewHandler({
    required this.from,
    required this.to,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final Path path = _buildCubic(from, to, 0.6);
    canvas.drawPath(path, p);
  }

  Path _buildCubic(Offset p0, Offset p3, double curvature) {
    final double dx = p3.dx - p0.dx;
    final double dy = p3.dy - p0.dy;
    final double dist = math.sqrt(dx * dx + dy * dy);
    final double h = dist * (0.25 + 0.35 * curvature);

    late final Offset c1, c2;
    if (dx.abs() >= dy.abs()) {
      final double sx = dx.sign == 0 ? 1.0 : dx.sign;
      c1 = p0 + Offset(h * sx, 0);
      c2 = p3 - Offset(h * sx, 0);
    } else {
      final double sy = dy.sign == 0 ? 1.0 : dy.sign;
      c1 = p0 + Offset(0, h * sy);
      c2 = p3 - Offset(0, h * sy);
    }

    return Path()
      ..moveTo(p0.dx, p0.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p3.dx, p3.dy);
  }

  @override
  bool shouldRepaint(covariant EdgePreviewHandler old) {
    return old.from != from || old.to != to || old.color != color || old.strokeWidth != strokeWidth;
  }
}
