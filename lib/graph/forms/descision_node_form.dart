part of '../graph.dart';

class DecisionNodeForm extends StatefulWidget {
  final Map<String, dynamic> data;

  const DecisionNodeForm({super.key, required this.data});

  @override
  State<DecisionNodeForm> createState() => _DecisionNodeFormState();
}

class _DecisionNodeFormState extends State<DecisionNodeForm> {
  late TextEditingController _titleCtrl;
  late TextEditingController _elseCtrl;


  late List<Map<String, dynamic>> _branches;

  @override
  void initState() {
    super.initState();

    _titleCtrl = TextEditingController(text: (widget.data['title'] as String?) ?? 'Decision');
    _elseCtrl = TextEditingController(text: (widget.data['else'] as String?) ?? '');


    final List<dynamic>? raw = widget.data['branches'] as List<dynamic>?;
    _branches = (raw ?? const <dynamic>[]).cast<Map<String, dynamic>>().toList();

    if (_branches.isEmpty) {
      _branches = <Map<String, dynamic>>[DecisionBranch(name: 'yes').toMap(), DecisionBranch(name: 'no').toMap()];
    }


    _sync();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _elseCtrl.dispose();
    super.dispose();
  }


  void _sync() {
    widget.data['title'] = _titleCtrl.text.trim();
    widget.data['else'] = _elseCtrl.text.trim().isEmpty ? null : _elseCtrl.text.trim();
    widget.data['branches'] = _branches;
  }

  void _addBranch() {
    setState(() {
      _branches.add(DecisionBranch(name: 'branch_${_branches.length + 1}').toMap());
      _sync();
    });
  }

  void _removeBranchAt(int index) {
    setState(() {
      _branches.removeAt(index);
      _sync();
    });
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


        Align(
          alignment: Alignment.centerLeft,
          child: Text('Branches (first match wins)', style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 8),


        Column(
          children: List<Widget>.generate(_branches.length, (int i) {
            return DecisionBranchEditor(
              key: ValueKey<String>('branch_$i'),
              branchMap: _branches[i],
              onChanged: (Map<String, dynamic> m) {
                setState(() {
                  _branches[i] = m;
                  _sync();
                });
              },
              onRemove: () => _removeBranchAt(i),
            );
          }),
        ),


        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(onPressed: _addBranch, icon: const Icon(Icons.add), label: const Text('Add branch')),
        ),
      ],
    );
  }
}
