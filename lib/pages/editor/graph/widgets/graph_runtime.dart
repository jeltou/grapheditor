part of '../graph.dart';

// --- NEU: Modus-Enum bleibt unverändert ---
enum _RuntimeMode { run, routes }

class GraphRuntimeDialog extends StatefulWidget {
  final Graph graph;
  final String? startNodeId;

  const GraphRuntimeDialog({super.key, required this.graph, this.startNodeId});

  @override
  State<GraphRuntimeDialog> createState() => _GraphRuntimeDialogState();
}

class _GraphRuntimeDialogState extends State<GraphRuntimeDialog> {
  bool _isRunning = false;
  bool _cancelRequested = false;

  // Run-Options
  final TextEditingController _maxStepsCtrl = TextEditingController(text: '1000');
  bool _allowNodeRevisit = true;

  // Routes-Options
  final TextEditingController _maxPathsCtrl = TextEditingController(text: '200');
  final TextEditingController _maxStepsPerPathCtrl = TextEditingController(text: '500');
  final TextEditingController _maxVisitsPerNodeCtrl = TextEditingController(text: '1');
  bool _routesStructuralOnly = true;
  bool _routesIncludeExec = false;
  bool _routesIncludeContext = false; // <-- NEU

  // Editor / stdout
  late final TextEditingController _ctxCtrl;
  late final TextEditingController _outCtrl;
  late final ScrollController _stdoutScroll;
  final List<String> _stdout = <String>[];
  final List<String> _stdoutBuffer = <String>[];
  Timer? _stdoutFlushTimer;
  static const int _stdoutFlushIntervalMs = 50;
  static const int _stdoutMaxLines = 2000;

  // Tests
  String? _ctxError;
  String? _selectedTestId;

  _RuntimeMode _mode = _RuntimeMode.run;

  @override
  void initState() {
    super.initState();
    _ctxCtrl = TextEditingController(text: _exampleContextJson());
    _outCtrl = TextEditingController(text: '');
    _stdoutScroll = ScrollController();

    if (widget.graph.testsContexts.isNotEmpty) {
      _selectedTestId = widget.graph.testsContexts.values.first.id;
    }
  }

  @override
  void dispose() {
    _stdoutFlushTimer?.cancel();
    _ctxCtrl.dispose();
    _outCtrl.dispose();
    _stdoutScroll.dispose();
    _maxStepsCtrl.dispose();
    _maxPathsCtrl.dispose();
    _maxStepsPerPathCtrl.dispose();
    _maxVisitsPerNodeCtrl.dispose();
    super.dispose();
  }

