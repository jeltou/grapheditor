part of '../graph.dart';

class RootNode extends AbstractLabelNode {
  @override
  String get nodeType => "RootNode";

  RootNode({required super.label});

  @override
  Widget draw(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final Gradient gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[cs.primaryContainer.withOpacity(0.95), cs.primary.withOpacity(0.85)],
    );
    return NodeScaffold(
      nodeName: "ROOT",
      icon: Icons.account_tree_rounded,
      width: width,
      height: height,
      gradient: gradient,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onPrimary),
      ),
    );
  }

  @override
  AbstractNode fromMap(Map<String, dynamic> m) {
    return RootNode(label: (m['label'] as String?) ?? 'Label');
  }
}
