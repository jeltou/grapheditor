part of '../../graph.dart';

class JsonGraphConverter implements GraphConverterInterface {
  final Map<String, NodeFactory> nodeDecoders;
  final Map<String, EdgeFactory> edgeDecoders;

  JsonGraphConverter({Map<String, NodeFactory>? nodeDecoders, Map<String, EdgeFactory>? edgeDecoders})
    : nodeDecoders = nodeDecoders ?? defaultNodeDecoders(),
      edgeDecoders = edgeDecoders ?? defaultEdgeDecoders();



  @override
  String graphToFormat(Graph graph) {
    final List<Map<String, dynamic>> nodes = <Map<String, dynamic>>[];
    graph.nodes.forEach((String id, AbstractNode node) {
      final Map<String, dynamic> m = Map<String, dynamic>.from(node.toMap());
      nodes.add(m);
    });

    final List<Map<String, dynamic>> edges = <Map<String, dynamic>>[];
    graph.edges.forEach((String id, AbstractEdge edge) {
      if (edge is BranchEdge) {
        edges.add(<String, dynamic>{'edgeType': 'BranchEdge', 'id': id, 'from': edge.from.id, 'to': edge.to.id, 'fromPort': edge.fromPort});
      } else if (edge is DefaultEdge) {
        edges.add(<String, dynamic>{'edgeType': 'DefaultEdge', 'id': id, 'from': edge.from.id, 'to': edge.to.id});
      } else {
        edges.add(<String, dynamic>{'edgeType': edge.runtimeType.toString(), 'id': id, 'from': edge.from.id, 'to': edge.to.id});
      }
    });

    final List<Map<String, dynamic>> contexts = <Map<String, dynamic>>[for (final TestContext c in graph.testsContexts.values) c.toMap()];

    final Map<String, dynamic> root = <String, dynamic>{
      'format': 'graph.v1',
      'version': 1,
      'nodes': nodes,
      'edges': edges,
      'meta': <String, dynamic>{...graph.getMeta(), 'exportedAt': DateTime.now().toIso8601String()},
      'testContexts': contexts,
    };

    return const JsonEncoder.withIndent('  ').convert(root);
  }

  @override
  Graph formatToGraph(String data) {
    final dynamic decoded = jsonDecode(data);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('JSON root must be an object.');
    }

    final String? format = decoded['format'] as String?;
    final int? version = decoded['version'] as int?;

    final List<dynamic> nodesRaw = (decoded['nodes'] as List?) ?? const <dynamic>[];
    final List<dynamic> edgesRaw = (decoded['edges'] as List?) ?? const <dynamic>[];
    final Map meta = (decoded['meta'] as Map?) ?? {};
    final List<dynamic> textCtxRaw = (decoded['testContexts'] as List?) ?? const <dynamic>[];

    final Graph g = Graph();
    final Map<String, AbstractNode> nodesById = <String, AbstractNode>{};


    for (final dynamic e in nodesRaw) {
      if (e is! Map<String, dynamic>) continue;
      final Map<String, dynamic> m = e;

      final String nodeType = (m['nodeType'] as String?) ?? 'DefaultNode';
      final NodeFactory? factory = nodeDecoders[nodeType] ?? nodeDecoders['DefaultNode'];
      if (factory == null) continue;

      final AbstractNode node = _buildNodeFromMap(factory, m);
      g.addNode(node);
      nodesById[node.id] = node;
    }

    for (final dynamic e in edgesRaw) {
      if (e is! Map<String, dynamic>) continue;
      final Map<String, dynamic> m = e;

      final String edgeType = (m['edgeType'] as String?) ?? 'DefaultEdge';
      final EdgeFactory? ef = edgeDecoders[edgeType];

      if (ef != null) {
        try {
          final AbstractEdge edge = ef(nodesById, m);
          g.addEdge(edge);
        } catch (err, st) {
          dPrint(err);
          dPrint(st);
        }
      } else {
        final String? fromId = m['from'] as String?;
        final String? toId = m['to'] as String?;
        if (fromId == null || toId == null) continue;

        final AbstractNode? from = nodesById[fromId];
        final AbstractNode? to = nodesById[toId];
        if (from == null || to == null) continue;

        final DefaultEdge edge = DefaultEdge(from, to);
        final String? id = m['id'] as String?;
        if (id != null && id.isNotEmpty) {
          (edge as dynamic).id = id;
        }
        g.addEdge(edge);
      }
    }

    for (final dynamic e in textCtxRaw) {
      if (e is! Map<String, dynamic>) continue;
      final TestContext ctx = TestContext.fromMap(e);
      g.insertTestContext(ctx);
    }

    if (meta is Map<String, dynamic>) {
      meta.forEach((key, value) => g.addMeta(key, value));
    }

    return g;
  }

  AbstractNode _buildNodeFromMap(NodeFactory factory, Map<String, dynamic> m) {
    final AbstractNode node = factory(m);

    final String? id = m['id'] as String?;
    if (id != null && id.isNotEmpty) {
      (node as dynamic).id = id;
    }


    final Map<String, dynamic>? pos = m['position'] as Map<String, dynamic>?;
    final double? x = _toDouble(pos?['x'] ?? pos?['dx'] ?? m['x']);
    final double? y = _toDouble(pos?['y'] ?? pos?['dy'] ?? m['y']);
    if (x != null && y != null) {
      node.setPosition(Offset(x, y));
    }


    final Map<String, dynamic>? size = m['size'] as Map<String, dynamic>?;
    final double? w = _toDouble(size?['width'] ?? m['width']);
    final double? h = _toDouble(size?['height'] ?? m['height']);
    if (w != null) (node as dynamic).width = w;
    if (h != null) (node as dynamic).height = h;

    return node;
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  @override
  List<String> getFileExtensions() => const <String>['json', 'jgraph'];
}
