part of '../graph.dart';

enum HandlePos { top, right, bottom, left }

class GraphCanvas extends StatefulWidget {
  final Graph graph;
  final void Function(AbstractNode) createNewNode;

  const GraphCanvas({super.key, required this.graph, required this.createNewNode});

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas> {
  NodeCreator nodeCreator = NodeCreator();
  final TransformationController _tc = TransformationController();
  final GlobalKey _viewerKey = GlobalKey();
  final GlobalKey _sceneKey = GlobalKey();
  final FocusNode _focusNode = FocusNode();

  static const double _kCanvasSize = 200000.0;
  static const double _kCullPadding = 200.0;
  static const double _kMinScale = 0.1;
  static const double _kMaxScale = 4.0;
  static const double _kWheelZoomSpeed = 0.00005;
  static const bool _kCtrlWheelOnly = false;

  bool _isConnecting = false;
  AbstractNode? _connFrom;
  HandlePos? _connFromSide;
  Offset? _connFromAnchorWorld;
  Offset? _connCursorWorld;

  AbstractEdge? _hoverEdge;
  final Set<AbstractEdge> _selectedEdges = <AbstractEdge>{};
  final Set<AbstractNode> _selectedNodes = <AbstractNode>{};

  @override
  void initState() {
    super.initState();
    _tc.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _tc.removeListener(_onTransformChanged);
    _tc.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Offset _globalToWorld(Offset globalPosition) {
    final RenderBox viewport = _viewerKey.currentContext!.findRenderObject() as RenderBox;
    final Offset inViewport = viewport.globalToLocal(globalPosition);
    return _tc.toScene(inViewport);
  }

  Rect _worldViewportRect(Size viewportSize) {
    final Offset tl = _tc.toScene(Offset.zero);
    final Offset br = _tc.toScene(Offset(viewportSize.width, viewportSize.height));
    return Rect.fromPoints(tl, br);
  }

  Rect _nodeRect(AbstractNode n) => Rect.fromLTWH(n.position.dx, n.position.dy, n.width, n.height);

  Iterable<AbstractNode> _visibleNodes(Iterable<AbstractNode> all, Rect worldView) {
    final Rect padded = worldView.inflate(_kCullPadding);
    return all.where((AbstractNode n) => _nodeRect(n).overlaps(padded));
  }

  List<AbstractEdge> _visibleEdges(Iterable<AbstractEdge> all, Rect worldView, Set<AbstractNode> visibleSet) {
    return all.toList();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;

    if (_kCtrlWheelOnly) {
      final bool ctrlDown =
          HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
          HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight);
      if (!ctrlDown) return;
    }

    final RenderBox? viewportBox = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewportBox == null) return;

    final Offset localFocal = viewportBox.globalToLocal(event.position);

    final double currentScale = _tc.value.getMaxScaleOnAxis();
    final double wheel = -event.scrollDelta.dy;
    final double scaleChange = math.exp(wheel * _kWheelZoomSpeed);
    final double unclamped = currentScale * scaleChange;

    final double newScale = unclamped.clamp(_kMinScale, _kMaxScale);
    final double effectiveChange = newScale / currentScale;
    if (effectiveChange == 1.0) return;

    final Matrix4 next = _tc.value.clone()
      ..translate(localFocal.dx, localFocal.dy)
      ..scale(effectiveChange)
      ..translate(-localFocal.dx, -localFocal.dy);

    _tc.value = next;
  }

  Future<void> createNode(Offset position) async {
    final AbstractNode? node = await nodeCreator.open(context);
    if (node != null) {
      node.setPosition(position);
      widget.createNewNode(node);
      setState(() {});
    }
  }

  void _startConnection(AbstractNode from, HandlePos side) {
    _isConnecting = true;
    _connFrom = from;
    _connFromSide = side;
    _connFromAnchorWorld = _handleAnchorWorld(from, side);
    _connCursorWorld = _connFromAnchorWorld;
    setState(() {});
  }

  void _updateConnection(Offset globalCursor) {
    if (!_isConnecting) return;
    _connCursorWorld = _globalToWorld(globalCursor);
    setState(() {});
  }

