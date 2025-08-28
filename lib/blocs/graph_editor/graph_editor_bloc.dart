import 'dart:io' as io;

import 'package:bloc/bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fores/blocs/navigation/navigation_nuntius.dart';
import 'package:fores/cbloc/cbloc.dart';
import 'package:grapheditor/models/tab_data.dart';
import 'package:meta/meta.dart';

import '../../cons.dart';
import '../../graph/graph.dart';

part 'graph_editor_event.dart';

part 'graph_editor_state.dart';

class GraphEditorBloc extends CBloc<GraphEditorEvent, GraphEditorState> {
  JsonGraphConverter converter = JsonGraphConverter();
  List<TabData> tabs = [];
  int currentTabIndex = 0;

  GraphEditorBloc() : super(GraphEditorInitial(), subscribedTopics: ["graphEditor"]) {
    on<GraphEditorEvent>((event, emit) {});
    on<GraphEditorMewGraphEvent>(_graphEditorMewGraphEvent);
    on<GraphEditorUpdate>(_graphEditorUpdate);
    on<GraphEditorSwitchTab>(_graphEditorSwitchTab);
    on<GraphEditorCloseTab>(_graphEditorCloseTab);
    on<GraphEditorAddNode>(_graphEditorAddNode);
    on<GraphEditorDeleteNode>(_graphEditorDeleteNode);
    on<GraphEditorAddEdge>(_graphEditorAddEdge);
    on<GraphEditorDeleteEdge>(_graphEditorDeleteEdge);
    on<GraphEditorApplyLayout>(_graphEditorApplyLayout);
    on<GraphEditorSaveGraph>(_graphEditorSaveGraph);
    on<GraphEditorOpenGraph>(_graphEditorOpenGraph);
  }

  Future<void> _graphEditorUpdate(GraphEditorUpdate event, Emitter emit) async {
    emit(GraphEditorUpdateState(tabs, currentTabIndex));
  }

  Future<void> _graphEditorMewGraphEvent(GraphEditorMewGraphEvent event, Emitter emit) async {
    Graph graph = Graph();
    graph.addNode(RootNode(label: event.name));
    graph.addMeta("name", event.name);
    currentTabIndex = getNextTabIndex();
    TabData tab = TabData(currentTabIndex, event.name, {graphKey: graph});
    tabs.add(tab);
    add(GraphEditorUpdate());
  }

  Future<void> _graphEditorSwitchTab(GraphEditorSwitchTab event, Emitter emit) async {
    currentTabIndex = event.tabIndex;
    add(GraphEditorUpdate());
  }

  Future<void> _graphEditorCloseTab(GraphEditorCloseTab event, Emitter emit) async {
    tabs.removeWhere((tab) => tab.index == event.tabIndex);
    add(GraphEditorUpdate());
  }

  Future<void> _graphEditorAddNode(GraphEditorAddNode event, Emitter emit) async {
    getCurrentGraph().addNode(event.node);
    add(GraphEditorUpdate());
  }

  Future<void> _graphEditorDeleteNode(GraphEditorDeleteNode event, Emitter emit) async {
    getCurrentGraph().removeNode(event.node);
    add(GraphEditorUpdate());
  }

  Future<void> _graphEditorAddEdge(GraphEditorAddEdge event, Emitter emit) async {
    getCurrentGraph().addEdge(event.edge);
  }

  Future<void> _graphEditorDeleteEdge(GraphEditorDeleteEdge event, Emitter emit) async {
    getCurrentGraph().removeEdge(event.edge);
    add(GraphEditorUpdate());
  }

  Future<void> _graphEditorApplyLayout(GraphEditorApplyLayout event, Emitter emit) async {
    event.layout.apply(getCurrentGraph(), LayoutOptions());
    add(GraphEditorUpdate());
  }

  Future<void> _graphEditorSaveGraph(GraphEditorSaveGraph event, Emitter emit) async {
    Graph graph = getCurrentGraph();

    String? filePath = graph.meta["filepath"];
    String data = converter.graphToFormat(graph);
    if (filePath == null || event.showDialog) {
      filePath = await FilePicker.platform.saveFile(dialogTitle: 'Speicherort', type: FileType.custom, allowedExtensions: ['gjson', 'json'], fileName: "${graph.meta['name']}.gjson");
      if (filePath != null) {
        graph.addMeta("filepath", filePath);
      }
    }

    try {
      io.File returnedFile = io.File('$filePath');
      await returnedFile.writeAsBytes(data.codeUnits);
    } catch (e) {}
  }

  Future<void> _graphEditorOpenGraph(GraphEditorOpenGraph event, Emitter emit) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.custom, allowedExtensions: ['gjson', 'json']);
    if (result == null) {
      return;
    }

    for (var file in result!.xFiles) {
      String data = await file.readAsString();
      Graph graph = converter.formatToGraph(data);
      graph.addMeta("filepath", file.path);
      graph.addMeta("name", file.name);
      currentTabIndex = getNextTabIndex();
      TabData tab = TabData(currentTabIndex, file.name, {graphKey: graph});
      tabs.add(tab);
    }

    add(GraphEditorUpdate());
  }

  TabData getCurrentTab() {
    return tabs.firstWhere((tab) => tab.index == currentTabIndex);
  }

  Graph getCurrentGraph() {
    return getCurrentTab().data[graphKey] as Graph;
  }

  int getNextTabIndex() {
    int max = 1;
    for (TabData tab in tabs) {
      if (tab.index > max) {
        max = tab.index;
      }
    }
    return max + 1;
  }
}
