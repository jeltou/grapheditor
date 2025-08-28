part of '../graph.dart';

typedef NodeFactory = AbstractNode Function(Map<String, dynamic> data);

Map<String, NodeFactory> defaultNodeDecoders() {
  double? toDouble(dynamic v) => (v is num) ? v.toDouble() : (v is String ? double.tryParse(v) : null);
  void applyBaseFields(Map<String, dynamic> m, AbstractNode node) {


    final String? id = m['id'] as String?;
    if (id != null && id.isNotEmpty) {
      (node as dynamic).id = id;
    }


    double? x;
    double? y;
    final dynamic posRaw = m['position'];
    if (posRaw is Map) {
      x ??= toDouble(posRaw['x']);
      y ??= toDouble(posRaw['y']);
    }
    if (x != null && y != null) {
      node.setPosition(Offset(x, y));
    }

    double? width;
    double? height;
    final dynamic sizeRaw = m['size'];
    if (sizeRaw is Map) {
      width ??= toDouble(sizeRaw['width']);
      height ??= toDouble(sizeRaw['height']);
    }
    if (width != null) (node as dynamic).width = width;
    if (height != null) (node as dynamic).height = height;
  }

  return <String, NodeFactory>{
    'RootNode': (Map<String, dynamic> m) {
      final String label = (m['label'] as String?)?.trim() ?? 'Root';
      final RootNode node = RootNode(label: label);
      applyBaseFields(m, node);
      return node;
    },

    'DefaultNode': (Map<String, dynamic> m) {
      final String label = (m['label'] as String?)?.trim() ?? '';
      final DefaultNode node = DefaultNode(label: label);
      applyBaseFields(m, node);
      return node;
    },

    'EndNode': (Map<String, dynamic> m) {
      final String label = (m['label'] as String?)?.trim() ?? '';
      final EndNode node = EndNode(label: label);
      applyBaseFields(m, node);
      return node;
    },

    'DecisionNode': (Map<String, dynamic> m) {
      final String title = (m['title'] as String?)?.trim() ?? 'Decision';
      final List<DecisionBranch> branches = ((m['branches'] as List?) ?? const <dynamic>[]).cast<Map<String, dynamic>>().map(DecisionBranch.fromMap).toList();
      final DecisionNode node = DecisionNode(title: title, branches: branches);
      applyBaseFields(m, node);
      return node;
    },

    'ContextNode': (Map<String, dynamic> m) {
      final String title = (m['title'] as String?)?.trim() ?? 'Context';
      final List<ContextAction> actions = ((m['actions'] as List?) ?? const <dynamic>[]).cast<Map<String, dynamic>>().map(ContextAction.fromMap).toList();
      final ContextNode node = ContextNode(title: title, actions: actions);
      applyBaseFields(m, node);
      return node;
    },
  };
}
