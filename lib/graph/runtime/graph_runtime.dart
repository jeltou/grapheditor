part of '../graph.dart';

class _RunCtx {
  AbstractNode current;
  final Map<String, dynamic> ctx;
  final List<RuntimeStep> steps = <RuntimeStep>[];
  final Set<String> visited = <String>{};
  int stepCount = 0;

  _RunCtx({required this.current, required this.ctx});
}

class _StepResult {
  final bool done;
  final RuntimeResult? stop;

  _StepResult.done(this.stop) : done = true;

  const _StepResult.continue_() : done = false, stop = null;
}

class GraphRuntime {
  final Graph graph;
  final int maxSteps;
  final bool allowNodeRevisit;
  final RuntimeHooks hooks;

  GraphRuntime({required this.graph, this.maxSteps = 1000, this.allowNodeRevisit = false, RuntimeHooks? hooks}) : hooks = hooks ?? const RuntimeHooks();

  AbstractNode? _resolveStart(String? startNodeId) {
    if (startNodeId != null) {
      final AbstractNode? n = graph.nodes[startNodeId];
      if (n != null) return n;
    }
    return resolveStartNode(graph);
  }

  _StepResult _stepOnce(_RunCtx s, int stepsTaken, DateTime startTime) {
    if (hooks.beforeNode != null) {
      final bool cont = hooks.beforeNode!(s.current, s.ctx);
      if (!cont) {
        s.steps.add(RuntimeStep(node: s.current, chosenEdge: null));
        return _StepResult.done(RuntimeResult(
          stepsTaken: stepsTaken,
          executionTime: DateTime.now().difference(startTime).inMilliseconds,
          steps: s.steps,
          context: s.ctx,
          reason: RuntimeStopReason.noOutgoingEdge,
          message: 'Stopped by beforeNode hook',
        ));
      }
    }

    if (s.current is EndNode) {
      s.steps.add(RuntimeStep(node: s.current, chosenEdge: null));
      return _StepResult.done(RuntimeResult(
        stepsTaken: stepsTaken,
        executionTime: DateTime.now().difference(startTime).inMilliseconds,
        steps: s.steps,
        context: s.ctx,
        reason: RuntimeStopReason.reachedEndNode,
        message: 'Reached EndNode',
      ));
    }

    if (!allowNodeRevisit) {
      final bool first = s.visited.add(s.current.id);
      if (!first) {
        s.steps.add(RuntimeStep(node: s.current, chosenEdge: null));
        return _StepResult.done(RuntimeResult(
          stepsTaken: stepsTaken,
          executionTime: DateTime.now().difference(startTime).inMilliseconds,
          steps: s.steps,
          context: s.ctx,
          reason: RuntimeStopReason.cycleDetected,
          message: 'Cycle detected at node ${s.current.id}',
        ));
      }
    }

    String? chosenPort;
    if (s.current is ExecutableNode) {
      (s.current as ExecutableNode).executeBefore(s.ctx);
      chosenPort = (s.current as ExecutableNode).choosePort(s.ctx);
    } else if (s.current is DecisionNode) {
      chosenPort = (s.current as DecisionNode).pickBranch(s.ctx);
    }

    hooks.afterNode?.call(s.current, s.ctx);

    final AbstractEdge? edge = _chooseNextEdge(s.current, s.ctx, chosenPort: chosenPort);
    s.steps.add(RuntimeStep(node: s.current, chosenEdge: edge));

    if (s.current is ExecutableNode) {
      (s.current as ExecutableNode).executeAfter(s.ctx, chosenPort: chosenPort);
    }

    if (edge == null) {
      return _StepResult.done(RuntimeResult(
        stepsTaken: stepsTaken,
        executionTime: DateTime.now().difference(startTime).inMilliseconds,
        steps: s.steps,
        context: s.ctx,
        reason: RuntimeStopReason.noOutgoingEdge,
        message: (chosenPort != null)
            ? 'No BranchEdge for port "$chosenPort" from node ${s.current.id}'
            : 'No outgoing edge from node ${s.current.id}',
      ));
    }

    hooks.onEdge?.call(edge, s.ctx);
    s.current = edge.to;
    s.stepCount++;
    return const _StepResult.continue_();
  }