  void _endConnection() async {
    if (!_isConnecting || _connFrom == null || _connCursorWorld == null) {
      _resetConnection();
      return;
    }

    final RenderBox viewport = _viewerKey.currentContext!.findRenderObject() as RenderBox;
    final Rect view = _worldViewportRect(viewport.size);
    final Set<AbstractNode> candidates = _visibleNodes(widget.graph.nodes.values, view).toSet();

    AbstractNode? target;
    for (final AbstractNode n in candidates) {
      if (identical(n, _connFrom)) continue;
      if (_nodeRect(n).contains(_connCursorWorld!)) {
        target = n;
        break;
      }
    }

    if (target != null) {
      if (_connFrom! is ChoosePortNode) {
        final String? port = await _chooseBranchPort(context, _connFrom! as ChoosePortNode, target.position);
        if (port != null) {
          context.read<GraphEditorBloc>().add(GraphEditorAddEdge(BranchEdge(_connFrom!, target, fromPort: port)));
        }
      } else {
        context.read<GraphEditorBloc>().add(GraphEditorAddEdge(DefaultEdge(_connFrom!, target)));
      }
    }

    _resetConnection();
    setState(() {});
  }

  void _resetConnection() {
    _isConnecting = false;
    _connFrom = null;
    _connFromSide = null;
    _connFromAnchorWorld = null;
    _connCursorWorld = null;
  }

  Offset _handleAnchorWorld(AbstractNode n, HandlePos pos) {
    final Rect r = _nodeRect(n);
    switch (pos) {
      case HandlePos.top:
        return Offset(r.center.dx, r.top);
      case HandlePos.right:
        return Offset(r.right, r.center.dy);
      case HandlePos.bottom:
        return Offset(r.center.dx, r.bottom);
      case HandlePos.left:
        return Offset(r.left, r.center.dy);
    }
  }

  Future<String?> _chooseBranchPort(BuildContext ctx, ChoosePortNode node, Offset menuGlobalPos) {
    final List<PopupMenuEntry<String>> items = <PopupMenuEntry<String>>[
      for (String port in node.getPorts()) PopupMenuItem<String>(value: port, child: Text('Route: $port')),
    ];
    return showMenu<String>(
      context: ctx,
      position: RelativeRect.fromLTRB(menuGlobalPos.dx, menuGlobalPos.dy, menuGlobalPos.dx, menuGlobalPos.dy),
      items: items,
    );
  }

  Offset _anchorOnRect(Rect rect, Offset toward) {
    final double cx = rect.center.dx, cy = rect.center.dy;
    double dx = toward.dx - cx, dy = toward.dy - cy;
    if (dx == 0 && dy == 0) return Offset(rect.right, cy);

    final double hw = rect.width / 2, hh = rect.height / 2;
    final double absDx = dx.abs(), absDy = dy.abs();

    late double sx, sy;
    if (absDx * hh > absDy * hw) {
      sx = dx.sign * hw;
      sy = dy * (hw / absDx);
    } else {
      sx = dx * (hh / absDy);
      sy = dy.sign * hh;
    }
    return Offset(cx + sx, cy + sy);
  }

  (Offset, Offset) _cubicHandles(Offset p0, Offset p3, double k) {
    final double dx = p3.dx - p0.dx, dy = p3.dy - p0.dy;
    final double dist = math.sqrt(dx * dx + dy * dy);
    final double h = dist * (0.25 + 0.35 * k.clamp(0, 1));
    if (dx.abs() >= dy.abs()) {
      final double sx = dx.sign == 0 ? 1.0 : dx.sign;
      return (p0 + Offset(h * sx, 0), p3 - Offset(h * sx, 0));
    } else {
      final double sy = dy.sign == 0 ? 1.0 : dy.sign;
      return (p0 + Offset(0, h * sy), p3 - Offset(0, h * sy));
    }
  }

  Offset _cubicPoint(Offset p0, Offset c1, Offset c2, Offset p3, double t) {
    final double mt = 1 - t;
    final double mt2 = mt * mt;
    final double t2 = t * t;
    final double x = mt2 * mt * p0.dx + 3 * mt2 * t * c1.dx + 3 * mt * t2 * c2.dx + t2 * t * p3.dx;
    final double y = mt2 * mt * p0.dy + 3 * mt2 * t * c1.dy + 3 * mt * t2 * c2.dy + t2 * t * p3.dy;
    return Offset(x, y);
  }

  double _distPointToSegment(Offset p, Offset a, Offset b) {
    final Offset ab = b - a;
    final double ab2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (ab2 == 0) return (p - a).distance;
    final double t = ((p.dx - a.dx) * ab.dx + (p.dy - a.dy) * ab.dy) / ab2;
    if (t <= 0) return (p - a).distance;
    if (t >= 1) return (p - b).distance;
    final Offset proj = a + ab * t;
    return (p - proj).distance;
  }

