part of '../graph.dart';

enum HttpMethod { get, post, put, patch, delete }

extension HttpMethodX on HttpMethod {
  String get label => switch (this) {
    HttpMethod.get => 'GET',
    HttpMethod.post => 'POST',
    HttpMethod.put => 'PUT',
    HttpMethod.patch => 'PATCH',
    HttpMethod.delete => 'DELETE',
  };
}

class HttpNode extends AbstractNode implements ExecutableNode, AsyncExecutableNode, ChoosePortNode  {
  String title;
  HttpMethod method;
  String urlTmpl;
  Map<String, String> headers;
  String? bodyTmpl;
  bool sendJson;
  bool parseJsonResponse;
  String savePath;
  int timeoutMs;
  List<String> ports = ["success", "error"];
  @override
  String get nodeType => 'HttpNode';

  double get height => 130;

  HttpNode({
    this.title = 'HTTP',
    this.method = HttpMethod.get,
    this.urlTmpl = 'https://api.example.com',
    Map<String, String>? headers,
    this.bodyTmpl,
    this.sendJson = true,
    this.parseJsonResponse = true,
    this.savePath = 'http.last',
    this.timeoutMs = 10000,
  }) : headers = headers ?? <String, String>{};

  @override
  void executeBefore(Map<String, dynamic> ctx) {
    executeBeforeAsync(ctx).then((_) {});
  }

  @override
  Future<void> executeBeforeAsync(Map<String, dynamic> ctx) async {
    final String url = _interpolate(urlTmpl, ctx);
    final Map<String, String> hdrs = <String, String>{};
    headers.forEach((String k, String v) {
      hdrs[_interpolate(k, ctx)] = _interpolate(v, ctx);
    });

    String? body;
    if (bodyTmpl != null && method != HttpMethod.get && method != HttpMethod.delete) {
      body = _interpolate(bodyTmpl!, ctx);
      if (sendJson && !hdrs.keys.map((k) => k.toLowerCase()).contains('content-type')) {
        hdrs['Content-Type'] = 'application/json';
      }
    }

    http.Response? resp;
    Object? error;
    try {
      final Uri uri = Uri.parse(url);
      Future<http.Response> fut = switch (method) {
        HttpMethod.get => http.get(uri, headers: hdrs),
        HttpMethod.delete => http.delete(uri, headers: hdrs),
        HttpMethod.post => http.post(uri, headers: hdrs, body: body),
        HttpMethod.put => http.put(uri, headers: hdrs, body: body),
        HttpMethod.patch => http.patch(uri, headers: hdrs, body: body),
      };
      resp = await fut.timeout(Duration(milliseconds: timeoutMs));
    } catch (e) {
      error = e;
    }

    final Map<String, dynamic> result = <String, dynamic>{
      'ok': resp != null && resp.statusCode >= 200 && resp.statusCode < 300,
      'status': resp?.statusCode,
      'url': url,
      'headers': resp?.headers,
      'body': resp?.body,
      'error': error?.toString(),
    };

    if (parseJsonResponse && resp?.body != null) {
      try {
        result['json'] = jsonDecode(resp!.body);
      } catch (_) {
      }
    }
    ctxSetPath(ctx, savePath, result);
  }

  @override
  String? choosePort(Map<String, dynamic> ctx) {
    final dynamic v = ctxGetPath(ctx, savePath);
    if (v is Map && (v['ok'] == true)) return 'success';
    return 'error';
  }

  @override
  void executeAfter(Map<String, dynamic> ctx, {String? chosenPort}) {}

  @override
  Future<void> executeAfterAsync(Map<String, dynamic> ctx, {String? chosenPort}) async {}

  @override
  List<String> getPorts() {
    return ports;
  }

  // --------- Visuals ----------
  @override
  Widget draw(BuildContext context) {
    final ThemeData t = Theme.of(context);
    final ColorScheme cs = t.colorScheme;
    final double w = width > 0 ? width : 300;
    final double h = height > 0 ? height : 140;

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
                    child: Icon(Icons.http_rounded, color: cs.onPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'HTTP',
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
                      method.label,
                      style: t.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: cs.onPrimary, letterSpacing: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _truncateMiddle(urlTmpl, 60),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.textTheme.bodySmall?.copyWith(color: cs.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                '→ $savePath',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.textTheme.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.8)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _truncateMiddle(String s, int max) {
    if (s.length <= max) return s;
    final int keep = (max - 3) ~/ 2;
    return '${s.substring(0, keep)}…${s.substring(s.length - keep)}';
  }

  String _interpolate(String template, Map<String, dynamic> ctx) {
    return template.replaceAllMapped(RegExp(r'\$\{([^}]+)\}'), (Match m) {
      final String path = m.group(1)!.trim();
      final dynamic v = ctxGetPath(ctx, path);
      return (v == null) ? '' : '$v';
    });
  }

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
    ...super.toMap(),
    'title': title,
    'method': method.name,
    'url': urlTmpl,
    'headers': headers,
    'body': bodyTmpl,
    'sendJson': sendJson,
    'parseJsonResponse': parseJsonResponse,
    'savePath': savePath,
    'timeoutMs': timeoutMs,
  };

  @override
  AbstractNode fromMap(Map<String, dynamic> m) => HttpNode(
    title: (m['title'] as String?) ?? 'HTTP',
    method: HttpMethod.values.firstWhere((HttpMethod v) => v.name == (m['method'] as String? ?? 'get'), orElse: () => HttpMethod.get),
    urlTmpl: (m['url'] as String?) ?? 'https://api.example.com',
    headers: ((m['headers'] as Map?)?.cast<String, String>()) ?? <String, String>{},
    bodyTmpl: m['body'] as String?,
    sendJson: (m['sendJson'] as bool?) ?? true,
    parseJsonResponse: (m['parseJsonResponse'] as bool?) ?? true,
    savePath: (m['savePath'] as String?) ?? 'http.last',
    timeoutMs: (m['timeoutMs'] as num?)?.toInt() ?? 10000,
  );
}
