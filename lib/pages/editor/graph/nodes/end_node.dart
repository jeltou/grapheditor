part of '../graph.dart';

class EndNode extends AbstractLabelNode {
  EndNode({required super.label});

  @override
  String get nodeType => "EndNode";

  @override
  Widget draw(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final Gradient gradient = LinearGradient(
      colors: <Color>[cs.errorContainer.withOpacity(0.95), cs.error.withOpacity(0.85)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return NodeScaffold(
      nodeName: "END",
      icon: Icons.stop_circle_rounded,
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
    return EndNode(label: (m['label'] as String?) ?? 'Label');
  }
}
