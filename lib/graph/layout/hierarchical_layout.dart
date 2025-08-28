part of '../graph.dart';

class HierarchicalLayout extends AbstractGraphLayout {

  @override
  void apply(Graph graph, LayoutOptions options) {
    final List<AbstractNode> nodes = allNodes(graph);
    if (nodes.isEmpty) return;

    final Map<AbstractNode, List<AbstractNode>> out = buildOutgoing(graph);
    final Map<AbstractNode, List<AbstractNode>> inc = buildIncoming(graph);
    final List<AbstractNode> roots = findRoots(graph);

    final Map<AbstractNode, int> layerOf = <AbstractNode, int>{};
    final List<List<AbstractNode>> layers = <List<AbstractNode>>[];

    final List<AbstractNode> queue = <AbstractNode>[];
    final Set<AbstractNode> visited = <AbstractNode>{};

    for (final AbstractNode r in roots) {
      layerOf[r] = 0;
      queue.add(r);
      visited.add(r);
    }

    while (queue.isNotEmpty) {
      final AbstractNode u = queue.removeAt(0);
      final int lu = layerOf[u] ?? 0;
      if (layers.length <= lu) layers.add(<AbstractNode>[]);
      layers[lu].add(u);

      for (final AbstractNode v in out[u] ?? const <AbstractNode>[]) {
        if (!visited.contains(v)) {
          layerOf[v] = lu + 1;
          visited.add(v);
          queue.add(v);
        }
      }
    }


    for (final AbstractNode n in nodes) {
      if (!visited.contains(n)) {
        final int l = 0;
        if (layers.isEmpty) layers.add(<AbstractNode>[]);
        layerOf[n] = l;
        layers[l].add(n);
      }
    }

    for (int l = 1; l < layers.length; l++) {
      final List<AbstractNode> layer = layers[l];
      layer.sort((AbstractNode a, AbstractNode b) {
        final double ax = _parentBarycenter(a, inc);
        final double bx = _parentBarycenter(b, inc);
        return ax.compareTo(bx);
      });
    }

    final List<double> layerHeights = <double>[];
    final List<double> layerWidths = <double>[];

    for (final List<AbstractNode> layer in layers) {
      double maxH = 0.0;
      double sumW = 0.0;
      for (final AbstractNode n in layer) {
        final Size s = nodeSize(n);
        maxH = math.max(maxH, s.height);
        sumW += s.width;
      }
      final double totalW = sumW + math.max(0, layer.length - 1) * options.hGap;
      layerHeights.add(maxH);
      layerWidths.add(totalW);
    }

    double yCursor = options.origin.dy + options.padding;
    for (int l = 0; l < layers.length; l++) {
      final List<AbstractNode> layer = layers[l];
      final double layerHeight = layerHeights[l];
      double xCursor = options.origin.dx + options.padding;

      for (final AbstractNode n in layer) {
        final Size s = nodeSize(n);
        n.setPosition(Offset(xCursor, yCursor));
        xCursor += s.width + options.hGap;
      }
      yCursor += layerHeight + options.vGap;
    }
  }

  double _parentBarycenter(AbstractNode n, Map<AbstractNode, List<AbstractNode>> inc) {
    final List<AbstractNode> parents = inc[n] ?? const <AbstractNode>[];
    if (parents.isEmpty) return 0.0;

    double sum = 0.0;
    for (final AbstractNode p in parents) {
      sum += p.hashCode.toDouble();
    }
    return sum / parents.length;
  }
}
