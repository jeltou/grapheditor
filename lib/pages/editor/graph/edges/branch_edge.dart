part of '../graph.dart';

class BranchEdge extends AbstractEdge {
  final String fromPort;
  @override
  String get edgeType => "BranchEdge";

  BranchEdge(super.from, super.to, {required this.fromPort});

  @override
  AbstractEdge fromMap(Map<String, dynamic> data) {
    throw UnimplementedError();
  }
}
