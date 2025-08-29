import 'package:flutter/material.dart';
import 'package:fores/fores.dart';
import 'package:grapheditor/pages/editor/blocs/graph_editor/graph_editor_bloc.dart';
import 'package:grapheditor/pages/editor/graph/graph.dart';

import '../../../cons.dart';
import '../../../widgets/widgets.dart';
import '../help/help.dart';

class GraphEditor extends StatefulWidget {
  const GraphEditor({super.key});

  @override
  State<GraphEditor> createState() => _GraphEditorState();
}

class _GraphEditorState extends State<GraphEditor> {
  NodeCreator nodeCreator = NodeCreator();
  Graph? currentGraph;

  @override
  void initState() {
    super.initState();
  }

  void addNewNode(AbstractNode node) {
    context.read<GraphEditorBloc>().add(GraphEditorAddNode(node));
  }

  void applyLayout(AbstractGraphLayout layout) {
    context.read<GraphEditorBloc>().add(GraphEditorApplyLayout(layout));
  }

  void openGraphRuntimeDialog() async {
    if (currentGraph != null) {
      await showGraphRuntimeDialog(context, graph: currentGraph!);
    }
  }

  void saveGraph(bool showDialog) {
    context.read<GraphEditorBloc>().add(GraphEditorSaveGraph(showDialog));
  }

  void openGraph() {
    context.read<GraphEditorBloc>().add(GraphEditorOpenGraph());
  }

  void createNode(String nodeTyoe) {
    nodeCreator.open(context, initialType: nodeTyoe);
  }

  void openHelp() {
    showHelpDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: MenuBar(
                  children: <Widget>[
                    SubmenuButton(
                      menuChildren: <Widget>[
                        MenuItemButton(onPressed: () => createNewGraph(context), child: const Text('Neuer Graph')),
                        MenuItemButton(onPressed: () => openGraph(), child: const Text('Graph öffnen')),
                        MenuItemButton(onPressed: currentGraph != null ? () => saveGraph(false) : null, child: const Text('Speichern')),
                        MenuItemButton(onPressed: currentGraph != null ? () => saveGraph(true) : null, child: const Text('Speichern unter')),
                      ],
                      child: const Text('File'),
                    ),
                    SubmenuButton(
                      menuChildren: <Widget>[MenuItemButton(child: const Text('Neuer DefaultNode'), onPressed: () => createNode("DefaultNode"))],
                      child: const Text('Nodes'),
                    ),
                    SubmenuButton(
                      menuChildren: <Widget>[MenuItemButton(child: const Text('Ausführen'), onPressed: openGraphRuntimeDialog)],
                      child: const Text('Graph'),
                    ),
                    SubmenuButton(
                      menuChildren: <Widget>[
                        MenuItemButton(onPressed: () {}, child: const Text('Undo')),
                        MenuItemButton(onPressed: () {}, child: const Text('Redo')),
                      ],
                      child: const Text('Edit'),
                    ),
                    SubmenuButton(
                      menuChildren: <Widget>[MenuItemButton(child: const Text('Tree Layout anwenden'), onPressed: () => applyLayout(TreeLayout()))],
                      child: const Text('Layout'),
                    ),
                    SubmenuButton(
                      menuChildren: <Widget>[MenuItemButton(child: const Text('Open Preview'))],
                      child: const Text('View'),
                    ),
                    SubmenuButton(
                      menuChildren: <Widget>[MenuItemButton(onPressed: () => openHelp(), child: const Text('Open Help'))],
                      child: const Text('Help'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: BlocConsumer<GraphEditorBloc, GraphEditorState>(
              listener: (context, state) {
                if (state is GraphEditorUpdateState) {
                  currentGraph = state.tabs.firstWhere((tab) => tab.index == state.currentTabIndex).data[graphKey] as Graph;
                  setState(() {});
                }
              },
              builder: (context, state) {
                if (state is GraphEditorUpdateState) {
                  if (state.tabs.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: state.tabs
                                .map(
                                  (e) => ClosableTab(
                                    title: e.title,
                                    selected: state.currentTabIndex == e.index,
                                    onTap: () => context.read<GraphEditorBloc>().add(GraphEditorSwitchTab(e.index)),
                                    onClose: () => context.read<GraphEditorBloc>().add(GraphEditorCloseTab(e.index)),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        Expanded(
                          child: GraphCanvas(
                            graph: state.tabs.firstWhere((tab) => tab.index == state.currentTabIndex).data[graphKey] as Graph,
                            createNewNode: addNewNode,
                          ),
                        ),
                      ],
                    );
                  }
                }
                return Center(child: Text("Aktuell ist kein Graph geöffnet"));
              },
            ),
          ),
        ],
      ),
    );
  }
}
