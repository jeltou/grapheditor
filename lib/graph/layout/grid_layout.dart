part of '../graph.dart';

class GridLayout extends AbstractGraphLayout {
  @override
  String get name => toString();

  @override
  void apply(Graph graph, LayoutOptions options) {
    final List<AbstractNode> nodes = allNodes(graph);
    if (nodes.isEmpty) return;


    double maxW = 0.0, maxH = 0.0;
    for (final AbstractNode n in nodes) {
      final Size s = nodeSize(n);
      maxW = math.max(maxW, s.width);
      maxH = math.max(maxH, s.height);
    }
    final double tileW = maxW + options.hGap;
    final double tileH = maxH + options.vGap;

    final int count = nodes.length;
    final int cols = math.max(1, (math.sqrt(count)).floor());
    int r = 0, c = 0;

    for (final AbstractNode n in nodes) {
      final double x = options.origin.dx + options.padding + c * tileW;
      final double y = options.origin.dy + options.padding + r * tileH;
      n.setPosition(Offset(x, y));

      c++;
      if (c >= cols) {
        c = 0;
        r++;
      }
    }
  }
}