  TextStyle get _mono => const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.3);

  String _exampleContextJson() => const JsonEncoder.withIndent('  ').convert(<String, Object>{"value": 1});

  void _appendStdout(String line) {
    _stdoutBuffer.add(line);
    _stdoutFlushTimer ??= Timer(const Duration(milliseconds: _stdoutFlushIntervalMs), _flushStdout);
  }

  void _flushStdout() {
    _stdoutFlushTimer?.cancel();
    _stdoutFlushTimer = null;
    if (!mounted || _stdoutBuffer.isEmpty) return;
    bool stickToBottom = false;
    if (_stdoutScroll.hasClients) {
      final pos = _stdoutScroll.position;
      stickToBottom = (pos.maxScrollExtent - pos.pixels) < 80;
    }
    setState(() {
      _stdout.addAll(_stdoutBuffer);
      _stdoutBuffer.clear();
      if (_stdout.length > _stdoutMaxLines) {
        _stdout.removeRange(0, _stdout.length - _stdoutMaxLines);
      }
    });
    if (stickToBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_stdoutScroll.hasClients) {
          _stdoutScroll.jumpTo(_stdoutScroll.position.maxScrollExtent);
        }
      });
    }
  }

  Map<String, dynamic>? _parseContext() {
    try {
      final dynamic decoded = jsonDecode(_ctxCtrl.text);
      if (decoded is Map<String, dynamic>) {
        setState(() => _ctxError = null);
        return decoded;
      }
      setState(() => _ctxError = 'JSON root must be an object (Map).');
      return null;
    } catch (e) {
      setState(() => _ctxError = 'Invalid JSON: $e');
      return null;
    }
  }

  String _prettyJson(Object? value) => const JsonEncoder.withIndent('  ').convert(value);

  void _formatContext() {
    final Map<String, dynamic>? ctx = _parseContext();
    if (ctx != null) _ctxCtrl.text = _prettyJson(ctx);
  }

  void _loadSelectedTest() {
    if (_selectedTestId == null) return;
    final TestContext? t = widget.graph.testsContexts[_selectedTestId!];
    if (t != null) {
      setState(() {
        _ctxCtrl.text = t.json;
        _ctxError = null;
      });
    }
  }

  Future<void> _saveTestAsNew() async {
    final String? name = await _askName(context, title: 'Save test as…', initial: 'Test', hintText: 'Enter test name');
    if (name == null || name.trim().isEmpty) return;
    final TestContext t = widget.graph.createTestContextFromRaw(id: null, name: name.trim(), json: _ctxCtrl.text);
    setState(() => _selectedTestId = t.id);
  }

  Future<void> _overwriteSelectedTest() async {
    if (_selectedTestId == null) return;
    final TestContext? t = widget.graph.testsContexts[_selectedTestId!];
    if (t == null) return;
    setState(() => t.json = _ctxCtrl.text);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test overwritten')));
  }

  void _deleteSelectedTest() {
    if (_selectedTestId == null) return;
    widget.graph.removeTestContextById(_selectedTestId!);
    setState(() => _selectedTestId = null);
  }

  int _coerceInt(TextEditingController c, int def, {required int min, required int max}) {
    final int? v = int.tryParse(c.text.trim());
    if (v == null) return def;
    return v.clamp(min, max);
  }

  int _coerceMaxSteps() => _coerceInt(_maxStepsCtrl, 1000, min: 1, max: 100000000);

  // ----------------- RUN -----------------
  Future<void> _run() async {
    if (_isRunning) return;
    setState(() {
      _stdout.clear();
      _stdoutBuffer.clear();
      _outCtrl.clear();
      _cancelRequested = false;
      _isRunning = true;
    });
    _appendStdout('== RUN ==');
    _flushStdout();

    final Map<String, dynamic>? ctx = _parseContext();
    if (ctx == null) {
      _appendStdout('Context parse failed.');
      _flushStdout();
      setState(() => _isRunning = false);
      return;
    }

    final GraphRuntime rt = GraphRuntime(
      graph: widget.graph,
      maxSteps: _coerceMaxSteps(),
      allowNodeRevisit: _allowNodeRevisit,
      hooks: RuntimeHooks(
        beforeNode: (n, c) {
          _appendStdout('→ Node ${n.runtimeType}(${n.id})');
          return true;
        },
        afterNode: (n, c) {},
        onEdge: (e, c) {
          if (e is BranchEdge) {
            _appendStdout('  use BranchEdge ${e.id} [${e.fromPort}]');
          } else {
            _appendStdout('  use Edge ${e.id}');
          }
        },
        chooseNextDefaultEdge: (n, outs, c) {
          outs.sort((a, b) => a.id.compareTo(b.id));
          return outs.first;
        },
      ),
    );

    try {
      final RuntimeResult res = await rt.runAsync(
        startNodeId: widget.startNodeId,
        context: ctx,
        yieldEvery: 250,
        yieldFor: const Duration(milliseconds: 1),
        shouldCancel: () => _cancelRequested,
      );

      _appendStdout('== STOP == (${res.reason.name}) ${res.message ?? ''}');
      _flushStdout();

      final Map<String, Object?> out = <String, Object?>{
        'reason': res.reason.name,
        'message': res.message,
        'lastNodeId': res.lastNode?.id,
        'stepsTaken': res.stepsTaken,
        'executionTime': res.executionTime,
        'context': res.context,
      };
      setState(() => _outCtrl.text = _prettyJson(out));
    } catch (e, st) {
      _appendStdout('Runtime error: $e');
      _flushStdout();
      debugPrintStack(stackTrace: st);
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  // -------------- ALL ROUTES (mit Context-Snapshots) --------------
  Future<void> _calcRoutes() async {
    if (_isRunning) return;
    setState(() {
      _stdout.clear();
      _stdoutBuffer.clear();
      _outCtrl.clear();
      _cancelRequested = false;
      _isRunning = true;
    });
    _appendStdout('== CALC ALL ROUTES ==');
    _flushStdout();

    final Map<String, dynamic>? ctx = _parseContext();
    if (!_routesStructuralOnly && ctx == null) {
      _appendStdout('Context parse failed (needed for context-aware routes).');
      _flushStdout();
      setState(() => _isRunning = false);
      return;
    }

    // Wenn Context-Snapshots gewünscht, Ausführung erzwingen:
    if (_routesIncludeContext && !_routesIncludeExec) {
      setState(() => _routesIncludeExec = true);
    }

    final GraphRuntime rt = GraphRuntime(graph: widget.graph);

    try {
      final AllRoutesResult res = await rt.calcAllRoutesAsync(
        startNodeId: widget.startNodeId,
        context: ctx ?? <String, dynamic>{},
        structuralOnly: _routesStructuralOnly,
        includeExecution: _routesIncludeExec && !_routesStructuralOnly,
        includeContextSnapshots: _routesIncludeContext && !_routesStructuralOnly,
        maxPaths: _coerceInt(_maxPathsCtrl, 200, min: 1, max: 20000),
        maxStepsPerPath: _coerceInt(_maxStepsPerPathCtrl, 500, min: 1, max: 1000000),
        maxVisitsPerNode: _coerceInt(_maxVisitsPerNodeCtrl, 1, min: 1, max: 1000),
      );

      _appendStdout('Computed ${res.paths.length} path(s). Truncated: ${res.truncated}. Explored: ${res.exploredPaths}.');
      _flushStdout();

      const int maxShow = 300;
      final int shown = res.paths.length.clamp(0, maxShow);
      final List<Object> pathsJson = <Object>[
        for (int i = 0; i < shown; i++)
          <String, Object?>{
            'index': i,
            'reason': res.paths[i].reason.name,
            'message': res.paths[i].message,
            'nodes': <Object>[
              for (final AbstractNode n in res.paths[i].nodes) <String, Object?>{'id': n.id, 'type': n.runtimeType.toString()},
            ],
            'edges': <Object>[
              for (final AbstractEdge e in res.paths[i].edges)
                if (e is BranchEdge)
                  <String, Object?>{'id': e.id, 'type': 'BranchEdge', 'from': e.from.id, 'to': e.to.id, 'port': e.fromPort}
                else
                  <String, Object?>{'id': e.id, 'type': e.runtimeType.toString(), 'from': e.from.id, 'to': e.to.id},
            ],
            if (_routesIncludeContext) 'context': res.paths[i].ctx,
          },
      ];

      final Map<String, Object?> out = <String, Object?>{
        'mode': _routesStructuralOnly ? 'structural' : (_routesIncludeExec ? (_routesIncludeContext ? 'context+exec+ctx' : 'context+exec') : 'context'),
        'totalPaths': res.paths.length,
        'pathsShown': shown,
        'truncated': res.truncated,
        'exploredPaths': res.exploredPaths,
        'paths': pathsJson,
      };

      setState(() => _outCtrl.text = _prettyJson(out));
    } catch (e, st) {
      _appendStdout('Routes error: $e');
      _flushStdout();
      debugPrintStack(stackTrace: st);
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  void _stop() {
    if (!_isRunning) return;
    setState(() => _cancelRequested = true);
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final ThemeData t = Theme.of(context);
    final ColorScheme cs = t.colorScheme;

    final double maxW = MediaQuery.of(context).size.width * 0.95;
    final double maxH = MediaQuery.of(context).size.height * 0.85;

    final List<TestContext> tests = widget.graph.testsContexts.values.toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (_selectedTestId != null && !widget.graph.testsContexts.containsKey(_selectedTestId!)) {
      _selectedTestId = null;
    }

    return AlertDialog(
      title: const Text('Run Graph'),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
        child: SizedBox(
          width: 1000,
          height: 620,
          child: Column(
            children: <Widget>[
              // Mode
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    Text('Mode', style: t.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 12),
                    Wrap(
                      spacing: 8,
                      children: <Widget>[
                        ChoiceChip(
                          label: const Text('Run'),
                          selected: _mode == _RuntimeMode.run,
                          onSelected: _isRunning ? null : (v) => setState(() => _mode = _RuntimeMode.run),
                        ),
                        ChoiceChip(
                          label: const Text('All routes'),
                          selected: _mode == _RuntimeMode.routes,
                          onSelected: _isRunning ? null : (v) => setState(() => _mode = _RuntimeMode.routes),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tests-Zeile
              Container(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    Text('Saved tests', style: t.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 280,
                      child: DropdownButtonFormField<String>(
                        value: _selectedTestId,
                        decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), hintText: 'Select test'),
                        items: <DropdownMenuItem<String>>[
                          for (final TestContext tc in tests)
                            DropdownMenuItem<String>(
                              value: tc.id,
                              child: Text(tc.name, overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: (String? v) => setState(() => _selectedTestId = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Load selected test into Context JSON',
                      child: IconButton(onPressed: (_selectedTestId == null) ? null : _loadSelectedTest, icon: const Icon(Icons.file_download_outlined)),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Save as new test',
                      child: IconButton(onPressed: _saveTestAsNew, icon: const Icon(Icons.save_as_outlined)),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Overwrite selected test',
                      child: IconButton(onPressed: (_selectedTestId == null) ? null : _overwriteSelectedTest, icon: const Icon(Icons.save_outlined)),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Delete selected test',
                      child: IconButton(onPressed: (_selectedTestId == null) ? null : _deleteSelectedTest, icon: const Icon(Icons.delete_outline)),
                    ),
                    const Spacer(),
                    Tooltip(
                      message: 'Format JSON',
                      child: IconButton(onPressed: _formatContext, icon: const Icon(Icons.format_align_left)),
                    ),
                    Tooltip(
                      message: 'Clear JSON',
                      child: IconButton(onPressed: () => setState(() => _ctxCtrl.clear()), icon: const Icon(Icons.clear_all)),
                    ),
                  ],
                ),
              ),

              // Optionen je Modus
              if (_mode == _RuntimeMode.run)
                Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: <Widget>[
                      Text('Runtime options', style: t.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 160,
                        child: TextField(
                          controller: _maxStepsCtrl,
                          enabled: !_isRunning,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(isDense: true, labelText: 'Max steps', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: <Widget>[
                          Switch.adaptive(value: _allowNodeRevisit, onChanged: _isRunning ? null : (v) => setState(() => _allowNodeRevisit = v)),
                          const SizedBox(width: 6),
                          const Text('Allow revisit'),
                        ],
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text('Routes options', style: t.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Switch.adaptive(
                            value: _routesStructuralOnly,
                            onChanged: _isRunning
                                ? null
                                : (bool v) => setState(() {
                                    _routesStructuralOnly = v;
                                    if (v) {
                                      _routesIncludeExec = false;
                                      _routesIncludeContext = false;
                                    }
                                  }),
                          ),
                          const SizedBox(width: 6),
                          const Text('Structural only'),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Switch.adaptive(
                            value: _routesIncludeExec,
                            onChanged: _isRunning
                                ? null
                                : (_routesStructuralOnly ? null : (bool v) => setState(() => _routesIncludeExec = v || _routesIncludeContext)),
                          ),
                          const SizedBox(width: 6),
                          const Text('Include execution'),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Switch.adaptive(
                            value: _routesIncludeContext,
                            onChanged: _isRunning
                                ? null
                                : (_routesStructuralOnly
                                      ? null
                                      : (bool v) => setState(() {
                                          _routesIncludeContext = v;
                                          if (v) _routesIncludeExec = true;
                                        })),
                          ),
                          const SizedBox(width: 6),
                          const Text('Include context'),
                        ],
                      ),
                      SizedBox(
                        width: 140,
                        child: TextField(
                          controller: _maxPathsCtrl,
                          enabled: !_isRunning,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(isDense: true, labelText: 'Max paths', border: OutlineInputBorder()),
                        ),
                      ),
                      SizedBox(
                        width: 180,
                        child: TextField(
                          controller: _maxStepsPerPathCtrl,
                          enabled: !_isRunning,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(isDense: true, labelText: 'Max steps / path', border: OutlineInputBorder()),
                        ),
                      ),
                      SizedBox(
                        width: 190,
                        child: TextField(
                          controller: _maxVisitsPerNodeCtrl,
                          enabled: !_isRunning,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(isDense: true, labelText: 'Max visits / node', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                ),

              // Editor-Spalten
              Expanded(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _Pane(
                        title: 'Context JSON',
                        child: TextField(
                          controller: _ctxCtrl,
                          expands: true,
                          maxLines: null,
                          decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: '{  }', errorText: _ctxError),
                          style: _mono,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Pane(
                        title: 'Result JSON',
                        child: TextField(
                          controller: _outCtrl,
                          expands: true,
                          maxLines: null,
                          readOnly: true,
                          decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                          style: _mono.copyWith(color: cs.onSurface.withOpacity(0.9)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // stdout
              SizedBox(
                height: 160,
                child: _Pane(
                  title: 'stdout',
                  child: Scrollbar(
                    controller: _stdoutScroll,
                    child: ListView.builder(
                      controller: _stdoutScroll,
                      itemCount: _stdout.length,
                      itemBuilder: (_, int i) => Text(_stdout[i], style: _mono.copyWith(color: cs.onSurface.withOpacity(0.85))),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        if (_isRunning)
          FilledButton.icon(onPressed: _stop, icon: const Icon(Icons.stop_circle_outlined), label: const Text('Stop'))
        else if (_mode == _RuntimeMode.run)
          FilledButton.icon(onPressed: _run, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Run'))
        else
          FilledButton.icon(onPressed: _calcRoutes, icon: const Icon(Icons.alt_route_rounded), label: const Text('Calc routes')),
      ],
    );
  }
}

class _Pane extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _Pane({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    final ThemeData t = Theme.of(context);
    final ColorScheme cs = t.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(title, style: t.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showGraphRuntimeDialog(BuildContext context, {required Graph graph, String? startNodeId}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext ctx) => GraphRuntimeDialog(graph: graph, startNodeId: startNodeId),
  );
}

Future<String?> _askName(BuildContext context, {required String title, String? initial, String? hintText}) async {
  final TextEditingController ctrl = TextEditingController(text: initial ?? '');
  final GlobalKey<FormState> key = GlobalKey<FormState>();
  return showDialog<String?>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: Text(title),
      content: Form(
        key: key,
        child: TextFormField(
          controller: ctrl,
          decoration: InputDecoration(hintText: hintText ?? 'Name', border: const OutlineInputBorder()),
          validator: (String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (key.currentState?.validate() ?? false) Navigator.pop(ctx, ctrl.text.trim());
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
