part of '../graph.dart';

class DecisionRuleEditor extends StatefulWidget {
  final Map<String, dynamic> ruleMap;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onRemove;

  const DecisionRuleEditor({super.key, required this.ruleMap, required this.onChanged, required this.onRemove});

  @override
  State<DecisionRuleEditor> createState() => _DecisionRuleEditorState();
}

class _DecisionRuleEditorState extends State<DecisionRuleEditor> {
  late TextEditingController _keyCtrl;
  late TextEditingController _valCtrl;
  late ConditionOp _op;



  String _type = 'auto';


  bool _boolValue = false;

  @override
  void initState() {
    super.initState();
    final ConditionRule r = ConditionRule.fromMap(widget.ruleMap);

    _keyCtrl = TextEditingController(text: r.leftKey);
    _op = r.op;


    _type = _inferTypeFromValue(r.rightValue) ?? _defaultTypeForOp(_op);

    if (_type == 'bool') {
      _boolValue = _asBool(r.rightValue) ?? false;
      _valCtrl = TextEditingController(text: '');
    } else {
      _valCtrl = TextEditingController(text: (r.rightValue == null) ? '' : '${r.rightValue}');
    }


    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  String? _enforcedTypeForOp(ConditionOp op) {
    if (_isNumericOp(op)) return 'number';
    if (_isStringOnlyOp(op)) return 'string';
    return null;
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _valCtrl.dispose();
    super.dispose();
  }




  dynamic _parseValue(String s) {
    switch (_effectiveTypeForOp(_op, _type)) {
      case 'string':
        return s;
      case 'number':
        return num.tryParse(s);
      case 'bool':
        return _boolValue;
      default:
        final num? n = num.tryParse(s);
        if (n != null) return n;
        if (s.toLowerCase() == 'true') return true;
        if (s.toLowerCase() == 'false') return false;
        return s;
    }
  }


  void _emit() {
    final Map<String, dynamic> m = <String, dynamic>{
      'leftKey': _keyCtrl.text.trim(),
      'op': _op.name,
      'rightValue': (_effectiveTypeForOp(_op, _type) == 'bool') ? _boolValue : _parseValue(_valCtrl.text),
    };
    widget.onChanged(m);
  }


  bool _isNumericOp(ConditionOp op) => op == ConditionOp.gt || op == ConditionOp.gte || op == ConditionOp.lt || op == ConditionOp.lte;


  bool _isStringOnlyOp(ConditionOp op) => op == ConditionOp.contains || op == ConditionOp.startsWith || op == ConditionOp.endsWith;


  String _effectiveTypeForOp(ConditionOp op, String chosen) {
    if (_isNumericOp(op)) return 'number';
    if (_isStringOnlyOp(op)) return 'string';
    return chosen;
  }


  String _defaultTypeForOp(ConditionOp op) {
    if (_isNumericOp(op)) return 'number';
    if (_isStringOnlyOp(op)) return 'string';
    return 'auto';
  }


  String? _inferTypeFromValue(dynamic v) {
    if (v is bool) return 'bool';
    if (v is num) return 'number';
    if (v is String) {

      if (num.tryParse(v) != null) return 'number';
      if (v.toLowerCase() == 'true' || v.toLowerCase() == 'false') return 'bool';
      return 'string';
    }
    return null;
  }

  bool? _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is String) {
      final String l = v.toLowerCase();
      if (l == 'true') return true;
      if (l == 'false') return false;
    }
    return null;
  }



  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuItem<ConditionOp>> opItems = ConditionOp.values.map((ConditionOp o) {
      final String label = switch (o) {
        ConditionOp.eq => '==',
        ConditionOp.ne => '!=',
        ConditionOp.gt => '>',
        ConditionOp.gte => '>=',
        ConditionOp.lt => '<',
        ConditionOp.lte => '<=',
        ConditionOp.contains => 'contains',
        ConditionOp.startsWith => 'startsWith',
        ConditionOp.endsWith => 'endsWith',
      };
      return DropdownMenuItem<ConditionOp>(value: o, child: Text(label));
    }).toList();


    final String? enforced = _enforcedTypeForOp(_op);
    final bool lockType = enforced != null;


    final String effType = enforced ?? _type;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: _keyCtrl,
              decoration: const InputDecoration(hintText: 'field.path', border: OutlineInputBorder()),
              onChanged: (_) => _emit(),
            ),
          ),
          const SizedBox(width: 8),


          DropdownButton<ConditionOp>(
            value: _op,
            onChanged: (ConditionOp? v) {
              if (v != null) {
                setState(() {
                  _op = v;

                  _emit();
                });
              }
            },
            items: opItems,
          ),
          const SizedBox(width: 8),


          Expanded(flex: 3, child: _buildRightValueEditor(effType)),
          const SizedBox(width: 8),


          IgnorePointer(
            ignoring: lockType,
            child: Opacity(
              opacity: lockType ? 0.6 : 1.0,
              child: DropdownButton<String>(
                value: effType,
                onChanged: (String? v) {
                  if (v != null) {
                    setState(() {
                      _type = v;
                      if (v == 'bool') {
                        _boolValue = _asBool(_valCtrl.text) ?? _boolValue;
                      }
                      _emit();
                    });
                  }
                },
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(value: 'auto', child: Text('auto')),
                  DropdownMenuItem<String>(value: 'string', child: Text('string')),
                  DropdownMenuItem<String>(value: 'number', child: Text('number')),
                  DropdownMenuItem<String>(value: 'bool', child: Text('bool')),
                ],
              ),
            ),
          ),

          IconButton(tooltip: 'Remove rule', onPressed: widget.onRemove, icon: const Icon(Icons.delete_outline)),
        ],
      ),
    );
  }

  Widget _buildRightValueEditor(String effType) {
    switch (effType) {
      case 'bool':
        return _BoolInlineEditor(
          value: _boolValue,
          onChanged: (bool v) {
            setState(() {
              _boolValue = v;
              _emit();
            });
          },
        );
      case 'number':
        return TextFormField(
          controller: _valCtrl,
          decoration: const InputDecoration(hintText: 'number', border: OutlineInputBorder()),
          keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
          inputFormatters: <TextInputFormatter>[

            FilteringTextInputFormatter.allow(RegExp(r'^[\d\-\.,]*$')),
          ],
          onChanged: (_) => _emit(),
        );
      case 'string':
      default:
        return TextFormField(
          controller: _valCtrl,
          decoration: const InputDecoration(hintText: 'value', border: OutlineInputBorder()),
          onChanged: (_) => _emit(),
        );
    }
  }
}


class _BoolInlineEditor extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _BoolInlineEditor({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Text('false'),
        Switch(value: value, onChanged: onChanged, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        const Text('true'),
      ],
    );
  }
}
