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

  _StepResult _stop(_RunCtx s, int stepsTaken, DateTime t0, {required RuntimeStopReason reason, required String message}) {
    return _StepResult.done(
      RuntimeResult(
        stepsTaken: stepsTaken,
        executionTime: DateTime.now().difference(t0).inMilliseconds,
        steps: s.steps,
        context: s.ctx,
        reason: reason,
        message: message,
      ),
    );
  }

  bool _isEnd(AbstractNode n) => n is EndNode;

  AbstractEdge? _chooseNextEdge(AbstractNode node, Map<String, dynamic> ctx, {String? chosenPort}) {
    final List<AbstractEdge> outgoing = _outgoing(node);

    if (chosenPort != null) {
      for (final AbstractEdge e in outgoing) {
        if (e is BranchEdge && identical(e.from, node) && e.fromPort == chosenPort) return e;
      }
      return null;
    }

    // DecisionNode: Port via pickBranch
    if (node is DecisionNode) {
      final String? port = node.pickBranch(ctx);
      if (port == null) return null;
      for (final AbstractEdge e in outgoing) {
        if (e is BranchEdge && identical(e.from, node) && e.fromPort == port) return e;
      }
      return null;
    }

    // Default-Edges
    final List<AbstractEdge> defaults = <AbstractEdge>[
      for (final AbstractEdge e in outgoing)
        if (e is! BranchEdge) e,
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

  _StepResult _stepOnceSync(_RunCtx s, int stepsTaken, DateTime t0) {
    // beforeNode-Hook
    if (hooks.beforeNode != null && !hooks.beforeNode!(s.current, s.ctx)) {
      s.steps.add(RuntimeStep(node: s.current, chosenEdge: null));
      return _stop(s, stepsTaken, t0, reason: RuntimeStopReason.noOutgoingEdge, message: 'Stopped by beforeNode hook');
    }

    // Executable (sync) pre
    if (s.current is ExecutableNode) {
      (s.current as ExecutableNode).executeBefore(s.ctx);
    }

    // End?
    if (_isEnd(s.current)) {
      s.steps.add(RuntimeStep(node: s.current, chosenEdge: null));
      return _stop(s, stepsTaken, t0, reason: RuntimeStopReason.reachedEndNode, message: 'Reached EndNode');
    }

    // Cycle?
    if (!allowNodeRevisit) {
      final bool first = s.visited.add(s.current.id);
      if (!first) {
        s.steps.add(RuntimeStep(node: s.current, chosenEdge: null));
        return _stop(s, stepsTaken, t0, reason: RuntimeStopReason.cycleDetected, message: 'Cycle detected at node ${s.current.id}');
      }
    }

    // afterNode-Hook
    hooks.afterNode?.call(s.current, s.ctx);

    String? chosenPort;
    if (s.current is ChoosePortNode) {
      chosenPort = (s.current as ChoosePortNode).choosePort(s.ctx);
    }

    // Edge wählen
    final AbstractEdge? edge = _chooseNextEdge(s.current, s.ctx, chosenPort: chosenPort);
    s.steps.add(RuntimeStep(node: s.current, chosenEdge: edge));

    if (edge == null) {
      return _stop(
        s,
        stepsTaken,
        t0,
        reason: RuntimeStopReason.noOutgoingEdge,
        message: (chosenPort != null) ? 'No BranchEdge for port "$chosenPort" from node ${s.current.id}' : 'No outgoing edge from node ${s.current.id}',
      );
    }

    // onEdge
    hooks.onEdge?.call(edge, s.ctx);

    // Executable (sync) post
    if (s.current is ExecutableNode) {
      (s.current as ExecutableNode).executeAfter(s.ctx, chosenPort: chosenPort);
    }

    s.current = edge.to;
    s.stepCount++;
    return const _StepResult.continue_();
  }

  // ---- EIN SCHRITT: ASYNC ---------------------------------------------------

  Future<_StepResult> _stepOnceAsync(_RunCtx s, int stepsTaken, DateTime t0) async {
    if (hooks.beforeNode != null && !hooks.beforeNode!(s.current, s.ctx)) {
      s.steps.add(RuntimeStep(node: s.current, chosenEdge: null));
      return _stop(s, stepsTaken, t0, reason: RuntimeStopReason.noOutgoingEdge, message: 'Stopped by beforeNode hook');
    }

    // sync + async pre
    if (s.current is AsyncExecutableNode) {
      await (s.current as AsyncExecutableNode).executeBeforeAsync(s.ctx);
    } else if (s.current is ExecutableNode && s.current is! AsyncExecutableNode) {
      (s.current as ExecutableNode).executeBefore(s.ctx);
    }

    if (_isEnd(s.current)) {
      s.steps.add(RuntimeStep(node: s.current, chosenEdge: null));
      return _stop(s, stepsTaken, t0, reason: RuntimeStopReason.reachedEndNode, message: 'Reached EndNode');
    }

    if (!allowNodeRevisit) {
      final bool first = s.visited.add(s.current.id);
      if (!first) {
        s.steps.add(RuntimeStep(node: s.current, chosenEdge: null));
        return _stop(s, stepsTaken, t0, reason: RuntimeStopReason.cycleDetected, message: 'Cycle detected at node ${s.current.id}');
      }
    }

    hooks.afterNode?.call(s.current, s.ctx);

    String? chosenPort;
    if (s.current is ChoosePortNode) {
      chosenPort = (s.current as ChoosePortNode).choosePort(s.ctx);
    }

    final AbstractEdge? edge = _chooseNextEdge(s.current, s.ctx, chosenPort: chosenPort);
    s.steps.add(RuntimeStep(node: s.current, chosenEdge: edge));

    if (edge == null) {
      return _stop(
        s,
        stepsTaken,
        t0,
        reason: RuntimeStopReason.noOutgoingEdge,
        message: (chosenPort != null) ? 'No BranchEdge for port "$chosenPort" from node ${s.current.id}' : 'No outgoing edge from node ${s.current.id}',
      );
    }

    hooks.onEdge?.call(edge, s.ctx);

    // sync + async post
    if (s.current is AsyncExecutableNode) {
      await (s.current as AsyncExecutableNode).executeAfterAsync(s.ctx, chosenPort: chosenPort);
    } else if (s.current is ExecutableNode && s is! AsyncExecutableNode) {
      (s.current as ExecutableNode).executeAfter(s.ctx, chosenPort: chosenPort);
    }

    s.current = edge.to;
    s.stepCount++;
    return const _StepResult.continue_();
  }

  // ----------------- SYNC API -----------------
  RuntimeResult run({String? startNodeId, Map<String, dynamic>? context}) {
    final Map<String, dynamic> ctx = context ?? <String, dynamic>{};
    final AbstractNode? start = _resolveStart(startNodeId);
    final DateTime t0 = DateTime.now();
    if (start == null) {
      return RuntimeResult(
        stepsTaken: 0,
        executionTime: DateTime.now().difference(t0).inMilliseconds,
        steps: const <RuntimeStep>[],
        context: ctx,
        reason: RuntimeStopReason.startNodeNotFound,
        message: 'Start node not found',
      );
    }

    final _RunCtx s = _RunCtx(current: start, ctx: ctx);

    for (int i = 0; i < maxSteps; i++) {
      final _StepResult r = _stepOnceSync(s, i, t0);
      if (r.done) return r.stop!;
    }

    return RuntimeResult(
      stepsTaken: maxSteps,
      executionTime: DateTime.now().difference(t0).inMilliseconds,
      steps: s.steps,
      context: s.ctx,
      reason: RuntimeStopReason.maxStepsExceeded,
      message: 'Exceeded maxSteps=$maxSteps',
    );
  }

  // --------------- ASYNC API -----------------
  Future<RuntimeResult> runAsync({
    String? startNodeId,
    Map<String, dynamic>? context,
    int yieldEvery = 100,
    Duration yieldFor = Duration.zero,
    bool Function()? shouldCancel,
  }) async {
    final Map<String, dynamic> ctx = context ?? <String, dynamic>{};
    final AbstractNode? start = _resolveStart(startNodeId);
    final DateTime t0 = DateTime.now();
    if (start == null) {
      return RuntimeResult(
        stepsTaken: 0,
        executionTime: DateTime.now().difference(t0).inMilliseconds,
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
          executionTime: DateTime.now().difference(t0).inMilliseconds,
          steps: s.steps,
          context: s.ctx,
          reason: RuntimeStopReason.userCancelled,
          message: 'Cancelled by user',
        );
      }

      final _StepResult r = await _stepOnceAsync(s, i, t0);
      if (r.done) return r.stop!;

      if (yieldEvery > 0 && (i % yieldEvery == 0)) {
        // UI atmen lassen
        await Future<void>.delayed(yieldFor);
      }
    }

    return RuntimeResult(
      stepsTaken: maxSteps,
      executionTime: DateTime.now().difference(t0).inMilliseconds,
      steps: s.steps,
      context: s.ctx,
      reason: RuntimeStopReason.maxStepsExceeded,
      message: 'Exceeded maxSteps=$maxSteps',
    );
  }
}
