part of '../graph.dart';

class NodeWrapper extends StatefulWidget {
  final AbstractNode node;
  final Offset Function(Offset position) globalToWorld;
  final VoidCallback onDragUpdate;
  final VoidCallback onDragEnd;
  final bool selected;
  final ValueChanged<bool>? onSelectedChanged;
  final VoidCallback? onRequestDelete;
  final VoidCallback? onRequestEdit;

  const NodeWrapper({
    super.key,
    required this.node,
    required this.globalToWorld,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onSelectedChanged,
    required this.onRequestDelete,
    required this.onRequestEdit,
    this.selected = false,
  });

  @override
  State<NodeWrapper> createState() => _NodeWrapperState();
}

class _NodeWrapperState extends State<NodeWrapper> {
  bool _hover = false;
  Offset? _lastGlobalDrag;

  bool get _multiPressed {
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    return pressed.contains(LogicalKeyboardKey.controlLeft) ||
        pressed.contains(LogicalKeyboardKey.controlRight) ||
        pressed.contains(LogicalKeyboardKey.metaLeft) ||
        pressed.contains(LogicalKeyboardKey.metaRight);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.node.position.dx,
      top: widget.node.position.dy,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: SystemMouseCursors.move,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (widget.onSelectedChanged != null) {
              widget.onSelectedChanged!(!_multiPressed ? true : !widget.selected);
            }
          },

          onPanStart: (DragStartDetails d) {
            _lastGlobalDrag = d.globalPosition;
          },
          onPanUpdate: (DragUpdateDetails d) {
            if (_lastGlobalDrag == null) return;
            final Offset prevWorld = widget.globalToWorld(_lastGlobalDrag!);
            final Offset nowWorld = widget.globalToWorld(d.globalPosition);
            final Offset delta = nowWorld - prevWorld;

            widget.node.setPosition(widget.node.position + delta);
            _lastGlobalDrag = d.globalPosition;
            widget.onDragUpdate();
            setState(() {});
          },
          onPanEnd: (DragEndDetails _) {
            _lastGlobalDrag = null;
            widget.onDragEnd();
          },
          onDoubleTap: widget.onRequestEdit,
          child: SizedBox(
            width: widget.node.width,
            height: widget.node.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[

                Positioned.fill(child: widget.node.draw(context)),


                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: true,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          width: widget.selected ? 2 : (_hover ? 1 : 0),
                          color: widget.selected ? Theme.of(context).colorScheme.primary : (_hover ? Colors.black26 : Colors.transparent),
                        ),
                      ),
                    ),
                  ),
                ),

                if (_hover || widget.selected)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: InkWell(
                      onTap: widget.onRequestDelete,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          shape: BoxShape.circle,
                          boxShadow: const <BoxShadow>[BoxShadow(blurRadius: 6, color: Colors.black26)],
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
