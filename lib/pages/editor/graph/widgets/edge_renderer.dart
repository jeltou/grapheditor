part of '../graph.dart';

class EdgeRenderer extends StatelessWidget {
  final List<AbstractEdge> edges;
  final Color color;
  final double strokeWidth;
  final bool arrows;

  final AbstractEdge? hovered;
  final Set<AbstractEdge>? selected;
  final Color? highlightHover;
  final Color? highlightSelected;

  const EdgeRenderer({
    super.key,
    required this.edges,
    this.color = const Color(0xFF555555),
    this.strokeWidth = 2.0,
    this.arrows = true,
    this.hovered,
    this.selected,
    this.highlightHover,
    this.highlightSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _EdgePainter(
          edges: edges,
          color: color,
          strokeWidth: strokeWidth,
          arrows: arrows,
          hovered: hovered,
          selected: selected ?? const <AbstractEdge>{},
          highlightHover: highlightHover ?? Theme.of(context).colorScheme.primary,
          highlightSelected: highlightSelected ?? Theme.of(context).colorScheme.error,
        ),
        isComplex: true,
        willChange: true,
      ),
    );
  }
}

class _EdgePainter extends CustomPainter {
  final List<AbstractEdge> edges;
  final Color color;
  final double strokeWidth;
  final bool arrows;

  final AbstractEdge? hovered;
  final Set<AbstractEdge> selected;
  final Color highlightHover;
  final Color highlightSelected;

  _EdgePainter({
    required this.edges,
    required this.color,
    required this.strokeWidth,
    required this.arrows,
    required this.hovered,
    required this.selected,
    required this.highlightHover,
    required this.highlightSelected,
  });

