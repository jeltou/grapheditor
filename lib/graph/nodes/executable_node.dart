part of '../graph.dart';

abstract class ExecutableNode {
  void executeBefore(Map<String, dynamic> ctx) {}
  void executeAfter(Map<String, dynamic> ctx, {String? chosenPort}) {}
  String? choosePort(Map<String, dynamic> ctx) => null;
}