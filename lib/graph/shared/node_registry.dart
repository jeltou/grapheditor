part of '../graph.dart';

Map<String, NodeFactory> _ensureFactories(Map<String, NodeFactory>? factories) {
  return factories ?? defaultNodeDecoders();
}

class NodeTypeDescriptor {
  final String type;
  final String displayName;
  final Widget Function(BuildContext, Map<String, dynamic>) buildSection;
  final AbstractNode Function(Map<String, dynamic>) buildNode;
  final void Function(AbstractNode node, Map<String, dynamic> data)? applyToNode;

  const NodeTypeDescriptor({required this.type, required this.displayName, required this.buildSection, required this.buildNode, this.applyToNode});
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
  };
}
