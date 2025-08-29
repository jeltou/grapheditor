part of '../graph.dart';

class PathFrame {
  final AbstractNode node;
  final List<AbstractNode> nodes;
  final List<AbstractEdge> edges;
  final Map<String, int> visits;
  final int steps;
  final Map<String, dynamic>? ctx;

  PathFrame({required this.node, required this.nodes, required this.edges, required this.visits, required this.steps, required this.ctx});
}

class RoutePath {
  final List<AbstractNode> nodes;
  final List<AbstractEdge> edges;
  final RouteStopReason reason;
  final String? message;
  final Map<String, dynamic>? ctx;

  const RoutePath({required this.nodes, required this.edges, required this.reason, this.message, required this.ctx});
}

extension GraphRuntimeAllRoutes on GraphRuntime {
  Map<String, dynamic> _cloneCtx(Map<String, dynamic> ctx) {
    try {
      return jsonDecode(jsonEncode(ctx)) as Map<String, dynamic>;
    } catch (_) {
      return Map<String, dynamic>.from(ctx);
    }
  }

  Future<void> _execBeforeAsyncIfEnabled(AbstractNode n, Map<String, dynamic> ctx, bool includeExecution) async {
    if (!includeExecution) return;
    if (n is AsyncExecutableNode) {
      await (n as AsyncExecutableNode).executeBeforeAsync(ctx);
    } else if (n is ExecutableNode) {
      (n as ExecutableNode).executeBefore(ctx);
    }
  }

  void _execBeforeSyncIfEnabled(AbstractNode n, Map<String, dynamic> ctx, bool includeExecution) {
    if (!includeExecution) return;
    if (n is ExecutableNode && n is! AsyncExecutableNode) {
      (n as ExecutableNode).executeBefore(ctx);
    }
  }

  Future<void> _execAfterAsyncIfEnabled(AbstractNode n, Map<String, dynamic> ctx, bool includeExecution, {String? chosenPort}) async {
    if (!includeExecution) return;
    if (n is AsyncExecutableNode) {
      await (n as AsyncExecutableNode).executeAfterAsync(ctx, chosenPort: chosenPort);
    } else if (n is ExecutableNode) {
      (n as ExecutableNode).executeAfter(ctx, chosenPort: chosenPort);
    }
  }

  void _execAfterSyncIfEnabled(AbstractNode n, Map<String, dynamic> ctx, bool includeExecution, {String? chosenPort}) {
    if (!includeExecution) return;
    if (n is ExecutableNode && n is! AsyncExecutableNode) {
      (n as ExecutableNode).executeAfter(ctx, chosenPort: chosenPort);
    }
  }

  String? _choosePortIfAny(AbstractNode n, Map<String, dynamic> ctx) {
    if (n is ChoosePortNode) return (n as ChoosePortNode).choosePort(ctx);
    return null;
  }

  List<AbstractEdge> _routingCandidates(AbstractNode node, {String? forcedPort}) {
    final List<AbstractEdge> outs = _outgoing(node);
    if (forcedPort != null) {
      return <AbstractEdge>[
        for (final AbstractEdge e in outs)
          if (e is BranchEdge && identical(e.from, node) && e.fromPort == forcedPort) e,
      ];
    }
    final bool hasBranches = outs.any((AbstractEdge e) => e is BranchEdge);
    if (hasBranches) {
      return <AbstractEdge>[
        for (final AbstractEdge e in outs)
          if (e is BranchEdge) e,
      ];
    }
    return <AbstractEdge>[
      for (final AbstractEdge e in outs)
        if (e is! BranchEdge) e,
    ];
  }