  AbstractEdge? _edgeAtWorld(Offset p, Iterable<AbstractEdge> edges, {double tol = 8.0}) {
    AbstractEdge? best;
    double bestD = tol;

    for (final AbstractEdge e in edges) {
      final Rect r1 = _nodeRect(e.from), r2 = _nodeRect(e.to);
      final Offset p0 = _anchorOnRect(r1, r2.center);
      final Offset p3 = _anchorOnRect(r2, r1.center);
      final (Offset c1, Offset c2) = _cubicHandles(p0, p3, 0.6);

      const int steps = 40;
      Offset prev = p0;
      for (int i = 1; i <= steps; i++) {
        final double t = i / steps;
        final Offset curr = _cubicPoint(p0, c1, c2, p3, t);
        final double d = _distPointToSegment(p, prev, curr);
        if (d < bestD) {
          bestD = d;
          best = e;
        }
        prev = curr;
      }
    }
    return best;
  }

  void deleteEdge(AbstractEdge edge) {
    context.read<GraphEditorBloc>().add(GraphEditorDeleteEdge(edge));
  }

  Offset _edgeMidpoint(AbstractEdge e) {
    final Rect r1 = _nodeRect(e.from), r2 = _nodeRect(e.to);
    final Offset p0 = _anchorOnRect(r1, r2.center);
    final Offset p3 = _anchorOnRect(r2, r1.center);
    final (Offset c1, Offset c2) = _cubicHandles(p0, p3, 0.6);
    return _cubicPoint(p0, c1, c2, p3, 0.5);
  }

  void _deleteSelectedEdges() {
    if (_selectedEdges.isEmpty) return;
    for (final AbstractEdge e in _selectedEdges.toList()) {
      deleteEdge(e);
    }
    _selectedEdges.clear();
    _hoverEdge = null;
  }

  void _toggleNodeSelection(AbstractNode n, {required bool multi}) {
    setState(() {
      if (!multi) _selectedNodes.clear();
      if (_selectedNodes.contains(n)) {
        if (multi) {
          _selectedNodes.remove(n);
        } else {
          _selectedNodes
            ..clear()
            ..add(n);
        }
      } else {
        _selectedNodes.add(n);
      }
    });
  }

  void _deleteSelectedNodes() {
    if (_selectedNodes.isEmpty) return;
    for (final AbstractNode n in _selectedNodes.toList()) {
      context.read<GraphEditorBloc>().add(GraphEditorDeleteNode(n));
      _selectedNodes.remove(n);
    }
  }

