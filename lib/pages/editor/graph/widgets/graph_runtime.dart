part of '../graph.dart';

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

  final TextEditingController _maxStepsCtrl = TextEditingController(text: '1000');
  bool _allowNodeRevisit = true;

  late final TextEditingController _ctxCtrl;
  late final TextEditingController _outCtrl;
  late final ScrollController _stdoutScroll;


  final List<String> _stdout = <String>[];
  final List<String> _stdoutBuffer = <String>[];
  Timer? _stdoutFlushTimer;
  static const int _stdoutFlushIntervalMs = 50;
  static const int _stdoutMaxLines = 2000;

  String? _ctxError;
  String? _selectedTestId;

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
    super.dispose();
  }

  TextStyle get _mono => const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.3);

  String _exampleContextJson() {
    final Map<String, Object> sample = <String, Object>{"value": 1};
    return const JsonEncoder.withIndent('  ').convert(sample);
  }

  void _appendStdout(String line) {
    _stdoutBuffer.add(line);
    _stdoutFlushTimer ??= Timer(const Duration(milliseconds: _stdoutFlushIntervalMs), _flushStdout);
  }

  void _flushStdout() {
    _stdoutFlushTimer?.cancel();
    _stdoutFlushTimer = null;
    if (!mounted || _stdoutBuffer.isEmpty) return;


    bool shouldAutoScroll = false;
    if (_stdoutScroll.hasClients) {
      final pos = _stdoutScroll.position;
      shouldAutoScroll = (pos.maxScrollExtent - pos.pixels) < 80;
    }

    setState(() {
      _stdout.addAll(_stdoutBuffer);
      _stdoutBuffer.clear();
      if (_stdout.length > _stdoutMaxLines) {
        _stdout.removeRange(0, _stdout.length - _stdoutMaxLines);
      }
    });

    if (shouldAutoScroll) {
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
    if (ctx != null) {
      _ctxCtrl.text = _prettyJson(ctx);
    }
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
    setState(() {
      _selectedTestId = t.id;
    });
  }

  Future<void> _overwriteSelectedTest() async {
    if (_selectedTestId == null) return;
    final TestContext? t = widget.graph.testsContexts[_selectedTestId!];
    if (t == null) return;
    setState(() {
      t.json = _ctxCtrl.text;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test overwritten')));
  }

  void _deleteSelectedTest() {
    if (_selectedTestId == null) return;
    widget.graph.removeTestContextById(_selectedTestId!);
    setState(() {
      _selectedTestId = null;
    });
  }

  int _coerceMaxSteps() {
    final String raw = _maxStepsCtrl.text.trim();
    final int? v = int.tryParse(raw);
    if (v == null || v <= 0) return 1000;
    return v.clamp(1, 100000000);
  }

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

    final int maxSteps = _coerceMaxSteps();

    final GraphRuntime rt = GraphRuntime(
      graph: widget.graph,
      maxSteps: maxSteps,
      allowNodeRevisit: _allowNodeRevisit,
      hooks: RuntimeHooks(
        beforeNode: (AbstractNode node, Map<String, dynamic> context) {
          _appendStdout('→ Node ${node.runtimeType}(${node.id})');
          return true;
        },
        afterNode: (AbstractNode node, Map<String, dynamic> context) {},
        onEdge: (AbstractEdge edge, Map<String, dynamic> context) {
          if (edge is BranchEdge) {
            _appendStdout('  use BranchEdge ${edge.id} [${edge.fromPort}]');
          } else {
            _appendStdout('  use Edge ${edge.id}');
          }
        },
        chooseNextDefaultEdge: (AbstractNode node, List<AbstractEdge> outs, Map<String, dynamic> context) {
          outs.sort((AbstractEdge a, AbstractEdge b) => a.id.compareTo(b.id));
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

        // deactivatet through perfomance issues
        // 'visitedNodes': <Object>[
        //   for (final AbstractNode n in res.visitedNodes) <String, Object?>{'id': n.id, 'type': n.runtimeType.toString()},
        // ],
        // 'traversedEdges': <Object>[
        //   for (final AbstractEdge e in res.traversedEdges)
        //     if (e is BranchEdge)
        //       <String, Object?>{'id': e.id, 'type': 'BranchEdge', 'from': e.from.id, 'to': e.to.id, 'port': e.fromPort}
        //     else
        //       <String, Object?>{'id': e.id, 'type': e.runtimeType.toString(), 'from': e.from.id, 'to': e.to.id},
        // ],
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

  void _stop() {
    if (!_isRunning) return;
    setState(() => _cancelRequested = true);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData t = Theme.of(context);
    final ColorScheme cs = t.colorScheme;

    final double maxW = MediaQuery.of(context).size.width * 0.95;
    final double maxH = MediaQuery.of(context).size.height * 0.85;

    final List<TestContext> tests = widget.graph.testsContexts.values.toList()
      ..sort((TestContext a, TestContext b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

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
                        Switch.adaptive(value: _allowNodeRevisit, onChanged: _isRunning ? null : (bool v) => setState(() => _allowNodeRevisit = v)),
                        const SizedBox(width: 6),
                        const Text('Allow revisit'),
                      ],
                    ),
                  ],
                ),
              ),


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


              SizedBox(
                height: 160,
                child: _Pane(
                  title: 'stdout',
                  child: Scrollbar(
                    controller: _stdoutScroll,
                    child: ListView.builder(
                      controller: _stdoutScroll,
                      itemCount: _stdout.length,
                      itemBuilder: (BuildContext _, int i) {
                        return Text(_stdout[i], style: _mono.copyWith(color: cs.onSurface.withOpacity(0.85)));
                      },
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
        else
          FilledButton.icon(onPressed: _run, icon: const Icon(Icons.play_arrow_rounded), label: const Text('Run')),
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
    builder: (BuildContext ctx) {
      return AlertDialog(
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
              if (key.currentState?.validate() ?? false) {
                Navigator.pop(ctx, ctrl.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