  AllRoutesResult calcAllRoutesSync({
    String? startNodeId,
    Map<String, dynamic>? context,
    bool structuralOnly = true,
    bool includeExecution = false,
    int maxPaths = 5000,
    int maxStepsPerPath = 2000,
    int maxVisitsPerNode = 1,
    bool includeContextSnapshots = false,
  }) {
    final AbstractNode? start = _resolveStart(startNodeId);
    if (start == null) {
      return const AllRoutesResult(paths: <RoutePath>[], truncated: false, exploredPaths: 0);
    }

    final Map<String, dynamic> baseCtx = context ?? <String, dynamic>{};

    final List<RoutePath> paths = <RoutePath>[];
    bool truncated = false;
    int explored = 0;

    final PathFrame startF = PathFrame(
      node: start,
      nodes: <AbstractNode>[start],
      edges: <AbstractEdge>[],
      visits: <String, int>{start.id: 1},
      steps: 0,
      ctx: structuralOnly ? null : _cloneCtx(baseCtx),
    );

    final List<PathFrame> stack = <PathFrame>[startF];

    while (stack.isNotEmpty) {
      if (paths.length >= maxPaths) {
        truncated = true;
        break;
      }

      final PathFrame f = stack.removeLast();

      if (!structuralOnly && includeExecution && f.ctx != null) {
        _execBeforeSyncIfEnabled(f.node, f.ctx!, true);
      }

      if (isEnd(f.node)) {
        paths.add(
          RoutePath(
            nodes: f.nodes,
            edges: f.edges,
            reason: RouteStopReason.reachedEndNode,
            message: 'Reached EndNode',
            ctx: includeContextSnapshots ? _cloneCtx(f.ctx ?? {}) : null,
          ),
        );
        explored++;
        continue;
      }

      if (f.steps >= maxStepsPerPath) {
        paths.add(
          RoutePath(
            nodes: f.nodes,
            edges: f.edges,
            reason: RouteStopReason.maxStepsExceeded,
            message: 'Max steps per path exceeded',
            ctx: includeContextSnapshots ? _cloneCtx(f.ctx ?? {}) : null,
          ),
        );
        explored++;
        continue;
      }

      String? forcedPort;
      if (!structuralOnly && f.ctx != null) {
        forcedPort = _choosePortIfAny(f.node, f.ctx!);
      }

      final List<AbstractEdge> cand = _routingCandidates(f.node, forcedPort: forcedPort);
      if (cand.isEmpty) {
        paths.add(
          RoutePath(
            nodes: f.nodes,
            edges: f.edges,
            reason: RouteStopReason.deadEnd,
            message: forcedPort != null ? 'No BranchEdge for port "$forcedPort"' : 'No outgoing edge',
            ctx: includeContextSnapshots ? _cloneCtx(f.ctx ?? {}) : null,
          ),
        );
        explored++;
        continue;
      }

      for (final AbstractEdge e in cand) {
        final AbstractNode next = e.to;

        final Map<String, int> visits2 = Map<String, int>.from(f.visits);
        final int newCount = (visits2[next.id] ?? 0) + 1;
        if (newCount > maxVisitsPerNode) {
          paths.add(
            RoutePath(
              nodes: <AbstractNode>[...f.nodes, next],
              edges: <AbstractEdge>[...f.edges, e],
              reason: RouteStopReason.maxVisitsExceeded,
              message: 'Node ${next.id} visited too often',
              ctx: includeContextSnapshots ? _cloneCtx(f.ctx ?? {}) : null,
            ),
          );
          explored++;
          continue;
        }
        visits2[next.id] = newCount;

        if (!structuralOnly && includeExecution && f.ctx != null) {
          _execAfterSyncIfEnabled(f.node, f.ctx!, true, chosenPort: forcedPort);
        }

        stack.add(
          PathFrame(
            node: next,
            nodes: <AbstractNode>[...f.nodes, next],
            edges: <AbstractEdge>[...f.edges, e],
            visits: visits2,
            steps: f.steps + 1,
            ctx: structuralOnly ? null : _cloneCtx(f.ctx ?? baseCtx),
          ),
        );
      }
    }

    return AllRoutesResult(paths: paths, truncated: truncated, exploredPaths: explored);
  }

