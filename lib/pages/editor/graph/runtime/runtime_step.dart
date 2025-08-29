part of '../graph.dart';


class RuntimeStep {
  final AbstractNode node;
  final AbstractEdge? chosenEdge;

  const RuntimeStep({required this.node, this.chosenEdge});
}