  RuntimeResult run({String? startNodeId, Map<String, dynamic>? context}) {
    final Map<String, dynamic> ctx = context ?? <String, dynamic>{};
    final AbstractNode? start = _resolveStart(startNodeId);
    final DateTime startTime = DateTime.now();
    if (start == null) {
      return RuntimeResult(
        stepsTaken: 0,
        executionTime: DateTime.now().difference(startTime).inMilliseconds,
        steps: const <RuntimeStep>[],
        context: ctx,
        reason: RuntimeStopReason.startNodeNotFound,
        message: 'Start node not found',
      );
    }

    final _RunCtx s = _RunCtx(current: start, ctx: ctx);

    for (int i = 0; i < maxSteps; i++) {
      final _StepResult r = _stepOnce(s, i, startTime);
      if (r.done) return r.stop!;
    }

    return RuntimeResult(
      stepsTaken: maxSteps,
      executionTime: DateTime.now().difference(startTime).inMilliseconds,
      steps: s.steps,
      context: s.ctx,
      reason: RuntimeStopReason.maxStepsExceeded,
      message: 'Exceeded maxSteps=$maxSteps',
    );
  }

  Future<RuntimeResult> runAsync({
    String? startNodeId,
    Map<String, dynamic>? context,
    int yieldEvery = 100,
    Duration yieldFor = Duration.zero,
    bool Function()? shouldCancel,
  }) async {
    final Map<String, dynamic> ctx = context ?? <String, dynamic>{};
    final AbstractNode? start = _resolveStart(startNodeId);
    final DateTime startTime = DateTime.now();
    if (start == null) {
      return RuntimeResult(
        stepsTaken: 0,
        executionTime: DateTime.now().difference(startTime).inMilliseconds,
        steps: const <RuntimeStep>[],
        context: ctx,
        reason: RuntimeStopReason.startNodeNotFound,
        message: 'Start node not found',
      );
    }

    final _RunCtx s = _RunCtx(current: start, ctx: ctx);

    for (int i = 0; i < maxSteps; i++) {
      if (shouldCancel?.call() == true) {
        s.steps.add(RuntimeStep(node: s.current, chosenEdge: null));
        return RuntimeResult(
          stepsTaken: i,
          executionTime: DateTime.now().difference(startTime).inMilliseconds,
          steps: s.steps,
          context: s.ctx,
          reason: RuntimeStopReason.userCancelled,
          message: 'Cancelled by user',
        );
      }

      final _StepResult r = _stepOnce(s, i, startTime);
      if (r.done) return r.stop!;

      if (yieldEvery > 0 && (i % yieldEvery == 0)) {
        await Future<void>.delayed(yieldFor);
      }
    }

    return RuntimeResult(
      stepsTaken: maxSteps,
      executionTime: DateTime.now().difference(startTime).inMilliseconds,
      steps: s.steps,
      context: s.ctx,
      reason: RuntimeStopReason.maxStepsExceeded,
      message: 'Exceeded maxSteps=$maxSteps',
    );
  }

  AbstractEdge? _chooseNextEdge(
      AbstractNode node,
      Map<String, dynamic> ctx, {
        String? chosenPort,
      }) {
    final List<AbstractEdge> outgoing = _outgoing(node);

    if (chosenPort != null) {
      for (final AbstractEdge e in outgoing) {
        if (e is BranchEdge && identical(e.from, node) && e.fromPort == chosenPort) {
          return e;
        }
      }
      return null;
    }

    if (node is DecisionNode) {
      final String? port = node.pickBranch(ctx);
      if (port == null) return null;
      for (final AbstractEdge e in outgoing) {
        if (e is BranchEdge && identical(e.from, node) && e.fromPort == port) return e;
      }
      return null;
    }

    final List<AbstractEdge> defaults = <AbstractEdge>[
      for (final AbstractEdge e in outgoing) if (e is! BranchEdge) e,
    ];

    if (defaults.isEmpty) return null;
    if (defaults.length == 1) return defaults.first;

    if (hooks.chooseNextDefaultEdge != null) {
      return hooks.chooseNextDefaultEdge!(node, defaults, ctx);
    }
    defaults.sort((a, b) => a.id.compareTo(b.id));
    return defaults.first;
  }

  List<AbstractEdge> _outgoing(AbstractNode node) {
    final List<AbstractEdge> out = <AbstractEdge>[];
    for (final AbstractEdge e in graph.edges.values) {
      if (identical(e.from, node)) out.add(e);
    }
    return out;
  }
}
