part of '../graph.dart';

enum RuntimeStopReason {
  reachedEndNode,
  noOutgoingEdge,
  noMatchingBranch,
  missingBranchEdge,
  cycleDetected,
  maxStepsExceeded,
  startNodeNotFound,
  userCancelled,
}

class RuntimeResult {
  final int stepsTaken;
  final int executionTime;
  final List<RuntimeStep> steps;
  final Map<String, dynamic> context;
  final RuntimeStopReason reason;
  final String? message;

  const RuntimeResult({
    required this.steps,
    required this.stepsTaken,
    required this.executionTime,
    required this.context,
    required this.reason,
    this.message,
  });

  AbstractNode? get lastNode => steps.isEmpty ? null : steps.last.node;
  List<AbstractNode> get visitedNodes => steps.map((s) => s.node).toList(growable: false);
  List<AbstractEdge> get traversedEdges =>
      steps.where((s) => s.chosenEdge != null).map((s) => s.chosenEdge!).toList(growable: false);
}