  Future<AllRoutesResult> calcAllRoutesAsync({
    String? startNodeId,
    Map<String, dynamic>? context,
    bool structuralOnly = true,
    bool includeExecution = false,
    int maxPaths = 5000,
    int maxStepsPerPath = 2000,
    int maxVisitsPerNode = 1,
    bool includeContextSnapshots = false,
  }) async {
    final AbstractNode? start = _resolveStart(startNodeId);
    if (start == null) {
      return const AllRoutesResult(paths: <RoutePath>[], truncated: false, exploredPaths: 0);
    }

    final Map<String, dynamic> baseCtx = context ?? <String, dynamic>{};

    final List<RoutePath> paths = <RoutePath>[];
    bool truncated = false;
    int explored = 0;
    final List<PathFrame> stack = <PathFrame>[
      PathFrame(
        node: start,
        nodes: <AbstractNode>[start],
        edges: <AbstractEdge>[],
        visits: <String, int>{start.id: 1},
        steps: 0,
        ctx: structuralOnly ? null : _cloneCtx(baseCtx),
      ),
    ];

    while (stack.isNotEmpty) {
      if (paths.length >= maxPaths) {
        truncated = true;
        break;
      }

      final PathFrame f = stack.removeLast();

      if (!structuralOnly && includeExecution && f.ctx != null) {
        await _execBeforeAsyncIfEnabled(f.node, f.ctx!, true);
      }

      if (isEnd(f.node)) {
        paths.add(
          RoutePath(
            nodes: f.nodes,
            edges: f.edges,
            reason: RouteStopReason.reachedEndNode,
            message: 'Reached EndNode',
            ctx: includeContextSnapshots ? _cloneCtx(f.ctx ?? {}) : null,
          ),
        );
        explored++;
        continue;
      }

      if (f.steps >= maxStepsPerPath) {
        paths.add(
          RoutePath(
            nodes: f.nodes,
            edges: f.edges,
            reason: RouteStopReason.maxStepsExceeded,
            message: 'Max steps per path exceeded',
            ctx: includeContextSnapshots ? _cloneCtx(f.ctx ?? {}) : null,
          ),
        );
        explored++;
        continue;
      }

      String? forcedPort;
      if (!structuralOnly && f.ctx != null) {
        forcedPort = _choosePortIfAny(f.node, f.ctx!);
      }

      final List<AbstractEdge> cand = _routingCandidates(f.node, forcedPort: forcedPort);
      if (cand.isEmpty) {
        paths.add(
          RoutePath(
            nodes: f.nodes,
            edges: f.edges,
            reason: RouteStopReason.deadEnd,
            message: forcedPort != null ? 'No BranchEdge for port "$forcedPort"' : 'No outgoing edge',
            ctx: includeContextSnapshots ? _cloneCtx(f.ctx ?? {}) : null,
          ),
        );
        explored++;
        continue;
      }

      for (final AbstractEdge e in cand) {
        final AbstractNode next = e.to;

        final Map<String, int> visits2 = Map<String, int>.from(f.visits);
        final int newCount = (visits2[next.id] ?? 0) + 1;
        if (newCount > maxVisitsPerNode) {
          paths.add(
            RoutePath(
              nodes: <AbstractNode>[...f.nodes, next],
              edges: <AbstractEdge>[...f.edges, e],
              reason: RouteStopReason.maxVisitsExceeded,
              message: 'Node ${next.id} visited too often',
              ctx: includeContextSnapshots ? _cloneCtx(f.ctx ?? {}) : null,
            ),
          );
          explored++;
          continue;
        }
        visits2[next.id] = newCount;

        if (!structuralOnly && includeExecution && f.ctx != null) {
          await _execAfterAsyncIfEnabled(f.node, f.ctx!, true, chosenPort: forcedPort);
        }

        stack.add(
          PathFrame(
            node: next,
            nodes: <AbstractNode>[...f.nodes, next],
            edges: <AbstractEdge>[...f.edges, e],
            visits: visits2,
            steps: f.steps + 1,
            ctx: structuralOnly ? null : _cloneCtx(f.ctx ?? baseCtx),
          ),
        );
      }
    }

    return AllRoutesResult(paths: paths, truncated: truncated, exploredPaths: explored);
  }
}
