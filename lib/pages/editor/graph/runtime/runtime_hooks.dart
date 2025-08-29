part of '../graph.dart';

class RuntimeHooks {
  final bool Function(AbstractNode node, Map<String, dynamic> ctx)? beforeNode;
  final void Function(AbstractNode node, Map<String, dynamic> ctx)? afterNode;
  final AbstractEdge? Function(AbstractNode node, List<AbstractEdge> outgoingDefaults, Map<String, dynamic> ctx)? chooseNextDefaultEdge;

  final void Function(AbstractEdge edge, Map<String, dynamic> ctx)? onEdge;

  const RuntimeHooks({this.beforeNode, this.afterNode, this.chooseNextDefaultEdge, this.onEdge});
}