  List<Widget> _buildPortHandles(AbstractNode node) {
    const double radius = 7.0;
    final Color c = Theme.of(context).colorScheme.primary;

    Widget makeHandle(HandlePos side, Offset localCenter) {
      return Positioned(
        left: node.position.dx + localCenter.dx - radius,
        top: node.position.dy + localCenter.dy - radius,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (DragStartDetails d) => _startConnection(node, side),
          onPanUpdate: (DragUpdateDetails d) => _updateConnection(d.globalPosition),
          onPanEnd: (DragEndDetails _) => _endConnection(),
          child: Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.9), width: 1),
              boxShadow: const <BoxShadow>[BoxShadow(blurRadius: 2, spreadRadius: 0.5)],
            ),
          ),
        ),
      );
    }

    final Offset top = Offset(node.width / 2, 0);
    final Offset right = Offset(node.width, node.height / 2);
    final Offset bottom = Offset(node.width / 2, node.height);
    final Offset left = Offset(0, node.height / 2);

    return <Widget>[makeHandle(HandlePos.top, top), makeHandle(HandlePos.right, right), makeHandle(HandlePos.bottom, bottom), makeHandle(HandlePos.left, left)];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        final Rect worldView = _worldViewportRect(viewportSize);

        final Iterable<AbstractNode> allNodes = widget.graph.nodes.values;
        final Iterable<AbstractEdge> allEdges = widget.graph.edges.values;

        final Set<AbstractNode> visNodeSet = _visibleNodes(allNodes, worldView).toSet();
        final List<AbstractEdge> visEdges = _visibleEdges(allEdges, worldView, visNodeSet);

        final ColorScheme cs = Theme.of(context).colorScheme;
        final Color edgeColor = const Color(0xFF555555);
        final Color hoverColor = cs.primary.withOpacity(0.95);
        final Color selectedColor = cs.error.withOpacity(0.95);

        return Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (FocusNode _, KeyEvent e) {
            if (e is KeyDownEvent && (e.logicalKey == LogicalKeyboardKey.delete || e.logicalKey == LogicalKeyboardKey.backspace)) {
              _deleteSelectedEdges();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Listener(
            onPointerSignal: _onPointerSignal,
            onPointerHover: (PointerHoverEvent ev) {
              final Offset world = _globalToWorld(ev.position);
              _hoverEdge = _edgeAtWorld(world, visEdges, tol: 8.0);
              setState(() {});
            },
            onPointerDown: (PointerDownEvent ev) async {
              if (ev.buttons == kPrimaryMouseButton) {
                final Offset world = _globalToWorld(ev.position);
                final AbstractEdge? hit = _edgeAtWorld(world, visEdges, tol: 8.0);
                final bool multi =
                    HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlLeft) ||
                    HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.controlRight) ||
                    HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaLeft) ||
                    HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.metaRight);

                if (hit != null) {
                  setState(() {
                    if (!multi) _selectedEdges.clear();
                    if (_selectedEdges.contains(hit)) {
                      if (multi) _selectedEdges.remove(hit);
                    } else {
                      _selectedEdges.add(hit);
                    }
                  });
                } else {
                  if (!multi && _selectedEdges.isNotEmpty) {
                    setState(() => _selectedEdges.clear());
                  }
                }
              }
            },
            child: InteractiveViewer(
              key: _viewerKey,
              transformationController: _tc,
              minScale: _kMinScale,
              maxScale: _kMaxScale,
              scaleEnabled: true,
              panEnabled: !_isConnecting,
              constrained: false,
              child: SizedBox(
                key: _sceneKey,
                width: _kCanvasSize,
                height: _kCanvasSize,

                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onSecondaryTapDown: (TapDownDetails d) async {
                    final Offset global = d.globalPosition;
                    final Offset world = _globalToWorld(global);
                    final String? choice = await showMenu<String>(
                      context: context,
                      position: RelativeRect.fromLTRB(global.dx, global.dy, global.dx, global.dy),
                      items: <PopupMenuEntry<String>>[const PopupMenuItem<String>(value: 'add', child: Text('Add node here'))],
                    );
                    if (choice == 'add') {
                      await createNode(Offset(world.dx, world.dy));
                    }
                  },
                  child: Stack(
                    children: <Widget>[
                      EdgeRenderer(
                        edges: visEdges,
                        color: edgeColor,
                        strokeWidth: 2.0,
                        arrows: true,
                        hovered: _hoverEdge,
                        selected: _selectedEdges,
                        highlightHover: hoverColor,
                        highlightSelected: selectedColor,
                      ),

                      Positioned.fill(
                        child: CustomPaint(painter: GridPainter(controller: _tc)),
                      ),

                      for (final AbstractNode node in visNodeSet)
                        NodeWrapper(
                          node: node,
                          globalToWorld: _globalToWorld,
                          onDragUpdate: () => setState(() {}),
                          onDragEnd: () => setState(() {}),
                          selected: _selectedNodes.contains(node),
                          onSelectedChanged: (bool _) {
                            final pressed = HardwareKeyboard.instance.logicalKeysPressed;
                            final bool multi =
                                pressed.contains(LogicalKeyboardKey.controlLeft) ||
                                pressed.contains(LogicalKeyboardKey.controlRight) ||
                                pressed.contains(LogicalKeyboardKey.metaLeft) ||
                                pressed.contains(LogicalKeyboardKey.metaRight);
                            _toggleNodeSelection(node, multi: multi);
                          },
                          onRequestDelete: () {
                            _selectedNodes.add(node);
                            _deleteSelectedNodes();
                          },
                          onRequestEdit: () async {
                            final bool changed = await nodeCreator.openEdit(context, node);
                            if (changed) setState(() {});
                          },
                        ),

                      for (final AbstractNode node in visNodeSet) ..._buildPortHandles(node),

                      if (_isConnecting && _connFromAnchorWorld != null && _connCursorWorld != null)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: EdgePreviewHandler(
                              from: _connFromAnchorWorld!,
                              to: _connCursorWorld!,
                              color: Theme.of(context).colorScheme.primary,
                              strokeWidth: 2.0,
                            ),
                          ),
                        ),

                      if (_hoverEdge != null)
                        ...() {
                          final Offset m = _edgeMidpoint(_hoverEdge!);
                          return <Widget>[
                            Positioned(
                              left: m.dx - 12,
                              top: m.dy - 12,
                              child: GestureDetector(
                                onTap: () {
                                  final AbstractEdge e = _hoverEdge!;
                                  deleteEdge(e);
                                  setState(() {});
                                },
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: selectedColor,
                                    shape: BoxShape.circle,
                                    boxShadow: const <BoxShadow>[BoxShadow(blurRadius: 6, color: Colors.black26)],
                                  ),
                                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ];
                        }(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
