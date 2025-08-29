part of '../graph.dart';

class DefaultEdge extends AbstractEdge {
  DefaultEdge(super.from, super.to);

  @override
  AbstractEdge fromMap(Map<String, dynamic> data) {
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toMap() {
    throw UnimplementedError();
  }
}
