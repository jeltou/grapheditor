part of '../graph.dart';

enum MathRounding { none, round, floor, ceil }

enum MathExpTokType { number, ident, op, lpar, rpar }

class MathExpTok {
  final MathExpTokType type;
  final String lex;

  MathExpTok(this.type, this.lex);
}

class MathNode extends AbstractNode implements ExecutableNode {
  String title;
  String expr;
  String outPath;
  MathRounding rounding;
  int? precision;

  @override
  String get nodeType => 'MathNode';

  @override
  double get height {
    return 150;
  }

  MathNode({this.title = 'Math', required this.expr, required this.outPath, this.rounding = MathRounding.none, this.precision});

  @override
  void executeBefore(Map<String, dynamic> ctx) {
    final num value = evaluate(expr, ctx);
    final num finalValue = applyRounding(value);
    ctxSetPath(ctx, outPath, finalValue);
  }

  @override
  void executeAfter(Map<String, dynamic> ctx, {String? chosenPort}) {}

  @override
  String? choosePort(Map<String, dynamic> ctx) => null; // nur DefaultEdge

  num evaluate(String expression, Map<String, dynamic> ctx) {
    final List<MathExpTok> toks = tokenize(expression);
    final List<MathExpTok> rpn = toReversePolishNotation(toks);
    return evalReversePolishNotation(rpn, ctx);
  }

