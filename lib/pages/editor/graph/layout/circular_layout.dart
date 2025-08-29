part of '../graph.dart';

class CircularLayout extends AbstractGraphLayout {

  @override
  void apply(Graph graph, LayoutOptions options) {
    final List<AbstractNode> nodes = allNodes(graph);
    if (nodes.isEmpty) return;

    double sumW = 0.0;
    for (final AbstractNode n in nodes) {
      sumW += nodeSize(n).width;
    }
    final double avgW = sumW / nodes.length;
    final double rHint = options.radiusHint ??
        math.max(200.0, (nodes.length * (avgW + options.hGap)) / (2 * math.pi));

    final Offset center = options.origin + Offset(rHint + options.padding, rHint + options.padding);

    for (int i = 0; i < nodes.length; i++) {
      final double t = (i / nodes.length) * 2 * math.pi;
      final AbstractNode n = nodes[i];
      final Size s = nodeSize(n);

      final double cx = center.dx + rHint * math.cos(t);
      final double cy = center.dy + rHint * math.sin(t);
      n.setPosition(Offset(cx - s.width * 0.5, cy - s.height * 0.5));
    }
  }
}