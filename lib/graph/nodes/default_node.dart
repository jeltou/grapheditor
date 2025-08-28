part of '../graph.dart';

class DefaultNode extends AbstractLabelNode {
  String get nodeType => "DefaultNode";

  DefaultNode({required super.label});

  @override
  Widget draw(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    final Gradient gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[cs.secondaryContainer.withOpacity(0.95), cs.secondary.withOpacity(0.85)],
    );
    return NodeScaffold(
      nodeName: "DEFAULT",
      icon: Icons.widgets_rounded,
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
    return DefaultNode(label: (m['label'] as String?) ?? 'Label');
  }
}
