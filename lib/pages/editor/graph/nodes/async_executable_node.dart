part of '../graph.dart';

abstract class AsyncExecutableNode {
  Future<void> executeBeforeAsync(Map<String, dynamic> ctx) async {}
  Future<void> executeAfterAsync(Map<String, dynamic> ctx, {String? chosenPort}) async {}
}
