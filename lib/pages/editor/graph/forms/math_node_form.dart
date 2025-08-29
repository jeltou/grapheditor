part of '../graph.dart';

class MathNodeForm extends StatefulWidget {
  final Map<String, dynamic> data;
  const MathNodeForm({super.key, required this.data});

  @override
  State<MathNodeForm> createState() => _MathNodeFormState();
}

class _MathNodeFormState extends State<MathNodeForm> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _exprCtrl;
  late final TextEditingController _outCtrl;
  MathRounding _rounding = MathRounding.none;
  late final TextEditingController _precCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: (widget.data['title'] as String?) ?? 'Math');
    _exprCtrl  = TextEditingController(text: (widget.data['expr']  as String?) ?? '');
    _outCtrl   = TextEditingController(text: (widget.data['outPath'] as String?) ?? 'result');
    _rounding  = MathNode._roundingFromName((widget.data['rounding'] as String?) ?? 'none');
    _precCtrl  = TextEditingController(text: ((widget.data['precision'] as num?)?.toInt()).toString());
    _sync();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _exprCtrl.dispose();
    _outCtrl.dispose();
    _precCtrl.dispose();
    super.dispose();
  }

  void _sync() {
    widget.data['title'] = _titleCtrl.text.trim();
    widget.data['expr'] = _exprCtrl.text.trim();
    widget.data['outPath'] = _outCtrl.text.trim();
    widget.data['rounding'] = _rounding.name;
    final int? p = int.tryParse(_precCtrl.text.trim());
    widget.data['precision'] = p;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextFormField(
          controller: _titleCtrl,
          decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
          onChanged: (_) => _sync(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _exprCtrl,
          decoration: const InputDecoration(
            labelText: 'Expression',
            hintText: 'z.B. a + b*2 - user.age/4',
            border: OutlineInputBorder(),
          ),
          validator: (String? v) => (v == null || v.trim().isEmpty) ? 'Expression required' : null,
          onChanged: (_) => _sync(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _outCtrl,
          decoration: const InputDecoration(labelText: 'Output path', hintText: 'result.total', border: OutlineInputBorder()),
          validator: (String? v) => (v == null || v.trim().isEmpty) ? 'Output path required' : null,
          onChanged: (_) => _sync(),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: DropdownButtonFormField<MathRounding>(
                value: _rounding,
                decoration: const InputDecoration(labelText: 'Rounding', border: OutlineInputBorder()),
                items: MathRounding.values
                    .map((MathRounding r) => DropdownMenuItem<MathRounding>(value: r, child: Text(r.name)))
                    .toList(),
                onChanged: (MathRounding? v) { if (v != null) setState(() { _rounding = v; _sync(); }); },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _precCtrl,
                decoration: const InputDecoration(labelText: 'Precision (for round)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (_) => _sync(),
                enabled: _rounding == MathRounding.round,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
