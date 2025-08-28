part of '../graph.dart';

abstract class AbstractGraphLayout {
  String get name => toString();

  void apply(Graph graph, LayoutOptions options);
}
