part of '../graph.dart';

class DecisionBranchEditor extends StatefulWidget {
  final Map<String, dynamic> branchMap;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onRemove;

  const DecisionBranchEditor({super.key, required this.branchMap, required this.onChanged, required this.onRemove});

  @override
  State<DecisionBranchEditor> createState() => _DecisionBranchEditorState();
}

class _DecisionBranchEditorState extends State<DecisionBranchEditor> {
  late TextEditingController _nameCtrl;
  late ConditionGroupOp _op;
  late List<Map<String, dynamic>> _rules;

  String? _nameError;

  @override
  void initState() {
    super.initState();
    final DecisionBranch b = DecisionBranch.fromMap(widget.branchMap);
    _nameCtrl = TextEditingController(text: b.name);
    _op = b.groupOp;
    _rules = b.rules.map((ConditionRule r) => r.toMap()).toList();
    _validateName(_nameCtrl.text);
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _validateName(String value) {
    final String v = value.trim();
    if (v.isEmpty) {
      _nameError = 'Branch name is required';
    } else {
      _nameError = null;
    }
  }

  void _emit() {
    final String safeName = _nameCtrl.text.trim();
    final DecisionBranch out = DecisionBranch(name: safeName.isEmpty ? 'branch' : safeName, groupOp: _op, rules: _rules.map(ConditionRule.fromMap).toList());
    widget.onChanged(out.toMap());
  }

  void _addRule() {
    setState(() {
      _rules.add(ConditionRule(leftKey: 'field', op: ConditionOp.eq, rightValue: '').toMap());
      _emit();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData t = Theme.of(context);
    final Color border = t.dividerColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: <Widget>[

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Branch name (edge port)',
                    hintText: 'e.g. accepted',
                    border: const OutlineInputBorder(),
                    errorText: _nameError,
                    helperText: 'Used as edge label / fromPort',
                  ),
                  onChanged: (String _) {
                    setState(() {
                      _validateName(_nameCtrl.text);
                      _emit();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: <Widget>[
                  DropdownButton<ConditionGroupOp>(
                    value: _op,
                    onChanged: (ConditionGroupOp? v) {
                      if (v != null) {
                        setState(() {
                          _op = v;
                          _emit();
                        });
                      }
                    },
                    items: ConditionGroupOp.values
                        .map(
                          (ConditionGroupOp e) =>
                              DropdownMenuItem<ConditionGroupOp>(value: e, child: Text(e == ConditionGroupOp.all ? 'ALL (AND)' : 'ANY (OR)')),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 4),
                  IconButton(tooltip: 'Remove branch', onPressed: widget.onRemove, icon: const Icon(Icons.delete_outline)),
                ],
              ),
            ],
          ),

          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Changing the branch name may break edges labeled with the old name.', style: t.textTheme.bodySmall?.copyWith(color: t.hintColor)),
            ),
          ),

          const SizedBox(height: 10),

          if (_rules.isEmpty)
            _EmptyRulesHint(onAdd: _addRule)
          else
            Column(
              children: List<Widget>.generate(_rules.length, (int i) {
                return DecisionRuleEditor(
                  key: ValueKey<String>('rule_$i'),
                  ruleMap: _rules[i],
                  onChanged: (Map<String, dynamic> v) {
                    setState(() {
                      _rules[i] = v;
                      _emit();
                    });
                  },
                  onRemove: () {
                    setState(() {
                      _rules.removeAt(i);
                      _emit();
                    });
                  },
                );
              }),
            ),

          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(onPressed: _addRule, icon: const Icon(Icons.add), label: const Text('Add rule')),
          ),
        ],
      ),
    );
  }


}

class _EmptyRulesHint extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyRulesHint({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final ThemeData t = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: t.colorScheme.surfaceVariant.withOpacity(0.25), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: <Widget>[
          const Icon(Icons.info_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text('No rules in this branch. It will never match.', style: t.textTheme.bodySmall)),
          TextButton(onPressed: onAdd, child: const Text('Add first rule')),
        ],
      ),
    );
  }
}
