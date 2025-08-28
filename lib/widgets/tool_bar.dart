part of 'widgets.dart';

class ToolBarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const ToolBarItem({super.key, required this.icon, required this.label, required this.onPressed});

  @override
  State<ToolBarItem> createState() => _ToolBarItemState();
}

class _ToolBarItemState extends State<ToolBarItem> {

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(key: const ValueKey('elevated'), icon: Icon(widget.icon), label: Text(widget.label), onPressed: widget.onPressed);
  }






























}

class ToolBar extends StatelessWidget {
  final List<ToolBarItem> items;

  const ToolBar({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SizedBox(height: 50, child: Row(children: items)),
      ),
    );
  }
}
