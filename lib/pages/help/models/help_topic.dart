import 'package:flutter/services.dart' show rootBundle;

class HelpTopic {
  final String id;
  final String title;
  final String assetPath;
  String? _markdown;

  HelpTopic({required this.id, required this.title, required this.assetPath});

  Future<String> markdown() async {
    _markdown ??= await rootBundle.loadString(assetPath);
    return _markdown!;
  }
}

List<HelpTopic> helpTopicsFromAssets() => <HelpTopic>[
  HelpTopic(id: 'getting-started', title: 'Getting started', assetPath: 'assets/docs/getting_started.md'),
  HelpTopic(id: 'nodes', title: 'Nodes', assetPath: 'assets/docs/nodes.md'),
];
