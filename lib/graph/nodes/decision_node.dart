part of '../graph.dart';

class DecisionNode extends AbstractNode implements ExecutableNode {
  String title;
  List<DecisionBranch> branches;

  static const double _kPad = 14.0 * 2;
  static const double _kHeaderH = 56.0;
  static const double _kDividerH = 9.0;
  static const double _kRowH = 44.0;

  @override
  String get nodeType => 'DecisionNode';

  @override
  double get height {
    final double rows = (branches.isEmpty ? 1 : branches.length) * _kRowH + 10;
    return _kPad + _kHeaderH + _kDividerH + rows;
  }

  DecisionNode({this.title = 'Decision', List<DecisionBranch>? branches})
    : branches = branches ?? <DecisionBranch>[DecisionBranch(name: 'yes'), DecisionBranch(name: 'no')];

  @override
  Widget draw(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    Widget branchRow(DecisionBranch b) {
      final String summary = summarizeBranch(b);
      return SizedBox(
        height: _kRowH,
        child: Row(
          children: <Widget>[
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
            ),

            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 60, maxWidth: 120),
              child: Text(
                b.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
              ),
            ),
            const SizedBox(width: 8),

            Expanded(
              child: Tooltip(
                message: summary,
                waitDuration: const Duration(milliseconds: 300),
                preferBelow: false,
                child: Text(
                  summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.85)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final double nodeW = (width > 0) ? width : 320.0;
    final double nodeH = height;

    return SizedBox(
      width: nodeW,
      height: nodeH,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[cs.tertiaryContainer.withOpacity(0.95), cs.tertiary.withOpacity(0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.onTertiary.withOpacity(0.12)),
            boxShadow: <BoxShadow>[BoxShadow(color: cs.tertiary.withOpacity(0.30), blurRadius: 22, offset: const Offset(0, 8))],
          ),
          child: Stack(
            children: <Widget>[
              Positioned(right: -8, bottom: -8, child: Icon(Icons.device_hub_rounded, size: 96, color: cs.onTertiary.withOpacity(0.08))),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      height: _kHeaderH,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: cs.onTertiary.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(color: cs.onTertiary.withOpacity(0.18)),
                            ),
                            child: Icon(Icons.device_hub_rounded, color: cs.onTertiary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'DECISION',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onTertiary.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onTertiary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                    Container(height: 1, color: cs.onSurface.withOpacity(0.06)),
                    const SizedBox(height: 8),
                    for (final DecisionBranch b in (branches.isEmpty ? <DecisionBranch>[DecisionBranch(name: '—')] : branches)) branchRow(b),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  String? choosePort(Map<String, dynamic> ctx) {
    return pickBranch(ctx);
  }

  @override
  void executeBefore(Map<String, dynamic> ctx) {}

  @override
  void executeAfter(Map<String, dynamic> ctx, {String? chosenPort}) {}

  String? pickBranch(Map<String, dynamic> ctx) {
    for (final DecisionBranch b in branches) {
      if (_evalBranch(b, ctx)) return b.name;
    }
    return null;
  }

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
    ...super.toMap(),
    'nodeType': nodeType,
    'title': title,
    'branches': branches.map((DecisionBranch b) => b.toMap()).toList(),
  };

  @override
  AbstractNode fromMap(Map<String, dynamic> m) => DecisionNode(
    title: (m['title'] as String?) ?? 'Decision',
    branches: ((m['branches'] as List?) ?? const <dynamic>[]).cast<Map<String, dynamic>>().map(DecisionBranch.fromMap).toList(),
  );

  bool _evalBranch(DecisionBranch b, Map<String, dynamic> ctx) {
    if (b.rules.isEmpty) return false;
    if (b.groupOp == ConditionGroupOp.all) {
      for (final ConditionRule r in b.rules) {
        if (!_evalRule(r, ctx)) return false;
      }
      return true;
    } else {
      for (final ConditionRule r in b.rules) {
        if (_evalRule(r, ctx)) return true;
      }
      return false;
    }
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

  bool _evalRule(ConditionRule r, Map<String, dynamic> ctx) {
    final dynamic left = ctxGet(ctx, r.leftKey);
    final dynamic right = r.rightValue;
    final (num? ln, String? ls, bool? lb) = _coerce(left);
    final (num? rn, String? rs, bool? rb) = _coerce(right);

    switch (r.op) {
      case ConditionOp.eq:
        return left == right || (ln != null && rn != null && ln == rn) || (lb != null && rb != null && lb == rb) || (ls != null && rs != null && ls == rs);
      case ConditionOp.ne:
        return !(ConditionRule(leftKey: r.leftKey, op: ConditionOp.eq, rightValue: r.rightValue).let((ConditionRule rr) => _evalRule(rr, ctx)));
      case ConditionOp.gt:
        return (ln != null && rn != null) && (ln > rn);
      case ConditionOp.gte:
        return (ln != null && rn != null) && (ln >= rn);
      case ConditionOp.lt:
        return (ln != null && rn != null) && (ln < rn);
      case ConditionOp.lte:
        return (ln != null && rn != null) && (ln <= rn);
      case ConditionOp.contains:
        if (ls != null && rs != null) return ls.contains(rs);
        if (left is Iterable) return left.contains(right);
        return false;
      case ConditionOp.startsWith:
        return (ls != null && rs != null) && ls.startsWith(rs);
      case ConditionOp.endsWith:
        return (ls != null && rs != null) && ls.endsWith(rs);
    }
  }
}
