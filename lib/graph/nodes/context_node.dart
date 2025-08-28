part of '../graph.dart';

class ContextNode extends AbstractNode implements ExecutableNode {
  String title;
  List<ContextAction> actions;

  @override
  String get nodeType => 'ContextNode';

  static const double _kPadY = 14.0;
  static const double _kHeaderH = 56.0;
  static const double _kDivTop = 10.0;
  static const double _kDivH = 1.0;
  static const double _kDivBottom = 8.0;
  static const double _kRowH = 28.0;
  static const double _kRowGap = 6.0;

  ContextNode({this.title = 'Context', List<ContextAction>? actions})
    : actions = actions ?? <ContextAction>[ContextAction(op: ContextOp.setValue, path: 'user.flag', value: true)];

  @override
  double get height {
    final int n = actions.length;
    final double body = (n == 0) ? 0.0 : (n * _kRowH + (n - 1) * _kRowGap);
    return _kPadY + _kHeaderH + _kDivTop + _kDivH + _kDivBottom + body + _kPadY;
  }

  int apply(Map<String, dynamic> ctx) {
    int applied = 0;
    for (final ContextAction a in actions) {
      switch (a.op) {
        case ContextOp.setValue:
          ctxSetPath(ctx, a.path, a.value);
          applied++;
          break;
        case ContextOp.increment:
          final num delta = (a.value is num) ? (a.value as num) : 1;
          final dynamic cur = ctxGetPath(ctx, a.path);
          final num next = (cur is num) ? (cur + delta) : delta;
          ctxSetPath(ctx, a.path, next);
          applied++;
          break;
        case ContextOp.toggleBool:
          final dynamic cur2 = ctxGetPath(ctx, a.path);
          final bool nextB = (cur2 is bool) ? !cur2 : true;
          ctxSetPath(ctx, a.path, nextB);
          applied++;
          break;
        case ContextOp.removeKey:
          ctxRemovePath(ctx, a.path);
          applied++;
          break;
        case ContextOp.mergeObject:
          final dynamic cur3 = ctxGetPath(ctx, a.path);
          final Map<String, dynamic> base = (cur3 is Map<String, dynamic>) ? cur3 : <String, dynamic>{};
          final Map<String, dynamic> add = (a.value is Map<String, dynamic>) ? (a.value as Map<String, dynamic>) : <String, dynamic>{};
          final Map<String, dynamic> merged = <String, dynamic>{...base, ...add};
          ctxSetPath(ctx, a.path, merged);
          applied++;
          break;
      }
    }
    return applied;
  }

  @override
  Widget draw(BuildContext context) {
    final ThemeData t = Theme.of(context);
    final ColorScheme cs = t.colorScheme;

    final double w = (width > 0) ? width : 320.0;
    final double h = height;

    String _opLabel(ContextOp op) => switch (op) {
      ContextOp.setValue => 'set',
      ContextOp.increment => 'inc',
      ContextOp.toggleBool => 'toggle',
      ContextOp.removeKey => 'remove',
      ContextOp.mergeObject => 'merge',
    };

    Widget _opChip(ContextOp op) {
      final String label = _opLabel(op);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cs.onSecondary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: cs.onSecondary.withOpacity(0.20)),
        ),
        child: Text(label, style: t.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
      );
    }

    Widget _valuePill(dynamic value) {
      if (value == null) {
        return const SizedBox.shrink();
      }
      final String v = value.toString();
      return Container(
        constraints: const BoxConstraints(minWidth: 0, maxWidth: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cs.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Text(
          v,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: t.textTheme.labelSmall?.copyWith(fontFamily: 'JetBrainsMono'),
        ),
      );
    }

    List<Widget> _actionRows() {
      return <Widget>[
        for (int i = 0; i < actions.length; i++) ...<Widget>[
          SizedBox(
            height: _kRowH,
            child: Row(
              children: <Widget>[
                _opChip(actions[i].op),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(actions[i].path, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.textTheme.bodySmall),
                ),
                const SizedBox(width: 8),
                _valuePill(actions[i].value),
              ],
            ),
          ),
          if (i != actions.length - 1) const SizedBox(height: _kRowGap),
        ],
      ];
    }

    return SizedBox(
      width: w,
      height: h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[cs.secondaryContainer.withOpacity(0.95), cs.secondary.withOpacity(0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.onSecondary.withOpacity(0.12)),
          boxShadow: <BoxShadow>[BoxShadow(color: cs.secondary.withOpacity(0.30), blurRadius: 22, offset: const Offset(0, 8))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(_kPadY),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                height: _kHeaderH,
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.onSecondary.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.onSecondary.withOpacity(0.18)),
                      ),
                      child: Icon(Icons.tune_rounded, color: cs.onSecondary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'CONTEXT',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.textTheme.labelSmall?.copyWith(letterSpacing: 1.1, fontWeight: FontWeight.w700, color: cs.onSecondary.withOpacity(0.9)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: _kDivTop),
              Container(height: _kDivH, color: cs.onSurface.withOpacity(0.06)),
              const SizedBox(height: _kDivBottom),
              ..._actionRows(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
    ...super.toMap(),
    'nodeType': nodeType,
    'title': title,
    'actions': <Map<String, dynamic>>[for (final ContextAction a in actions) a.toMap()],
  };

  @override
  AbstractNode fromMap(Map<String, dynamic> m) => ContextNode(
    title: (m['title'] as String?) ?? 'Context',
    actions: ((m['actions'] as List?) ?? const <dynamic>[]).cast<Map<String, dynamic>>().map(ContextAction.fromMap).toList(),
  );

  @override
  void executeBefore(Map<String, dynamic> ctx) {
    apply(ctx);
  }

  @override
  void executeAfter(Map<String, dynamic> ctx, {String? chosenPort}) {}

  @override
  String? choosePort(Map<String, dynamic> ctx) => null;
}
