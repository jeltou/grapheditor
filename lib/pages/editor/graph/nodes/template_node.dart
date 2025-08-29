part of '../graph.dart';

class TemplateNode extends AbstractNode implements ExecutableNode {
  String title;
  String template;
  String outPath;
  bool nullAsEmpty;

  @override
  String get nodeType => 'TemplateNode';

  TemplateNode({this.title = 'Template', this.template = '', this.outPath = 'result', this.nullAsEmpty = true});

  static String renderTemplate(String tpl, Map<String, dynamic> ctx, {bool nullAsEmpty = true}) {
    final RegExp re = RegExp(r'{{\s*([a-zA-Z_][\w\.]*)\s*}}');
    return tpl.replaceAllMapped(re, (Match m) {
      final String path = m.group(1)!;
      final dynamic v = ctxGetPath(ctx, path);
      if (v == null) return nullAsEmpty ? '' : 'null';
      return '$v';
    });
  }

  @override
  void executeBefore(Map<String, dynamic> ctx) {
    final String rendered = renderTemplate(template, ctx, nullAsEmpty: nullAsEmpty);
    ctxSetPath(ctx, outPath, rendered);
  }

  @override
  void executeAfter(Map<String, dynamic> ctx, {String? chosenPort}) {}


  @override
  double get height {
    final int lines = template.split('\n').length.clamp(1, 6);
    final double base = 88;
    final double perLine = 18;
    return (super.height > 0) ? super.height : (base + lines * perLine);
  }

  @override
  double get width {
    return (super.width > 0) ? super.width : 320;
  }

  @override
  Widget draw(BuildContext context) {
    final ThemeData t = Theme.of(context);
    final ColorScheme cs = t.colorScheme;

    final String preview = template.trim().isEmpty ? '— no template —' : template.split('\n').take(6).join('\n');

    return SizedBox(
      width: width,
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
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Header
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
                    child: Icon(Icons.short_text_rounded, color: cs.onPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'TEMPLATE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.onPrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: cs.onPrimary.withOpacity(0.18)),
                    ),
                    child: Text(
                      outPath,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: cs.onPrimary, letterSpacing: 0.4),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Container(height: 1, color: cs.onSurface.withOpacity(0.06)),
              const SizedBox(height: 8),

              // Preview
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cs.surface.withOpacity(0.45),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Text(preview.isEmpty ? ' ' : preview, style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.3)),
                  ),
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
    'title': title,
    'template': template,
    'outPath': outPath,
    'nullAsEmpty': nullAsEmpty,
  };

  @override
  AbstractNode fromMap(Map<String, dynamic> m) => TemplateNode(
    title: (m['title'] as String?) ?? 'Template',
    template: (m['template'] as String?) ?? '',
    outPath: (m['outPath'] as String?) ?? 'result',
    nullAsEmpty: (m['nullAsEmpty'] as bool?) ?? true,
  );
}
