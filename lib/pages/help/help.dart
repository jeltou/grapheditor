import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'models/help_topic.dart';

class HelpPage extends StatefulWidget {
  final String? initialTopicId;

  const HelpPage({super.key, this.initialTopicId});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  late List<HelpTopic> _filtered;
  int _selectedIndex = 0;
  bool _loadingAll = true; // für initialen Search über Inhalte
  final Map<String, String> _mdCache = {}; // id -> markdown (für Suche)

  @override
  void initState() {
    super.initState();
    _filtered = List<HelpTopic>.from(helpTopicsFromAssets());
    if (widget.initialTopicId != null) {
      final int idx = _filtered.indexWhere((t) => t.id == widget.initialTopicId);
      if (idx >= 0) _selectedIndex = idx;
    }
    _searchCtrl.addListener(_applyFilter);
    _preloadAll();
  }

  Future<void> _preloadAll() async {
    for (final HelpTopic t in helpTopicsFromAssets()) {
      try {
        _mdCache[t.id] = await t.markdown();
      } catch (_) {
        _mdCache[t.id] = '';
      }
    }
    if (mounted) setState(() => _loadingAll = false);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final String q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List<HelpTopic>.from(helpTopicsFromAssets());
      } else {
        _filtered = helpTopicsFromAssets().where((t) {
          final String title = t.title.toLowerCase();
          final String body = (_mdCache[t.id] ?? '').toLowerCase();
          return title.contains(q) || body.contains(q);
        }).toList();
      }
      if (_filtered.isEmpty) {
        _selectedIndex = 0;
      } else {
        _selectedIndex = _selectedIndex.clamp(0, _filtered.length - 1);
      }
    });
  }

  void _openTopicById(String id) {
    final int idx = _filtered.indexWhere((t) => t.id == id);
    if (idx >= 0) setState(() => _selectedIndex = idx);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData t = Theme.of(context);
    final ColorScheme cs = t.colorScheme;

    final HelpTopic? current = (_filtered.isEmpty) ? null : _filtered[_selectedIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('Help')),
      body: Row(
        children: <Widget>[
          // Sidebar
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: cs.surfaceVariant.withOpacity(0.25),
              border: Border(right: BorderSide(color: cs.outlineVariant.withOpacity(0.6))),
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: const OutlineInputBorder(),
                      hintText: _loadingAll ? 'Loading docs…' : 'Search…',
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: cs.outlineVariant.withOpacity(0.35)),
                    itemBuilder: (BuildContext _, int i) {
                      final HelpTopic topic = _filtered[i];
                      final bool sel = i == _selectedIndex;
                      return Material(
                        color: sel ? cs.primary.withOpacity(0.12) : Colors.transparent,
                        child: ListTile(
                          dense: true,
                          title: Text(topic.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          selected: sel,
                          onTap: () => setState(() => _selectedIndex = i),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Container(
              color: cs.surface,
              child: current == null
                  ? const Center(child: Text('No results'))
                  : FutureBuilder<String>(
                      future: current.markdown(),
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final String md = snap.data ?? 'Failed to load ${current.assetPath}';
                        _mdCache[current.id] = md;
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                          child: Markdown(
                            selectable: true,
                            data: md,
                            onTapLink: (String text, String? href, String title) {
                              if (href != null && href.startsWith('help://topic/')) {
                                final String id = href.substring('help://topic/'.length);
                                _openTopicById(id);
                              }
                            },
                            styleSheet: MarkdownStyleSheet.fromTheme(t).copyWith(
                              codeblockDecoration: BoxDecoration(color: cs.surfaceVariant.withOpacity(0.4), borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showHelpDialog(BuildContext context, {String? initialTopicId}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext ctx) {
      final double maxW = MediaQuery.of(ctx).size.width * 0.95;
      final double maxH = MediaQuery.of(ctx).size.height * 0.90;
      return AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
          child: SizedBox(width: 1100, height: 700, child: HelpPage(initialTopicId: initialTopicId)),
        ),
      );
    },
  );
}