  List<MathExpTok> tokenize(String s) {
    final List<MathExpTok> out = <MathExpTok>[];
    int i = 0;
    MathExpTokType? prevType;

    bool isIdStart(int c) => (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95; // A-Z a-z _
    bool isIdCont(int c) => isIdStart(c) || (c >= 48 && c <= 57) || c == 46;
    bool isDigit(int c) => (c >= 48 && c <= 57); // 0-9

    while (i < s.length) {
      final int c = s.codeUnitAt(i);

      if (c == 32 || c == 9 || c == 10 || c == 13) {
        i++;
        continue;
      }

      if (isDigit(c) || (c == 46 && i + 1 < s.length && isDigit(s.codeUnitAt(i + 1)))) {
        int j = i + 1;
        bool hasDot = (c == 46);
        while (j < s.length) {
          final int d = s.codeUnitAt(j);
          if (d == 46) {
            if (hasDot) break;
            hasDot = true;
            j++;
            continue;
          }
          if (!isDigit(d)) break;
          j++;
        }
        out.add(MathExpTok(MathExpTokType.number, s.substring(i, j)));
        prevType = MathExpTokType.number;
        i = j;
        continue;
      }

      if (isIdStart(c)) {
        // key from the context
        int j = i + 1;
        while (j < s.length && isIdCont(s.codeUnitAt(j))) {
          j++;
        }
        out.add(MathExpTok(MathExpTokType.ident, s.substring(i, j)));
        prevType = MathExpTokType.ident;
        i = j;
        continue;
      }

      // parentheses
      if (c == 40) {
        // '('
        out.add(MathExpTok(MathExpTokType.lpar, '('));
        prevType = MathExpTokType.lpar;
        i++;
        continue;
      }
      if (c == 41) {
        // ')'
        out.add(MathExpTok(MathExpTokType.rpar, ')'));
        prevType = MathExpTokType.rpar;
        i++;
        continue;
      }

      // operators + - * / %
      if (c == 43) {
        out.add(MathExpTok(MathExpTokType.op, '+'));
        prevType = MathExpTokType.op;
        i++;
        continue;
      } // +
      if (c == 45) {
        // -
        // unary minus?
        final bool unary = (prevType == null || prevType == MathExpTokType.op || prevType == MathExpTokType.lpar);
        out.add(MathExpTok(MathExpTokType.op, unary ? 'u-' : '-'));
        prevType = MathExpTokType.op;
        i++;
        continue;
      }
      if (c == 42) {
        out.add(MathExpTok(MathExpTokType.op, '*'));
        prevType = MathExpTokType.op;
        i++;
        continue;
      } // *
      if (c == 47) {
        out.add(MathExpTok(MathExpTokType.op, '/'));
        prevType = MathExpTokType.op;
        i++;
        continue;
      } // /
      if (c == 37) {
        out.add(MathExpTok(MathExpTokType.op, '%'));
        prevType = MathExpTokType.op;
        i++;
        continue;
      } // %

      i++;
    }
    return out;
  }

  //--- Convert Expression to Reverse Polish Notation-----------------------------------------------------------

  // https://de.wikipedia.org/wiki/Umgekehrte_polnische_Notation
  // https://de.wikipedia.org/wiki/Shunting-yard-Algorithmus
  // Shunting-yard: to RPN
  static final Map<String, (int prec, bool right)> _prec = <String, (int, bool)>{
    'u-': (4, true),
    '*': (3, false),
    '/': (3, false),
    '%': (3, false),
    '+': (2, false),
    '-': (2, false),
  };

  List<MathExpTok> toReversePolishNotation(List<MathExpTok> t) {
    final List<MathExpTok> out = <MathExpTok>[];
    final List<MathExpTok> ops = <MathExpTok>[];

    for (final MathExpTok x in t) {
      switch (x.type) {
        case MathExpTokType.number:
        case MathExpTokType.ident:
          out.add(x);
          break;
        case MathExpTokType.op:
          final (int p, bool right) = _prec[x.lex]!;

          while (ops.isNotEmpty && ops.last.type == MathExpTokType.op) {
            final (int p2, bool right2) = _prec[ops.last.lex]!;
            if ((right && p < p2) || (!right && p <= p2)) {
              out.add(ops.removeLast());
            } else {
              break;
            }
          }
          ops.add(x);
          break;
        case MathExpTokType.lpar:
          ops.add(x);
          break;
        case MathExpTokType.rpar:
          while (ops.isNotEmpty && ops.last.type != MathExpTokType.lpar) {
            out.add(ops.removeLast());
          }
          if (ops.isNotEmpty && ops.last.type == MathExpTokType.lpar) ops.removeLast(); // pop '('
          break;
      }
    }
    while (ops.isNotEmpty) {
      out.add(ops.removeLast());
    }
    return out;
  }

  num evalReversePolishNotation(List<MathExpTok> rpn, Map<String, dynamic> ctx) {
    final List<num> st = <num>[];
    for (final MathExpTok x in rpn) {
      switch (x.type) {
        case MathExpTokType.number:
          st.add(asNum(x.lex));
          break;
        case MathExpTokType.ident:
          final dynamic v = ctxGetPath(ctx, x.lex);
          st.add(asNum(v));
          break;
        case MathExpTokType.op:
          if (x.lex == 'u-') {
            final num a = st.removeLast();
            st.add(-a);
          } else {
            final num b = st.removeLast();
            final num a = st.removeLast();
            switch (x.lex) {
              case '+':
                st.add(a + b);
                break;
              case '-':
                st.add(a - b);
                break;
              case '*':
                st.add(a * b);
                break;
              case '/':
                st.add(b == 0 ? 0 : a / b);
                break;
              case '%':
                st.add(b == 0 ? 0 : a % b);
                break;
            }
          }
          break;
        default:
          break;
      }
    }
    return st.isEmpty ? 0 : st.last;
  }

  num asNum(dynamic v) {
    if (v is num) return v;
    if (v is String) {
      final num? n = num.tryParse(v);
      if (n != null) return n;
    }
    return 0;
  }

  num applyRounding(num v) {
    switch (rounding) {
      case MathRounding.none:
        return v;
      case MathRounding.floor:
        return v.floor();
      case MathRounding.ceil:
        return v.ceil();
      case MathRounding.round:
        final int p = (precision ?? 0).clamp(0, 10);
        return num.parse(v.toStringAsFixed(p));
    }
  }

  // ---------- UI ----------
  @override
  Widget draw(BuildContext context) {
    final ThemeData t = Theme.of(context);
    final ColorScheme cs = t.colorScheme;
    final double w = width > 0 ? width : 280;
    final double h = height > 0 ? height : 140;

    String roundLabel() {
      return switch (rounding) {
        MathRounding.none => 'no rounding',
        MathRounding.floor => 'floor',
        MathRounding.ceil => 'ceil',
        MathRounding.round => 'round(${precision ?? 0})',
      };
    }

    return SizedBox(
      width: w,
      height: h,
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
                    child: Icon(Icons.calculate_outlined, color: cs.onPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'MATH',
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
                ],
              ),
              const SizedBox(height: 10),
              Container(height: 1, color: cs.onSurface.withOpacity(0.06)),
              const SizedBox(height: 8),
              Text(
                'expr: $expr',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: t.textTheme.bodySmall?.copyWith(color: cs.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'out → $outPath',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.textTheme.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.85)),
              ),
              const SizedBox(height: 4),
              Text(
                'round → ${roundLabel()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.textTheme.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.85)),
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
    'expr': expr,
    'outPath': outPath,
    'rounding': rounding.name,
    'precision': precision,
  };

  @override
  AbstractNode fromMap(Map<String, dynamic> m) => MathNode(
    title: (m['title'] as String?) ?? 'Math',
    expr: (m['expr'] as String?) ?? '',
    outPath: (m['outPath'] as String?) ?? 'result',
    rounding: _roundingFromName((m['rounding'] as String?) ?? 'none'),
    precision: (m['precision'] as num?)?.toInt(),
  );

  static MathRounding _roundingFromName(String s) {
    return MathRounding.values.firstWhere((MathRounding e) => e.name == s, orElse: () => MathRounding.none);
  }
}
