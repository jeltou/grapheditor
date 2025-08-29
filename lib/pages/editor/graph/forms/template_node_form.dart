part of '../graph.dart';

class TemplateNodeForm extends StatefulWidget {
  final Map<String, dynamic> data;
  const TemplateNodeForm({super.key, required this.data});

  @override
  State<TemplateNodeForm> createState() => _TemplateNodeFormState();
}

class _TemplateNodeFormState extends State<TemplateNodeForm> {
  late TextEditingController _titleCtrl;
  late TextEditingController _outCtrl;
  late TextEditingController _tplCtrl;
  bool _nullAsEmpty = true;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: (widget.data['title'] as String?) ?? 'Template');
    _outCtrl = TextEditingController(text: (widget.data['outPath'] as String?) ?? 'result');
    _tplCtrl = TextEditingController(text: (widget.data['template'] as String?) ?? '');
    _nullAsEmpty = (widget.data['nullAsEmpty'] as bool?) ?? true;
    _sync();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _outCtrl.dispose();
    _tplCtrl.dispose();
    super.dispose();
  }

  void _sync() {
    widget.data['title'] = _titleCtrl.text.trim();
    widget.data['outPath'] = _outCtrl.text.trim().isEmpty ? 'result' : _outCtrl.text.trim();
    widget.data['template'] = _tplCtrl.text;
    widget.data['nullAsEmpty'] = _nullAsEmpty;
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
        TextFormField(
          controller: _outCtrl,
          decoration: const InputDecoration(labelText: 'Output path', hintText: 'e.g. output.greeting', border: OutlineInputBorder()),
          validator: (String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          onChanged: (_) => _sync(),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Switch.adaptive(
              value: _nullAsEmpty,
              onChanged: (bool v) => setState(() {
                _nullAsEmpty = v;
                _sync();
              }),
            ),
            const SizedBox(width: 6),
            const Text('Null → empty string'),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Template', style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 180,
          child: TextFormField(
            controller: _tplCtrl,
            expands: true,
            maxLines: null,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Hello {{user.firstName}}!\nYour total is {{cart.total}} €.',
            ),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            onChanged: (_) => _sync(),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Use {{ path.to.value }} to inject context values.',
            style: t.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
