part of '../graph.dart';


enum TreeOrientation {
  topDown,
  leftRight,
}
class TreeLayout extends AbstractGraphLayout {
  final TreeOrientation orientation;

  TreeLayout({this.orientation = TreeOrientation.topDown});

  @override
  void apply(Graph graph, LayoutOptions options) {
    final List<AbstractNode> nodes = allNodes(graph);
    if (nodes.isEmpty) return;

    final Map<AbstractNode, List<AbstractNode>> outgoing = buildOutgoing(graph);
    final List<AbstractNode> roots = findRoots(graph);


    final Set<AbstractNode> used = <AbstractNode>{};
    final List<_TNode> forest = <_TNode>[];
    for (final AbstractNode r in roots) {
      final _TNode t = _buildTree(r, outgoing, used);
      forest.add(t);
    }

    for (final AbstractNode n in nodes) {
      if (!used.contains(n)) {
        forest.add(_TNode(node: n, children: <_TNode>[]));
      }
    }


    final Map<int, double> levelMaxHeights = <int, double>{};
    for (final _TNode root in forest) {
      _computeSubtreeMetrics(root, depth: 0, hGap: options.hGap, levelMaxHeights: levelMaxHeights);
    }


    final Map<int, double> depthOffset = _accumulateDepthOffsets(
      levelMaxHeights: levelMaxHeights,
      originPrimary: (orientation == TreeOrientation.topDown) ? options.origin.dy + options.padding : options.origin.dx + options.padding,
      vGap: options.vGap,
    );


    double forestCursor = (orientation == TreeOrientation.topDown) ? options.origin.dx + options.padding : options.origin.dy + options.padding;

    for (final _TNode root in forest) {

      _assignPositions(root, leftPrimary: forestCursor, depthOffset: depthOffset, hGap: options.hGap, orientation: orientation);


      forestCursor += root.subtreeWidth + options.hGap;
    }
  }





  _TNode _buildTree(
    AbstractNode root,
    Map<AbstractNode, List<AbstractNode>> outgoing,
    Set<AbstractNode> used, {
    int guardDepth = 0,
    int guardLimit = 100000,
  }) {
    used.add(root);
    final List<_TNode> kids = <_TNode>[];
    if (guardDepth > guardLimit) {
      return _TNode(node: root, children: <_TNode>[]);
    }

    final List<AbstractNode> outs = outgoing[root] ?? const <AbstractNode>[];
    for (final AbstractNode c in outs) {
      if (used.contains(c)) continue;
      final _TNode child = _buildTree(c, outgoing, used, guardDepth: guardDepth + 1, guardLimit: guardLimit);
      kids.add(child);
    }
    return _TNode(node: root, children: kids);
  }





  double _computeSubtreeMetrics(_TNode t, {required int depth, required double hGap, required Map<int, double> levelMaxHeights}) {
    t.depth = depth;

    final Size sz = nodeSize(t.node);
    final double nodeW = sz.width;
    final double nodeH = sz.height;

    final double prevMax = levelMaxHeights[depth] ?? 0.0;
    if (nodeH > prevMax) levelMaxHeights[depth] = nodeH;

    if (t.children.isEmpty) {
      t.subtreeWidth = nodeW;
      return t.subtreeWidth;
    }

    double sumChildren = 0.0;
    for (int i = 0; i < t.children.length; i++) {
      final _TNode ch = t.children[i];
      final double w = _computeSubtreeMetrics(ch, depth: depth + 1, hGap: hGap, levelMaxHeights: levelMaxHeights);
      sumChildren += w;
      if (i < t.children.length - 1) sumChildren += hGap;
    }

    t.subtreeWidth = math.max(nodeW, sumChildren);
    return t.subtreeWidth;
  }




  Map<int, double> _accumulateDepthOffsets({required Map<int, double> levelMaxHeights, required double originPrimary, required double vGap}) {
    final List<int> levels = levelMaxHeights.keys.toList()..sort();
    final Map<int, double> offset = <int, double>{};

    double cursor = originPrimary;
    for (final int d in levels) {
      offset[d] = cursor;
      cursor += levelMaxHeights[d]! + vGap;
    }
    return offset;
  }


  void _assignPositions(
    _TNode t, {
    required double leftPrimary,
    required Map<int, double> depthOffset,
    required double hGap,
    required TreeOrientation orientation,
  }) {
    final Size sz = nodeSize(t.node);
    final double nodeW = sz.width;
    final double nodeH = sz.height;


    final double nodePrimary = leftPrimary + (t.subtreeWidth - nodeW) * 0.5;

    if (orientation == TreeOrientation.topDown) {
      final double x = nodePrimary;
      final double y = depthOffset[t.depth] ?? 0.0;
      t.node.setPosition(Offset(x, y));
    } else {
      final double x = depthOffset[t.depth] ?? 0.0;
      final double y = nodePrimary;
      t.node.setPosition(Offset(x, y));
    }


    double childLeft = leftPrimary;
    for (final _TNode ch in t.children) {
      _assignPositions(ch, leftPrimary: childLeft, depthOffset: depthOffset, hGap: hGap, orientation: orientation);
      childLeft += ch.subtreeWidth + hGap;
    }
  }

}


class _TNode {
  final AbstractNode node;
  final List<_TNode> children;


  late int depth;
  late double subtreeWidth;

  _TNode({required this.node, required this.children});
}
