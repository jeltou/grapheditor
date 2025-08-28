part of '../graph.dart';

abstract class GraphConverterInterface {
  Graph formatToGraph(String data);

  String graphToFormat(Graph graph);

  List<String> getFileExtensions();
}
