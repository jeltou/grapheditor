part of '../graph.dart';

class TestContext with GraphObjectShared {
  String id;
  String name;
  String json;

  TestContext({String? id, required this.name, required this.json}) : id = id ?? '' {
    if (this.id.isEmpty) {
      this.id = generateMewId();
    }
  }

  Map<String, dynamic>? tryParse() {
    try {
      final dynamic d = jsonDecode(json);
      if (d is Map<String, dynamic>) return d;
      return <String, dynamic>{'value': d};
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toMap() => <String, dynamic>{'id': id, 'name': name, 'json': json};

  static TestContext fromMap(Map<String, dynamic> m) => TestContext(
    id: (m['id'] as String?) ?? 'CTX${DateTime.now().microsecondsSinceEpoch}',
    name: (m['name'] as String?) ?? 'Context',
    json: (m['json'] as String?) ?? '{}',
  );
}
