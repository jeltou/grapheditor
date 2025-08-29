part of '../graph.dart';

class NodeScaffold extends StatelessWidget {
  final String nodeName;
  final IconData icon;
  final double width;
  final double height;
  final Gradient gradient;
  final Widget? child;

  const NodeScaffold({super.key, required this.nodeName, required this.icon, required this.width, required this.height, required this.gradient, this.child});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.onPrimary.withOpacity(0.12), width: 1),
          boxShadow: <BoxShadow>[BoxShadow(color: cs.primary.withOpacity(0.35), blurRadius: 24, spreadRadius: 1, offset: const Offset(0, 8))],
        ),
        child: Stack(
          children: <Widget>[

            Positioned(right: -8, bottom: -8, child: Icon(icon, size: 96, color: cs.onPrimary.withOpacity(0.08))),


            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[

                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.onPrimary.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.onPrimary.withOpacity(0.18)),
                    ),
                    child: Icon(icon, size: 24, color: cs.onPrimary),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          nodeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700, color: cs.onPrimary.withOpacity(0.9)),
                        ),
                        const SizedBox(height: 4),
                        child ?? Container(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
