part of '../graph.dart';

class MapperNodeForm extends StatefulWidget {
  final Map<String, dynamic> data;
  const MapperNodeForm({super.key, required this.data});

  @override
  State<MapperNodeForm> createState() => _MapperNodeFormState();
}

class _MapperNodeFormState extends State<MapperNodeForm> {
  late TextEditingController _titleCtrl;
  late List<Map<String, dynamic>> _rules;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: (widget.data['title'] as String?) ?? 'Map Context');
    _rules = ((widget.data['rules'] as List?) ?? <dynamic>[])
        .cast<Map<String, dynamic>>()
        .toList();

    if (_rules.isEmpty) {
      _rules = <Map<String, dynamic>>[
        MapperRule(from: 'contextdata.xyz', to: 'a.c.d').toMap(),
      ];
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
    widget.data['rules'] = _rules;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData t = Theme.of(context);
    final ColorScheme cs = t.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TextFormField(
          controller: _titleCtrl,
          decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
          onChanged: (_) => _sync(),
        ),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerLeft, child: Text('Rules', style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
        const SizedBox(height: 8),
        Column(
          children: List<Widget>.generate(_rules.length, (int i) {
            return _MapperRuleEditor(
              key: ValueKey<int>(i),
              map: _rules[i],
              onChanged: (Map<String, dynamic> m) {
                setState(() {
                  _rules[i] = m;
                  _sync();
                });
              },
              onRemove: () {
                setState(() {
                  _rules.removeAt(i);
                  _sync();
                });
              },
            );
          }),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _rules.add(MapperRule(from: 'from.path', to: 'to.path').toMap());
                _sync();
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Add rule'),
          ),
        ),
        const SizedBox(height: 6),
        Container(height: 1, color: cs.onSurface.withOpacity(0.06)),
      ],
    );
  }
}