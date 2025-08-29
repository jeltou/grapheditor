part of '../graph.dart';

class MapperNode extends AbstractNode implements ExecutableNode {
  String title;
  List<MapperRule> rules;
  static const double _kPad = 14.0 * 2;
  static const double _kHeaderH = 56.0;
  static const double _kDividerH = 9.0;
  static const double _kRuleheight = 30;

  @override
  String get nodeType => 'MapperNode';

  @override
  double get height {
    return _kHeaderH + _kPad + _kDividerH + (_kRuleheight * rules.length);
  }

  MapperNode({this.title = 'Map Context', List<MapperRule>? rules}) : rules = rules ?? <MapperRule>[MapperRule(from: 'a', to: 'b')];

  int apply(Map<String, dynamic> ctx) {
    int applied = 0;
    for (final MapperRule r in rules) {
      if (r.from.isEmpty || r.to.isEmpty) continue;

      final dynamic value = ctxGetPath(ctx, r.from);
      if (value == null && r.skipIfNull) {
        continue;
      }

      if (!r.overwrite) {
        final dynamic exists = ctxGetPath(ctx, r.to);
        if (exists != null) {
          continue;
        }
      }

      ctxSetPath(ctx, r.to, value);
      if (r.move) {
        ctxRemovePath(ctx, r.from);
      }
      applied++;
    }
    return applied;
  }

  @override
  void executeBefore(Map<String, dynamic> ctx) {
    apply(ctx);
  }

  @override
  void executeAfter(Map<String, dynamic> ctx, {String? chosenPort}) {}

  @override
  Widget draw(BuildContext context) {
    final ThemeData t = Theme.of(context);
    final ColorScheme cs = t.colorScheme;
    const double pad = 14;

    return SizedBox(
      width: super.width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[cs.primaryContainer.withOpacity(0.95), cs.primary.withOpacity(0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.onPrimary.withOpacity(0.12)),
          boxShadow: <BoxShadow>[BoxShadow(color: cs.primary.withOpacity(0.30), blurRadius: 22, offset: const Offset(0, 8))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // header
              Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.onPrimary.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.onPrimary.withOpacity(0.18)),
                    ),
                    child: Icon(Icons.compare_arrows_rounded, color: cs.onPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'MAPPER',
                          style: t.textTheme.labelSmall?.copyWith(letterSpacing: 1.1, fontWeight: FontWeight.w700, color: cs.onPrimary.withOpacity(0.9)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onPrimary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.onPrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: cs.onPrimary.withOpacity(0.18)),
                    ),
                    child: Text(
                      '${rules.length} rule${rules.length == 1 ? '' : 's'}',
                      style: t.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: cs.onPrimary, letterSpacing: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(height: 1, color: cs.onSurface.withOpacity(0.06)),
              const SizedBox(height: 8),

              // rules
              Expanded(
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rules.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (BuildContext _, int i) {
                    final MapperRule r = rules[i];
                    final String flags = [if (r.move) 'move', if (!r.overwrite) 'no-overwrite', if (r.skipIfNull) 'skip-null'].join(' · ');
                    return Text(
                      '${r.from}  →  ${r.to}${flags.isEmpty ? '' : '  [$flags]'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.textTheme.bodySmall?.copyWith(color: cs.onSurface),
                    );
                  },
                ),
              ),
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
    'rules': <Map<String, dynamic>>[for (final MapperRule r in rules) r.toMap()],
  };

  @override
  AbstractNode fromMap(Map<String, dynamic> m) => MapperNode(
    title: (m['title'] as String?) ?? 'Map Context',
    rules: ((m['rules'] as List?) ?? const <dynamic>[]).cast<Map<String, dynamic>>().map(MapperRule.fromMap).toList(),
  );
}