  static const double _padTop = 14.0;
  static const double _headerH = 56.0;
  static const double _space1 = 10.0;
  static const double _dividerH = 1.0;
  static const double _space2 = 8.0;
  static const double _rowH = 44.0;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final AbstractEdge e in edges) {
      late final Offset p0;
      late final Offset p3;

      final Rect toRect = Rect.fromLTWH(e.to.position.dx, e.to.position.dy, e.to.width, e.to.height);

      final Rect fromRect = Rect.fromLTWH(e.from.position.dx, e.from.position.dy, e.from.width, e.from.height);
      p0 = _anchorOnRect(fromRect, toRect.center);
      p3 = _anchorOnRect(toRect, fromRect.center);

      final (Offset c1, Offset c2) = _cubicHandles(p0, p3, 0.6);

      final bool isSel = selected.contains(e);
      final bool isHov = identical(hovered, e);

      final Paint paint = base
        ..color = isSel ? highlightSelected : (isHov ? highlightHover : color)
        ..strokeWidth = isSel ? (strokeWidth + 2.0) : (isHov ? (strokeWidth + 1.0) : strokeWidth);

      final Path path = Path()
        ..moveTo(p0.dx, p0.dy)
        ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p3.dx, p3.dy);
      canvas.drawPath(path, paint);

      if (arrows) {
        _drawArrowHeadAlong(canvas, tip: p3, dir: p3 - c2, basePaint: paint);
      }

      if (e is BranchEdge) {
        _drawBranchLabel(canvas: canvas, text: e.fromPort, p0: p0, c1: c1, c2: c2, p3: p3, color: paint.color);
      }
    }
  }

  Offset _branchAnchor(DecisionNode n, String branchName, {required Offset toward}) {
    int idx = n.branches.indexWhere((DecisionBranch b) => b.name == branchName);
    if (idx < 0) idx = 0;

    final double listTop = n.position.dy + _padTop + _headerH + _space1 + _dividerH + _space2;
    final double y = listTop + idx * _rowH + _rowH / 2.0;

    final double nodeMidX = n.position.dx + n.width / 2.0;
    final bool rightSide = toward.dx >= nodeMidX;
    final double x = rightSide ? (n.position.dx + n.width) : n.position.dx;
    return Offset(x, y);
  }

  Offset _anchorOnRect(Rect rect, Offset toward) {
    final double cx = rect.center.dx, cy = rect.center.dy;
    double dx = toward.dx - cx, dy = toward.dy - cy;
    if (dx == 0 && dy == 0) return Offset(rect.right, cy);
    final double hw = rect.width / 2.0, hh = rect.height / 2.0;
    final double absDx = dx.abs(), absDy = dy.abs();
    late final double sx, sy;
    if (absDx * hh > absDy * hw) {
      sx = dx.sign * hw;
      sy = dy * (hw / absDx);
    } else {
      sx = dx * (hh / absDy);
      sy = dy.sign * hh;
    }
    return Offset(cx + sx, cy + sy);
  }

  (Offset, Offset) _cubicHandles(Offset p0, Offset p3, double k) {
    final double dx = p3.dx - p0.dx, dy = p3.dy - p0.dy;
    final double dist = math.sqrt(dx * dx + dy * dy);
    final double h = dist * (0.25 + 0.35 * k.clamp(0.0, 1.0));
    if (dx.abs() >= dy.abs()) {
      final double sx = dx.sign == 0 ? 1.0 : dx.sign;
      return (p0 + Offset(h * sx, 0), p3 - Offset(h * sx, 0));
    } else {
      final double sy = dy.sign == 0 ? 1.0 : dy.sign;
      return (p0 + Offset(0, h * sy), p3 - Offset(0, h * sy));
    }
  }

  void _drawBranchLabel({
    required Canvas canvas,
    required String text,
    required Offset p0,
    required Offset c1,
    required Offset c2,
    required Offset p3,
    required Color color,
  }) {
    const double t = 0.5;

    Offset _pointAt(double t) {
      final double mt = 1.0 - t;
      final double mt2 = mt * mt;
      final double t2 = t * t;
      return Offset(
        mt2 * mt * p0.dx + 3 * mt2 * t * c1.dx + 3 * mt * t2 * c2.dx + t2 * t * p3.dx,
        mt2 * mt * p0.dy + 3 * mt2 * t * c1.dy + 3 * mt * t2 * c2.dy + t2 * t * p3.dy,
      );
    }

    Offset _tangentAt(double t) {
      final double mt = 1.0 - t;

      final Offset a = (c1 - p0) * (mt * mt);
      final Offset b = (c2 - c1) * (2 * mt * t);
      final Offset c = (p3 - c2) * (t * t);
      return (a + b + c) * 3.0;
    }

    final Offset pt = _pointAt(t);
    Offset tan = _tangentAt(t);
    if (tan.distance < 1e-3) tan = const Offset(1, 0);

    Offset nrm = Offset(-tan.dy, tan.dx);
    if (nrm.distance < 1e-3) nrm = const Offset(0, -1);
    nrm = nrm / nrm.distance;

    const double offset = 12.0;
    final Offset center = pt + nrm * offset;

    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 180);

    const double padH = 6.0;
    const double padV = 2.0;
    final Size ts = tp.size;
    final Rect r = Rect.fromCenter(center: center, width: ts.width + padH * 2, height: ts.height + padV * 2);

    final RRect rr = RRect.fromRectAndRadius(r, const Radius.circular(8));
    final Paint bg = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.fill;
    final Paint bd = Paint()
      ..color = color.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(rr, bg);
    canvas.drawRRect(rr, bd);

    final Offset textTopLeft = Offset(r.left + padH, r.top + padV);
    tp.paint(canvas, textTopLeft);
  }

  void _drawArrowHeadAlong(Canvas canvas, {required Offset tip, required Offset dir, required Paint basePaint}) {
    final double len = dir.distance;
    if (len == 0) return;
    final Offset u = dir / len;
    const double aLen = 12.0, aDeg = 25.0;

    Offset rot(Offset v, double deg) {
      final double r = deg * math.pi / 180.0;
      final double c = math.cos(r), s = math.sin(r);
      return Offset(v.dx * c - v.dy * s, v.dx * s + v.dy * c);
    }

    final Offset left = tip - rot(u, aDeg) * aLen;
    final Offset right = tip - rot(u, -aDeg) * aLen;

    final Paint fill = Paint()
      ..color = basePaint.color
      ..style = PaintingStyle.fill;

    final Path head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    canvas.drawPath(head, fill);
  }

  @override
  bool shouldRepaint(covariant _EdgePainter old) =>
      old.edges != edges ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.arrows != arrows ||
      old.hovered != hovered ||
      old.selected != selected ||
      old.highlightHover != highlightHover ||
      old.highlightSelected != highlightSelected;
}
