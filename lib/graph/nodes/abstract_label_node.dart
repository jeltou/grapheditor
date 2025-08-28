part of '../graph.dart';

abstract class AbstractLabelNode extends AbstractNode {
  String label;
  @override

  String get nodeType => "AbstractLabelNode";

  AbstractLabelNode({required this.label});

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{...super.toMap(), 'label': label};
  }

  @override
  AbstractNode fromMap(Map<String, dynamic> m) {
    return DefaultNode(label: (m['label'] as String?) ?? 'Label');
  }
}
