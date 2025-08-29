part of '../graph.dart';

enum ConditionGroupOp { all, any }

enum ConditionOp { eq, ne, gt, gte, lt, lte, contains, startsWith, endsWith }

String opText(ConditionOp op) {
  switch (op) {
    case ConditionOp.eq:
      return '==';
    case ConditionOp.ne:
      return '!=';
    case ConditionOp.gt:
      return '>';
    case ConditionOp.gte:
      return '>=';
    case ConditionOp.lt:
      return '<';
    case ConditionOp.lte:
      return '<=';
    case ConditionOp.contains:
      return 'contains';
    case ConditionOp.startsWith:
      return 'startsWith';
    case ConditionOp.endsWith:
      return 'endsWith';
  }
}

String summarizeBranch(DecisionBranch b) {
  if (b.rules.isEmpty) return 'No rules';
  final String joiner = (b.groupOp == ConditionGroupOp.all) ? ' AND ' : ' OR ';
  final List<String> parts = <String>[for (final ConditionRule r in b.rules) '${r.leftKey} ${opText(r.op)} ${dynamic2String(r.rightValue)}'];
  return parts.join(joiner);
}

String dynamic2String(dynamic v) {
  if (v == null) return 'null';
  if (v is String) return v.isEmpty ? '""' : v;
  return '$v';
}

class ConditionRule {
  final String leftKey;
  final ConditionOp op;
  final dynamic rightValue;

  ConditionRule({required this.leftKey, required this.op, required this.rightValue});

  Map<String, dynamic> toMap() => <String, dynamic>{'leftKey': leftKey, 'op': op.name, 'rightValue': rightValue};

  static ConditionRule fromMap(Map<String, dynamic> m) =>
      ConditionRule(leftKey: m['leftKey'] as String, op: ConditionOp.values.firstWhere((ConditionOp e) => e.name == m['op']), rightValue: m['rightValue']);
}

class DecisionBranch {
  String name;
  ConditionGroupOp groupOp;
  List<ConditionRule> rules;

  DecisionBranch({required this.name, this.groupOp = ConditionGroupOp.all, List<ConditionRule>? rules}) : rules = rules ?? <ConditionRule>[];

  Map<String, dynamic> toMap() => <String, dynamic>{'name': name, 'groupOp': groupOp.name, 'rules': rules.map((ConditionRule r) => r.toMap()).toList()};

  static DecisionBranch fromMap(Map<String, dynamic> m) => DecisionBranch(
    name: m['name'] as String,
    groupOp: ConditionGroupOp.values.firstWhere((ConditionGroupOp e) => e.name == m['groupOp']),
    rules: ((m['rules'] as List?) ?? const <dynamic>[]).cast<Map<String, dynamic>>().map(ConditionRule.fromMap).toList(),
  );
}

dynamic ctxGet(Map<String, dynamic> ctx, String path) {
  final List<String> parts = path.split('.');
  dynamic cur = ctx;
  for (final String p in parts) {
    if (cur is Map && cur.containsKey(p)) {
      cur = cur[p];
    } else {
      return null;
    }
  }
  return cur;
}

(num?, String?, bool?) _coerce(dynamic v) {
  if (v is num) return (v, null, null);
  if (v is bool) return (null, null, v);
  if (v is String) {
    final num? n = num.tryParse(v);
    if (n != null) return (n, null, null);
    if (v.toLowerCase() == 'true') return (null, null, true);
    if (v.toLowerCase() == 'false') return (null, null, false);
    return (null, v, null);
  }
  return (null, v?.toString(), null);
}

bool evalRule(ConditionRule r, Map<String, dynamic> ctx) {
  final dynamic left = ctxGet(ctx, r.leftKey);
  final dynamic right = r.rightValue;

  final (num? ln, String? ls, bool? lb) = _coerce(left);
  final (num? rn, String? rs, bool? rb) = _coerce(right);

  switch (r.op) {
    case ConditionOp.eq:
      return left == right || (ln != null && rn != null && ln == rn) || (lb != null && rb != null && lb == rb) || (ls != null && rs != null && ls == rs);
    case ConditionOp.ne:
      return !evalRule(ConditionRule(leftKey: r.leftKey, op: ConditionOp.eq, rightValue: r.rightValue), ctx);
    case ConditionOp.gt:
      if (ln != null && rn != null) return ln > rn;
      return false;
    case ConditionOp.gte:
      if (ln != null && rn != null) return ln >= rn;
      return false;
    case ConditionOp.lt:
      if (ln != null && rn != null) return ln < rn;
      return false;
    case ConditionOp.lte:
      if (ln != null && rn != null) return ln <= rn;
      return false;
    case ConditionOp.contains:
      if (ls != null && rs != null) return ls.contains(rs);
      if (left is Iterable) return left.contains(right);
      return false;
    case ConditionOp.startsWith:
      if (ls != null && rs != null) return ls.startsWith(rs);
      return false;
    case ConditionOp.endsWith:
      if (ls != null && rs != null) return ls.endsWith(rs);
      return false;
  }
}

bool evalBranch(DecisionBranch b, Map<String, dynamic> ctx) {
  if (b.rules.isEmpty) return false;
  if (b.groupOp == ConditionGroupOp.all) {
    for (final ConditionRule r in b.rules) {
      if (!evalRule(r, ctx)) return false;
    }
    return true;
  } else {
    for (final ConditionRule r in b.rules) {
      if (evalRule(r, ctx)) return true;
    }
    return false;
  }
}
