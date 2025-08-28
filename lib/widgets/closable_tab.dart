part of 'widgets.dart';

class ClosableTab extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onClose;
  final VoidCallback onTap;

  const ClosableTab({required this.title, required this.selected, required this.onTap, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle =
        (selected ? Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600) : Theme.of(context).textTheme.bodyMedium) ??
        const TextStyle();

    return Tab(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(selected ? Icons.description : Icons.description_outlined, size: 16),
            const SizedBox(width: 8),
            Text(title, style: textStyle),
            const SizedBox(width: 6),
            Padding(
              padding: EdgeInsets.all(4.0),
              child: IconButton(icon: Icon(Icons.close, size: 16), onPressed: onClose),
            ),
          ],
        ),
      ),
    );
  }
}
