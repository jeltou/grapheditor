part of '../graph.dart';

enum ContextOp {
  setValue,
  increment,
  toggleBool,
  removeKey,
  mergeObject,
}

class ContextAction {
  final ContextOp op;
  final String path;
  final dynamic value;

  const ContextAction({
    required this.op,
    required this.path,
    this.value,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'op': op.name,
    'path': path,
    'value': value,
  };

  static ContextAction fromMap(Map<String, dynamic> m) {
    final String opName = (m['op'] as String?) ?? ContextOp.setValue.name;
    final ContextOp op = ContextOp.values.firstWhere(
          (ContextOp o) => o.name == opName,
      orElse: () => ContextOp.setValue,
    );
    return ContextAction(op: op, path: (m['path'] as String?) ?? '', value: m['value']);
  }
}