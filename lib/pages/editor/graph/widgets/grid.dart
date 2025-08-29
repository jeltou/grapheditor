part of '../graph.dart';

class GridPainter extends CustomPainter {
  final TransformationController controller;
  final double step;

  GridPainter({required this.controller, this.step = 50});

  @override
  void paint(Canvas canvas, Size size) {
    final inv = Matrix4.inverted(controller.value);
    final corners = [const Offset(0, 0), Offset(size.width, 0), Offset(0, size.height), Offset(size.width, size.height)].map((p) {
      final v = inv.transform3(Vector3(p.dx, p.dy, 0));
      return Offset(v.x, v.y);
    }).toList();

    final minX = corners.map((e) => e.dx).reduce(math.min);
    final maxX = corners.map((e) => e.dx).reduce(math.max);
    final minY = corners.map((e) => e.dy).reduce(math.min);
    final maxY = corners.map((e) => e.dy).reduce(math.max);

    final paint = Paint()
      ..strokeWidth = 1
      ..color = Colors.black12;

    final startX = (minX / step).floor() * step;
    final startY = (minY / step).floor() * step;

    for (double x = startX; x <= maxX; x += step) {
      canvas.drawLine(Offset(x, minY), Offset(x, maxY), paint);
    }
    for (double y = startY; y <= maxY; y += step) {
      canvas.drawLine(Offset(minX, y), Offset(maxX, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter old) => old.controller.value != controller.value || old.step != step;
}