part of '../graph.dart';

Size nodeSize(AbstractNode n) {
  final double w = (n.width).toDouble();
  final double h = (n.height).toDouble();
  return Size(w > 0 ? w : 120.0, h > 0 ? h : 72.0);
}

List<AbstractNode> allNodes(Graph g) => g.nodes.values.toList();

List<AbstractEdge> allEdges(Graph g) => g.edges.values.toList();

Map<AbstractNode, List<AbstractNode>> buildOutgoing(Graph g) {
  final Map<AbstractNode, List<AbstractNode>> out = <AbstractNode, List<AbstractNode>>{};
  for (final AbstractNode n in allNodes(g)) {
    out[n] = <AbstractNode>[];
  }
  for (final AbstractEdge e in allEdges(g)) {
    out[e.from]!.add(e.to);
  }
  return out;
}

Map<AbstractNode, List<AbstractNode>> buildIncoming(Graph g) {
  final Map<AbstractNode, List<AbstractNode>> inc = <AbstractNode, List<AbstractNode>>{};
  for (final AbstractNode n in allNodes(g)) {
    inc[n] = <AbstractNode>[];
  }
  for (final AbstractEdge e in allEdges(g)) {
    inc[e.to]!.add(e.from);
  }
  return inc;
}

List<AbstractNode> findRoots(Graph g) {
  final Map<AbstractNode, List<AbstractNode>> inc = buildIncoming(g);
  final List<AbstractNode> roots = <AbstractNode>[
    for (final MapEntry<AbstractNode, List<AbstractNode>> it in inc.entries)
      if (it.value.isEmpty) it.key,
  ];
  if (roots.isEmpty && inc.isNotEmpty) {
    roots.add(inc.keys.first);
  }
  return roots;
}

AbstractNode? resolveStartNode(Graph graph) {
  for (final AbstractNode n in graph.nodes.values) {
    if (n is RootNode) return n;
  }
  return null;
}

bool isEnd(AbstractNode n) => n is EndNode;

extension _Let<T> on T { R let<R>(R Function(T it) f) => f(this); }

String normalizeTypeString(String raw) {
  if (raw.isEmpty) return raw;
  String s = raw;
  if (s.startsWith("Instance of '") && s.endsWith("'")) {
    s = s.substring("Instance of '".length, s.length - 1);
  }
  return s;
}

dynamic ctxGetPath(Map<String, dynamic> ctx, String path) {
  List<String> parts = path.split('.');
  dynamic cur = ctx;
  for (final String p in parts) {
    if (cur is Map && cur.containsKey(p)) {
      cur = cur[p];
    } else {
      return null;
    }
  }
  return cur;
}

void ctxSetPath(Map<String, dynamic> ctx, String path, dynamic value) {
  List<String> parts = path.split('.');
  Map<String, dynamic> cur = ctx;
  for (int i = 0; i < parts.length - 1; i++) {
    final String key = parts[i];
    final dynamic next = cur[key];
    if (next is Map<String, dynamic>) {
      cur = next;
    } else {
      final Map<String, dynamic> created = <String, dynamic>{};
      cur[key] = created;
      cur = created;
    }
  }
  cur[parts.last] = value;
}

void ctxRemovePath(Map<String, dynamic> ctx, String path) {
  List<String> parts = path.split('.');
  Map<String, dynamic> cur = ctx;
  for (int i = 0; i < parts.length - 1; i++) {
    final String key = parts[i];
    final dynamic next = cur[key];
    if (next is Map<String, dynamic>) {
      cur = next;
    } else {
      return;
    }
  }
  cur.remove(parts.last);
}

