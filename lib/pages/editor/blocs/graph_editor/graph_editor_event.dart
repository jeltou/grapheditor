part of 'graph_editor_bloc.dart';

@immutable
sealed class GraphEditorEvent extends CEvent {}

class GraphEditorUpdate extends GraphEditorEvent {}

class GraphEditorSwitchTab extends GraphEditorEvent {
  final int tabIndex;

  GraphEditorSwitchTab(this.tabIndex);
}

class GraphEditorCloseTab extends GraphEditorEvent {
  final int tabIndex;

  GraphEditorCloseTab(this.tabIndex);
}

class GraphEditorMewGraphEvent extends GraphEditorEvent {
  final String name;

  GraphEditorMewGraphEvent(this.name);
}

class GraphEditorAddNode extends GraphEditorEvent {
  final AbstractNode node;

  GraphEditorAddNode(this.node);
}

class GraphEditorDeleteNode extends GraphEditorEvent {
  final AbstractNode node;

  GraphEditorDeleteNode(this.node);
}

class GraphEditorApplyLayout extends GraphEditorEvent {
  final AbstractGraphLayout layout;

  GraphEditorApplyLayout(this.layout);
}

class GraphEditorAddEdge extends GraphEditorEvent {
  final AbstractEdge edge;

  GraphEditorAddEdge(this.edge);
}

class GraphEditorDeleteEdge extends GraphEditorEvent {
  final AbstractEdge edge;

  GraphEditorDeleteEdge(this.edge);
}

class GraphEditorSaveGraph extends GraphEditorEvent {
  final bool showDialog;

  GraphEditorSaveGraph(this.showDialog);
}

class GraphEditorOpenGraph extends GraphEditorEvent {}
