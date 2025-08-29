library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:fores/fores.dart';
import 'package:grapheditor/pages/editor/blocs/graph_editor/graph_editor_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

// Edges
part 'edges/abstract_edge.dart';
part 'edges/default_edge.dart';
part 'edges/branch_edge.dart';

// Nodes
part 'nodes/abstract_node.dart';
part 'nodes/executable_node.dart';
part 'nodes/async_executable_node.dart';
part 'nodes/choose_port_node.dart';
part 'nodes/abstract_label_node.dart';
part 'nodes/root_node.dart';
part 'nodes/default_node.dart';
part 'nodes/end_node.dart';
part 'nodes/decision_node.dart';
part 'nodes/context_node.dart';
part 'nodes/math_node.dart';
part 'nodes/http_node.dart';
part 'nodes/mapper_node.dart';

// Shared
part 'shared/graph_object_shared.dart';
part 'shared/utils.dart';
part 'shared/decision_branch.dart';
part 'shared/context_actions.dart';
part 'shared/test_context.dart';
part 'shared/mapper_rule.dart';

// Layouts
part 'layout/abstract_layout.dart';
part 'layout/layout_options.dart';
part 'layout/grid_layout.dart';
part 'layout/circular_layout.dart';
part 'layout/hierarchical_layout.dart';
part 'layout/tree_layout.dart';

// Widgets
part 'widgets/node_creator.dart';
part 'widgets/node_wrapper.dart';
part 'widgets/graph_canvas.dart';
part 'widgets/grid.dart';
part 'widgets/edge_renderer.dart';
part 'widgets/edge_preview_renderer.dart';
part 'widgets/decision_branch_editor.dart';
part 'widgets/decision_rule_editor.dart';
part 'widgets/node_scaffold.dart';
part 'widgets/graph_runtime.dart';
part 'widgets/mapper_rule_editor.dart';

// Forms
part 'forms/label_node_form.dart';
part 'forms/descision_node_form.dart';
part 'forms/context_node_form.dart';
part 'forms/math_node_form.dart';
part 'forms/http_node_form.dart';
part 'forms/mapper_node_form.dart';

// GraphRuntime
part 'runtime/graph_runtime.dart';
part 'runtime/graph_runtime_calc_all_routes.dart';
part 'runtime/runtime_result.dart';
part 'runtime/runtime_step.dart';
part 'runtime/runtime_hooks.dart';

// Exceptions
part 'exceptions/graph_exceptions.dart';

// Factories
part 'factories/node_factory.dart';
part 'factories/edge_factory.dart';

// Import Export
part 'imex/graph_converter_interface.dart';
part 'imex/converter/json_graph_converter.dart';

class Graph {
  Map<String, dynamic> meta = {};
  Map<String, AbstractNode> nodes = {};
  Map<String, AbstractEdge> edges = {};
  Map<String, TestContext> testsContexts = {};

  void addNode(AbstractNode node) {
    nodes[node.id] = node;
  }

  void removeNode(AbstractNode node) {
    if (nodes.containsKey(node.id)) {
      nodes.remove(node.id);
      edges.removeWhere((id, edge) => edge.from.id == node.id || edge.to.id == node.id);
    }
  }

  void addEdge(AbstractEdge edge) {
    if (nodes.containsKey(edge.from.id) && nodes.containsKey(edge.to.id)) {
      edges[edge.id] = edge;
      nodes[edge.from.id]!.addEdge(edge);
      nodes[edge.to.id]!.addEdge(edge);
    } else {
      throw GraphExceptions("Trying to add Edge to not available nodes ${edge.from.id}  ${edge.to.id}");
    }
  }

  void removeEdge(AbstractEdge edge) {
    if (edges.containsKey(edge.id)) {
      edges.remove(edge.id);
    }
  }

  void addMeta(String key, dynamic data) {
    meta[key] = data;
  }

  Map<String, dynamic> getMeta() {
    return meta;
  }

  void insertTestContext(TestContext ctx) {
    testsContexts[ctx.id] = ctx;
  }

  void removeTestContextById(String id) {
    testsContexts.remove(id);
  }

  TestContext createTestContextFromRaw({required String? id, required String name, required String json}) {
    final TestContext ctx = TestContext(id: id, name: name, json: json);
    testsContexts[ctx.id] = ctx;
    return ctx;
  }
}
