part of '../graph.dart';

class _MapperRuleEditor extends StatefulWidget {
  final Map<String, dynamic> map;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onRemove;

  const _MapperRuleEditor({super.key, required this.map, required this.onChanged, required this.onRemove});

  @override
  State<_MapperRuleEditor> createState() => _MapperRuleEditorState();
}

class _MapperRuleEditorState extends State<_MapperRuleEditor> {
  late TextEditingController _fromCtrl;
  late TextEditingController _toCtrl;
  bool _move = false;
  bool _overwrite = true;
  bool _skipIfNull = true;

  @override
  void initState() {
    super.initState();
    final MapperRule r = MapperRule.fromMap(widget.map);
    _fromCtrl = TextEditingController(text: r.from);
    _toCtrl = TextEditingController(text: r.to);
    _move = r.move;
    _overwrite = r.overwrite;
    _skipIfNull = r.skipIfNull;
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(MapperRule(
      from: _fromCtrl.text.trim(),
      to: _toCtrl.text.trim(),
      move: _move,
      overwrite: _overwrite,
      skipIfNull: _skipIfNull,
    ).toMap());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextFormField(
              controller: _fromCtrl,
              decoration: const InputDecoration(labelText: 'From', hintText: 'contextdata.xyz', border: OutlineInputBorder()),
              onChanged: (_) => _emit(),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: _toCtrl,
              decoration: const InputDecoration(labelText: 'To', hintText: 'a.c.d', border: OutlineInputBorder()),
              onChanged: (_) => _emit(),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Move (delete source)',
            child: Checkbox(
              value: _move,
              onChanged: (bool? v) {
                setState(() {
                  _move = v ?? false;
                  _emit();
                });
              },
            ),
          ),
          Tooltip(
            message: 'Overwrite destination',
            child: Checkbox(
              value: _overwrite,
              onChanged: (bool? v) {
                setState(() {
                  _overwrite = v ?? true;
                  _emit();
                });
              },
            ),
          ),
          Tooltip(
            message: 'Skip when source is null',
            child: Checkbox(
              value: _skipIfNull,
              onChanged: (bool? v) {
                setState(() {
                  _skipIfNull = v ?? true;
                  _emit();
                });
              },
            ),
          ),
          IconButton(onPressed: widget.onRemove, icon: const Icon(Icons.delete_outline)),
        ],
      ),
    );
  }
}