part of '../graph.dart';

class ContextNodeForm extends StatefulWidget {
  final Map<String, dynamic> data;
  const ContextNodeForm({super.key, required this.data});

  @override
  State<ContextNodeForm> createState() => _ContextNodeFormState();
}

class _ContextNodeFormState extends State<ContextNodeForm> {
  late TextEditingController _titleCtrl;
  late List<Map<String, dynamic>> _actions;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: (widget.data['title'] as String?) ?? 'Context');
    _actions = ((widget.data['actions'] as List?) ?? const <dynamic>[]).cast<Map<String, dynamic>>().toList();
    if (_actions.isEmpty) {
      _actions.add(ContextAction(op: ContextOp.setValue, path: 'user.flag', value: true).toMap());
    }
    _sync();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _sync() {
    widget.data['title'] = _titleCtrl.text.trim();
    widget.data['actions'] = _actions;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData t = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TextFormField(
          controller: _titleCtrl,
          decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
          onChanged: (_) => _sync(),
        ),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerLeft, child: Text('Actions', style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
        const SizedBox(height: 8),
        Column(
          children: List<Widget>.generate(_actions.length, (int i) {
            return ContextActionEditor(
              key: ValueKey<String>('ctx_action_$i'),
              map: _actions[i],
              onChanged: (Map<String, dynamic> m) {
                setState(() {
                  _actions[i] = m;
                  _sync();
                });
              },
              onRemove: () {
                setState(() {
                  _actions.removeAt(i);
                  _sync();
                });
              },
            );
          }),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _actions.add(ContextAction(op: ContextOp.setValue, path: 'key', value: 'value').toMap());
                _sync();
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Add action'),
          ),
        ),
      ],
    );
  }
}

class ContextActionEditor extends StatefulWidget {
  final Map<String, dynamic> map;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onRemove;

  const ContextActionEditor({super.key, required this.map, required this.onChanged, required this.onRemove});

  @override
  State<ContextActionEditor> createState() => _ContextActionEditorState();
}

class _ContextActionEditorState extends State<ContextActionEditor> {
  late ContextOp _op;
  late TextEditingController _pathCtrl;
  late TextEditingController _valueCtrl;
  String _type = 'auto';

  @override
  void initState() {
    super.initState();
    final ContextAction a = ContextAction.fromMap(widget.map);
    _op = a.op;
    _pathCtrl = TextEditingController(text: a.path);
    _valueCtrl = TextEditingController(text: _stringify(a.value));
    _type = _inferType(a.value);
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    _pathCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  String _stringify(dynamic v) {
    if (v == null) return '';
    if (v is Map || v is List) return const JsonEncoder.withIndent('  ').convert(v);
    return '$v';
  }

  String _inferType(dynamic v) {
    if (v is bool) return 'bool';
    if (v is num) return 'number';
    if (v is Map || v is List) return 'json';
    if (v is String) {
      if (num.tryParse(v) != null) return 'number';
      if (v.toLowerCase() == 'true' || v.toLowerCase() == 'false') return 'bool';
      if (v.startsWith('{') || v.startsWith('[')) return 'json';
      return 'string';
    }
    return 'auto';
  }

  dynamic _parseValue(String s) {
    switch (_type) {
      case 'number':
        return num.tryParse(s);
      case 'bool':
        final String l = s.toLowerCase();
        if (l == 'true') return true;
        if (l == 'false') return false;
        return null;
      case 'json':
        try {
          return jsonDecode(s);
        } catch (_) {
          return null;
        }
      case 'string':
        return s;
      default:
        final num? n = num.tryParse(s);
        if (n != null) return n;
        if (s.toLowerCase() == 'true') return true;
        if (s.toLowerCase() == 'false') return false;
        if (s.startsWith('{') || s.startsWith('[')) {
          try {
            return jsonDecode(s);
          } catch (_) {}
        }
        return s;
    }
  }

  void _emit() {
    final Map<String, dynamic> m = <String, dynamic>{
      'op': _op.name,
      'path': _pathCtrl.text.trim(),
      'value': switch (_op) {
        ContextOp.removeKey || ContextOp.toggleBool => null,
        _ => _parseValue(_valueCtrl.text),
      },
    };
    widget.onChanged(m);
  }

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuItem<ContextOp>> opItems = ContextOp.values
        .map((ContextOp o) => DropdownMenuItem<ContextOp>(
      value: o,
      child: Text(switch (o) {
        ContextOp.setValue => 'set',
        ContextOp.increment => 'increment',
        ContextOp.toggleBool => 'toggle',
        ContextOp.removeKey => 'remove',
        ContextOp.mergeObject => 'merge',
      }),
    ))
        .toList();

    final bool needsValue = _op == ContextOp.setValue || _op == ContextOp.increment || _op == ContextOp.mergeObject;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          DropdownButton<ContextOp>(value: _op, onChanged: (ContextOp? v) => setState(() { if (v != null) _op = v; _emit(); }),
              items: opItems),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: _pathCtrl,
              decoration: const InputDecoration(hintText: 'user.age', border: OutlineInputBorder()),
              onChanged: (_) => _emit(),
            ),
          ),
          const SizedBox(width: 8),
          if (needsValue)
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _valueCtrl,
                decoration: const InputDecoration(hintText: 'value / json', border: OutlineInputBorder()),
                onChanged: (_) => _emit(),
                maxLines: (_type == 'json') ? 3 : 1,
              ),
            ),
          if (needsValue) const SizedBox(width: 8),
          if (needsValue)
            DropdownButton<String>(
              value: _type,
              onChanged: (String? v) => setState(() { if (v != null) _type = v; _emit(); }),
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(value: 'auto', child: Text('auto')),
                DropdownMenuItem<String>(value: 'string', child: Text('string')),
                DropdownMenuItem<String>(value: 'number', child: Text('number')),
                DropdownMenuItem<String>(value: 'bool', child: Text('bool')),
                DropdownMenuItem<String>(value: 'json', child: Text('json')),
              ],
            ),
          IconButton(onPressed: widget.onRemove, icon: const Icon(Icons.delete_outline)),
        ],
      ),
    );
  }
}
