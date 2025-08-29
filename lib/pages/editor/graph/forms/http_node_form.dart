part of '../graph.dart';

class HttpNodeForm extends StatefulWidget {
  final Map<String, dynamic> data;
  const HttpNodeForm({super.key, required this.data});

  @override
  State<HttpNodeForm> createState() => _HttpNodeFormState();
}

class _HttpNodeFormState extends State<HttpNodeForm> {
  late TextEditingController _title;
  late TextEditingController _url;
  late TextEditingController _body;
  late TextEditingController _savePath;
  late TextEditingController _timeout;

  HttpMethod _method = HttpMethod.get;
  bool _sendJson = true;
  bool _parseJsonResponse = true;
  List<MapEntry<String, String>> _headers = <MapEntry<String, String>>[];

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: (widget.data['title'] as String?) ?? 'HTTP');
    _url = TextEditingController(text: (widget.data['url'] as String?) ?? 'https://dummyjson.com/test');
    _body = TextEditingController(text: (widget.data['body'] as String?) ?? '');
    _savePath = TextEditingController(text: (widget.data['savePath'] as String?) ?? 'http.last');
    _timeout = TextEditingController(text: '${(widget.data['timeoutMs'] as num?)?.toInt() ?? 10000}');

    final String m = (widget.data['method'] as String?) ?? 'get';
    _method = HttpMethod.values.firstWhere((HttpMethod v) => v.name == m, orElse: () => HttpMethod.get);

    _sendJson = (widget.data['sendJson'] as bool?) ?? true;
    _parseJsonResponse = (widget.data['parseJsonResponse'] as bool?) ?? true;

    final Map<String, String> hdrs = ((widget.data['headers'] as Map?)?.cast<String, String>()) ?? <String, String>{};
    _headers = hdrs.entries.toList();

    _sync();
  }

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    _body.dispose();
    _savePath.dispose();
    _timeout.dispose();
    super.dispose();
  }

  void _sync() {
    widget.data['title'] = _title.text.trim();
    widget.data['method'] = _method.name;
    widget.data['url'] = _url.text.trim();
    widget.data['body'] = _body.text;
    widget.data['headers'] = <String, String>{ for (final MapEntry<String,String> e in _headers) e.key: e.value };
    widget.data['sendJson'] = _sendJson;
    widget.data['parseJsonResponse'] = _parseJsonResponse;
    widget.data['savePath'] = _savePath.text.trim();
    widget.data['timeoutMs'] = int.tryParse(_timeout.text.trim()) ?? 10000;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData t = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TextFormField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
          onChanged: (_) => _sync(),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<HttpMethod>(
                value: _method,
                decoration: const InputDecoration(labelText: 'Method', border: OutlineInputBorder()),
                items: HttpMethod.values.map((HttpMethod m) =>
                    DropdownMenuItem<HttpMethod>(value: m, child: Text(m.label))
                ).toList(),
                onChanged: (HttpMethod? v) { if (v != null) setState(() { _method = v; _sync(); }); },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: TextFormField(
                controller: _url,
                decoration: const InputDecoration(labelText: r'URL (supports ${ctx.path})', border: OutlineInputBorder()),
                onChanged: (_) => _sync(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Headers
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Headers', style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 6),
        Column(
          children: List<Widget>.generate(_headers.length, (int i) {
            final MapEntry<String, String> e = _headers[i];
            final TextEditingController k = TextEditingController(text: e.key);
            final TextEditingController v = TextEditingController(text: e.value);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: k,
                      decoration: const InputDecoration(hintText: 'Header name', border: OutlineInputBorder()),
                      onChanged: (_) { _headers[i] = MapEntry<String,String>(k.text, v.text); _sync(); },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: v,
                      decoration: const InputDecoration(hintText: 'Header value', border: OutlineInputBorder()),
                      onChanged: (_) { _headers[i] = MapEntry<String,String>(k.text, v.text); _sync(); },
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    onPressed: () { setState(() { _headers.removeAt(i); _sync(); }); },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            );
          }),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() { _headers.add(const MapEntry<String,String>('','')); _sync(); }),
            icon: const Icon(Icons.add),
            label: const Text('Add header'),
          ),
        ),

        // Body (nur nicht-GET/DELETE)
        if (_method != HttpMethod.get && _method != HttpMethod.delete) ...<Widget>[
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  controller: _body,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: r'Body (supports ${ctx.path})',
                    hintText: r'{"name":"${user.name}"}',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _sync(),
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Checkbox(value: _sendJson, onChanged: (bool? v) => setState(() { _sendJson = v ?? true; _sync(); })),
              const Text('Send as JSON (sets Content-Type)'),
            ],
          ),
        ],

        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                controller: _savePath,
                decoration: const InputDecoration(labelText: 'Save to context path', hintText: 'http.last', border: OutlineInputBorder()),
                onChanged: (_) => _sync(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 140,
              child: TextFormField(
                controller: _timeout,
                decoration: const InputDecoration(labelText: 'Timeout (ms)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                onChanged: (_) => _sync(),
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Checkbox(value: _parseJsonResponse, onChanged: (bool? v) => setState(() { _parseJsonResponse = v ?? true; _sync(); })),
            const Text('Parse JSON response'),
          ],
        ),
      ],
    );
  }
}
