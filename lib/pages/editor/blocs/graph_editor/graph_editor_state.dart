part of 'graph_editor_bloc.dart';

@immutable
sealed class GraphEditorState extends CState {}

final class GraphEditorInitial extends GraphEditorState {}

class GraphEditorUpdateState extends GraphEditorState {
  final List<TabData> tabs;
  final int currentTabIndex;

  GraphEditorUpdateState(this.tabs, this.currentTabIndex);
}
