part of '../graph.dart';

class NodeCreator {
  final Map<String, NodeTypeDescriptor> registry;

  NodeCreator({Map<String, NodeTypeDescriptor>? registry}) : registry = registry ?? defaultNodeRegistry();

  Future<AbstractNode?> open(BuildContext context, {String? initialType}) async {
    final _NodeEditorResult? res = await showDialog<_NodeEditorResult>(
      context: context,
      builder: (BuildContext ctx) {
        return _NodeEditorDialog(registry: registry, mode: NodeEditorMode.create, initialType: initialType);
      },
    );

    if (res == null || !res.saved) return null;

    final NodeTypeDescriptor? desc = registry[res.type];
    if (desc == null) return null;

    final AbstractNode node = desc.buildNode(res.data);
    return node;
  }

  Future<bool> openEdit(BuildContext context, AbstractNode node) async {
    final Map<String, dynamic> snapshot = node.toMap();
    final String nodeType = (snapshot['nodeType'] as String?) ?? node.runtimeType.toString();

    final NodeTypeDescriptor? desc = registry[nodeType];
    if (desc == null) {
      await showDialog<void>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: const Text('Unsupported type'),
          content: Text('No editor registered for type "$nodeType".'),
          actions: <Widget>[TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
      return false;
    }

    final _NodeEditorResult? res = await showDialog<_NodeEditorResult>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return _NodeEditorDialog(registry: registry, mode: NodeEditorMode.edit, fixedType: nodeType, initialData: snapshot);
      },
    );

    if (res == null || !res.saved) return false;

    desc.applyToNode?.call(node, res.data);
    return true;
  }
}

enum NodeEditorMode { create, edit }

class _NodeEditorResult {
  final bool saved;
  final String type;
  final Map<String, dynamic> data;

  const _NodeEditorResult({required this.saved, required this.type, required this.data});
}

class _NodeEditorDialog extends StatefulWidget {
  final Map<String, NodeTypeDescriptor> registry;
  final NodeEditorMode mode;

  final String? initialType;
  final String? fixedType;
  final Map<String, dynamic>? initialData;

  const _NodeEditorDialog({required this.registry, required this.mode, this.initialType, this.fixedType, this.initialData});

  @override
  State<_NodeEditorDialog> createState() => _NodeEditorDialogState();
}

class _NodeEditorDialogState extends State<_NodeEditorDialog> with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String _selectedType;
  late Map<String, dynamic> _data;

  bool get _isEdit => widget.mode == NodeEditorMode.edit;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _selectedType = widget.fixedType!;
      _data = Map<String, dynamic>.from(widget.initialData ?? <String, dynamic>{});
    } else {
      _selectedType = widget.initialType ?? widget.registry.keys.first;
      _data = <String, dynamic>{};
    }
  }

  void _submit() {
    final FormState? form = _formKey.currentState;
    if (form != null) {
      if (!form.validate()) return;
      form.save();
    }

    Navigator.of(context).pop<_NodeEditorResult>(_NodeEditorResult(saved: true, type: _selectedType, data: _data));
  }

  @override
  Widget build(BuildContext context) {
    final NodeTypeDescriptor? current = widget.registry[_selectedType];
    if (current == null) {

      return AlertDialog(
        title: const Text('Unsupported type'),
        content: Text('No editor registered for type "$_selectedType".'),
        actions: <Widget>[TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      );
    }

    final Widget section = current.buildSection(context, _data);
    final double maxDialogHeight = MediaQuery.of(context).size.height * 0.8;

    return AlertDialog(
      title: Text(_isEdit ? 'Edit ${current.displayName}' : 'Create Node'),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      content: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 600, maxWidth: 720, maxHeight: maxDialogHeight),
        child: SingleChildScrollView(
          clipBehavior: Clip.hardEdge,
          child: Form(
            key: _formKey,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (!_isEdit)
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      items: <DropdownMenuItem<String>>[
                        for (final NodeTypeDescriptor d in widget.registry.values) DropdownMenuItem<String>(value: d.type, child: Text(d.displayName)),
                      ],
                      decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                      onChanged: (String? v) {
                        if (v == null) return;
                        setState(() {
                          _selectedType = v;
                          _data.clear();
                        });
                      },
                    )
                  else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          child: Text(current.displayName, style: Theme.of(context).textTheme.bodyMedium),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  section,
                ],
              ),
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop<_NodeEditorResult?>(null), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: Text(_isEdit ? 'Save' : 'Create')),
      ],
    );
  }
}
