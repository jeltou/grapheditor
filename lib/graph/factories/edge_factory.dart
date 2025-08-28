part of '../graph.dart';


typedef EdgeFactory = AbstractEdge Function(
    Map<String, AbstractNode> nodesById,
    Map<String, dynamic> data,
    );


Map<String, EdgeFactory> defaultEdgeDecoders() {
  return <String, EdgeFactory>{
    'DefaultEdge': (Map<String, AbstractNode> nodes, Map<String, dynamic> m) {
      final String fromId = m['from'] as String? ?? (throw const FormatException('DefaultEdge missing "from"'));
      final String toId   = m['to']   as String? ?? (throw const FormatException('DefaultEdge missing "to"'));

      final AbstractNode from = nodes[fromId] ?? (throw StateError('Unknown node id "$fromId"'));
      final AbstractNode to   = nodes[toId]   ?? (throw StateError('Unknown node id "$toId"'));

      final DefaultEdge e = DefaultEdge(from, to);
      final String? id = m['id'] as String?;
      if (id != null && id.isNotEmpty) {
        (e as dynamic).id = id;
      }
      return e;
    },

    'BranchEdge': (Map<String, AbstractNode> nodes, Map<String, dynamic> m) {
      final String fromId   = m['from'] as String? ?? (throw const FormatException('BranchEdge missing "from"'));
      final String toId     = m['to']   as String? ?? (throw const FormatException('BranchEdge missing "to"'));
      final String fromPort = m['fromPort'] as String? ?? (throw const FormatException('BranchEdge missing "fromPort"'));

      final AbstractNode from = nodes[fromId] ?? (throw StateError('Unknown node id "$fromId"'));
      final AbstractNode to   = nodes[toId]   ?? (throw StateError('Unknown node id "$toId"'));

      final BranchEdge e = BranchEdge(from, to, fromPort: fromPort);
      final String? id = m['id'] as String?;
      if (id != null && id.isNotEmpty) {
        (e as dynamic).id = id;
      }
      return e;
    },
  };
}