void generateRandomGraph({
  required dynamic graph,
  int layers = 8,
  int nodesPerLayer = 30,
  int edgesPerNode = 2,
  double horizontalGap = 220.0,
  double verticalGap = 140.0,
  Offset origin = const Offset(0, 0),
  double jitter = 24.0,
  int seed = 42,
  AbstractNode Function(int layer, int index)? makeNode,
  AbstractEdge Function(AbstractNode from, AbstractNode to)? makeEdge,
}) {
  if (layers < 1) {
    throw ArgumentError.value(layers, 'layers', 'Must be >= 1');
  }
  if (nodesPerLayer < 0) {
    throw ArgumentError.value(nodesPerLayer, 'nodesPerLayer', 'Must be >= 0');
  }
  if (edgesPerNode < 0) {
    throw ArgumentError.value(edgesPerNode, 'edgesPerNode', 'Must be >= 0');
  }
  if (layers > 1 && nodesPerLayer > 0 && edgesPerNode == 0) {
    throw ArgumentError('edgesPerNode must be >= 1 when layers > 1 and nodesPerLayer > 0 to guarantee coverage.');
  }

  final math.Random rng = math.Random(seed);

  AbstractNode defaultMakeNode(int layer, int index) {
    if (layer == 0 && index == 0) {
      return RootNode(label: "Root");
    }
    return DefaultNode(label: '$layer-$index');
  }

  AbstractEdge defaultMakeEdge(AbstractNode from, AbstractNode to) {
    return DefaultEdge(from, to);
  }

  final AbstractNode Function(int, int) nodeFactory = makeNode ?? defaultMakeNode;
  final AbstractEdge Function(AbstractNode, AbstractNode) edgeFactory = makeEdge ?? defaultMakeEdge;

  final List<List<AbstractNode>> layerNodes = List<List<AbstractNode>>.generate(layers, (int _) => <AbstractNode>[], growable: false);

  for (int layer = 0; layer < layers; layer++) {
    final int count = (layer == 0) ? 1 : nodesPerLayer;
    for (int i = 0; i < count; i++) {
      final AbstractNode node = nodeFactory(layer, i);
      final double x = origin.dx + i * horizontalGap;
      final double y = origin.dy + layer * verticalGap;

      final double jx = (jitter > 0) ? (rng.nextDouble() * jitter - jitter * 0.5) : 0.0;
      final double jy = (jitter > 0) ? (rng.nextDouble() * jitter - jitter * 0.5) : 0.0;

      final Offset pos = Offset(x + jx, y + jy);
      node.setPosition(pos);

      layerNodes[layer].add(node);
      graph.addNode(node);
    }
  }

  for (int layer = 0; layer < layers - 1; layer++) {
    final List<AbstractNode> fromLayer = layerNodes[layer];
    final List<AbstractNode> toLayer = layerNodes[layer + 1];

    if (fromLayer.isEmpty || toLayer.isEmpty) {
      continue;
    }

    final Map<AbstractNode, Set<int>> usedTargetsByFrom = <AbstractNode, Set<int>>{for (final AbstractNode f in fromLayer) f: <int>{}};

    for (int t = 0; t < toLayer.length; t++) {
      final AbstractNode toNode = toLayer[t];
      final AbstractNode fromNode = fromLayer[t % fromLayer.length];
      if (!usedTargetsByFrom[fromNode]!.contains(t)) {
        final AbstractEdge e = edgeFactory(fromNode, toNode);
        graph.addEdge(e);
        usedTargetsByFrom[fromNode]!.add(t);
      }
    }

    for (final AbstractNode fromNode in fromLayer) {
      final Set<int> used = usedTargetsByFrom[fromNode]!;
      final int remaining = math.max(0, edgesPerNode - used.length);
      if (remaining == 0) continue;

      final List<int> candidates = <int>[
        for (int idx = 0; idx < toLayer.length; idx++)
          if (!used.contains(idx)) idx,
      ];
      if (candidates.isEmpty) continue;

      final int addCount = math.min(remaining, candidates.length);
      for (int k = 0; k < addCount; k++) {
        final int pickIndex = rng.nextInt(candidates.length);
        final int targetIdx = candidates.removeAt(pickIndex);
        final AbstractNode toNode = toLayer[targetIdx];

        final AbstractEdge e = edgeFactory(fromNode, toNode);
        graph.addEdge(e);
        used.add(targetIdx);
      }
    }
  }
  final List<AbstractNode> lastLayer = layerNodes.last;
  if (lastLayer.isNotEmpty) {
    final AbstractNode endNode = EndNode(label: "End");

    double minX = double.infinity;
    double maxX = -double.infinity;

    for (final AbstractNode n in lastLayer) {
      final double left = n.position.dx;
      final double right = left + n.width;
      if (left < minX) minX = left;
      if (right > maxX) maxX = right;
    }

    if (minX == double.infinity) {
      minX = origin.dx;
      maxX = origin.dx;
    }

    final double endCenterX = (minX + maxX) * 0.5;
    final double endY = origin.dy + (layers) * verticalGap + ((jitter > 0) ? (rng.nextDouble() * jitter - jitter * 0.5) : 0.0);
    final double endW = endNode.width;
    final Offset endPos = Offset(endCenterX - (endW * 0.5), endY);
    endNode.setPosition(endPos);
    graph.addNode(endNode);

    for (final AbstractNode fromNode in lastLayer) {
      final AbstractEdge e = edgeFactory(fromNode, endNode);
      graph.addEdge(e);
    }
  }
}
