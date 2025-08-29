part of '../graph.dart';

class MapperRule {
  final String from;
  final String to;
  final bool move;        // delete source after copy
  final bool overwrite;   // overwrite destination if already set
  final bool skipIfNull;  // skip when source resolves to null

  MapperRule({
    required this.from,
    required this.to,
    this.move = false,
    this.overwrite = true,
    this.skipIfNull = true,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'from': from,
    'to': to,
    'move': move,
    'overwrite': overwrite,
    'skipIfNull': skipIfNull,
  };

  static MapperRule fromMap(Map<String, dynamic> m) => MapperRule(
    from: (m['from'] as String? ?? '').trim(),
    to: (m['to'] as String? ?? '').trim(),
    move: m['move'] as bool? ?? false,
    overwrite: m['overwrite'] as bool? ?? true,
    skipIfNull: m['skipIfNull'] as bool? ?? true,
  );
}