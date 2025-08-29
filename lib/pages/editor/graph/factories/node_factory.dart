part of '../graph.dart';

typedef NodeFactory = AbstractNode Function(Map<String, dynamic> data);

class NodeTypeDescriptor {
  final String type;
  final String displayName;
  final Widget Function(BuildContext, Map<String, dynamic>) buildSection;
  final AbstractNode Function(Map<String, dynamic>) buildNode;
  final void Function(AbstractNode node, Map<String, dynamic> data)? applyToNode;

  const NodeTypeDescriptor({required this.type, required this.displayName, required this.buildSection, required this.buildNode, this.applyToNode});
}

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
    'MathNode': (Map<String, dynamic> m) {
      final String title = (m['title'] as String?) ?? 'Math';
      final String expr = (m['expr'] as String?) ?? '';
      final String out = (m['outPath'] as String?) ?? 'result';
      final MathRounding round = MathNode._roundingFromName((m['rounding'] as String?) ?? 'none');
      final int? prec = (m['precision'] as num?)?.toInt();
      return MathNode(title: title, expr: expr, outPath: out, rounding: round, precision: prec);
    },
  };
}

Map<String, NodeFactory> _ensureFactories(Map<String, NodeFactory>? factories) {
  return factories ?? defaultNodeDecoders();
}

Map<String, NodeTypeDescriptor> defaultNodeRegistry({Map<String, NodeFactory>? factories}) {
  final Map<String, NodeFactory> f = _ensureFactories(factories);

  return <String, NodeTypeDescriptor>{
    'DefaultNode': NodeTypeDescriptor(
      type: 'DefaultNode',
      displayName: 'Default Node',
      buildSection: (BuildContext context, Map<String, dynamic> data) => LabelNodeForm(data),
      buildNode: (Map<String, dynamic> data) => f['DefaultNode']!(data),
      applyToNode: (AbstractNode node, Map<String, dynamic> data) {
        if (node is DefaultNode) {
          node.label = (data['label'] as String?)?.trim() ?? '';
        }
      },
    ),

    'EndNode': NodeTypeDescriptor(
      type: 'EndNode',
      displayName: 'End Node',
      buildSection: (BuildContext context, Map<String, dynamic> data) => LabelNodeForm(data),
      buildNode: (Map<String, dynamic> data) => f['EndNode']!(data),
      applyToNode: (AbstractNode node, Map<String, dynamic> data) {
        if (node is EndNode) {
          node.label = (data['label'] as String?)?.trim() ?? '';
        }
      },
    ),

    'RootNode': NodeTypeDescriptor(
      type: 'RootNode',
      displayName: 'Root Node',
      buildSection: (BuildContext context, Map<String, dynamic> data) => LabelNodeForm(data),
      buildNode: (Map<String, dynamic> data) => f['RootNode']!(data),
      applyToNode: (AbstractNode node, Map<String, dynamic> data) {
        if (node is RootNode) {
          node.label = (data['label'] as String?)?.trim() ?? '';
        }
      },
    ),

    'DecisionNode': NodeTypeDescriptor(
      type: 'DecisionNode',
      displayName: 'Decision Node',
      buildSection: (BuildContext context, Map<String, dynamic> data) => DecisionNodeForm(data: data),
      buildNode: (Map<String, dynamic> data) => f['DecisionNode']!(data),
      applyToNode: (AbstractNode node, Map<String, dynamic> data) {
        if (node is DecisionNode) {
          node.title = (data['title'] as String?)?.trim() ?? 'Decision';
          node.branches = ((data['branches'] as List?) ?? const <dynamic>[]).cast<Map<String, dynamic>>().map(DecisionBranch.fromMap).toList();
        }
      },
    ),

    'ContextNode': NodeTypeDescriptor(
      type: 'ContextNode',
      displayName: 'Context Node',
      buildSection: (BuildContext context, Map<String, dynamic> data) => ContextNodeForm(data: data),
      buildNode: (Map<String, dynamic> data) => f['ContextNode']!(data),
      applyToNode: (AbstractNode node, Map<String, dynamic> data) {
        if (node is ContextNode) {
          node.title = (data['title'] as String?)?.trim() ?? 'Context';
          node.actions = ((data['actions'] as List?) ?? const <dynamic>[]).cast<Map<String, dynamic>>().map(ContextAction.fromMap).toList();
        }
      },
    ),
    'MathNode': NodeTypeDescriptor(
      type: 'MathNode',
      displayName: 'Math Node',
      buildSection: (BuildContext context, Map<String, dynamic> data) => MathNodeForm(data: data),
      buildNode: (Map<String, dynamic> data) {
        final String title = (data['title'] as String?)?.trim() ?? 'Math';
        final String expr = (data['expr'] as String?)?.trim() ?? '';
        final String out = (data['outPath'] as String?)?.trim() ?? 'result';
        final MathRounding round = MathNode._roundingFromName((data['rounding'] as String?) ?? 'none');
        final int? prec = (data['precision'] as num?)?.toInt();
        return MathNode(title: title, expr: expr, outPath: out, rounding: round, precision: prec);
      },
      applyToNode: (AbstractNode node, Map<String, dynamic> data) {
        if (node is MathNode) {
          node.title = (data['title'] as String?)?.trim() ?? 'Math';
          node.expr = (data['expr'] as String?)?.trim() ?? '';
          node.outPath = (data['outPath'] as String?)?.trim() ?? 'result';
          node.rounding = MathNode._roundingFromName((data['rounding'] as String?) ?? 'none');
          node.precision = (data['precision'] as num?)?.toInt();
        }
      },
    ),
    'HttpNode': NodeTypeDescriptor(
      type: 'HttpNode',
      displayName: 'HTTP Node',
      buildSection: (BuildContext context, Map<String, dynamic> data) => HttpNodeForm(data: data),
      buildNode: (Map<String, dynamic> data) => HttpNode(
        title: (data['title'] as String?) ?? 'HTTP',
        method: HttpMethod.values.firstWhere(
              (HttpMethod v) => v.name == (data['method'] as String? ?? 'get'),
          orElse: () => HttpMethod.get,
        ),
        urlTmpl: (data['url'] as String?) ?? 'https://api.example.com',
        headers: ((data['headers'] as Map?)?.cast<String, String>()) ?? <String, String>{},
        bodyTmpl: data['body'] as String?,
        sendJson: (data['sendJson'] as bool?) ?? true,
        parseJsonResponse: (data['parseJsonResponse'] as bool?) ?? true,
        savePath: (data['savePath'] as String?) ?? 'http.last',
        timeoutMs: (data['timeoutMs'] as num?)?.toInt() ?? 10000,
      ),
      applyToNode: (AbstractNode node, Map<String, dynamic> data) {
        if (node is HttpNode) {
          node
            ..title = (data['title'] as String?) ?? node.title
            ..method = HttpMethod.values.firstWhere(
                  (HttpMethod v) => v.name == (data['method'] as String? ?? node.method.name),
              orElse: () => node.method,
            )
            ..urlTmpl = (data['url'] as String?) ?? node.urlTmpl
            ..headers = ((data['headers'] as Map?)?.cast<String, String>()) ?? node.headers
            ..bodyTmpl = data['body'] as String?
            ..sendJson = (data['sendJson'] as bool?) ?? node.sendJson
            ..parseJsonResponse = (data['parseJsonResponse'] as bool?) ?? node.parseJsonResponse
            ..savePath = (data['savePath'] as String?) ?? node.savePath
            ..timeoutMs = (data['timeoutMs'] as num?)?.toInt() ?? node.timeoutMs;
        }
      },
    ),
  };
}
