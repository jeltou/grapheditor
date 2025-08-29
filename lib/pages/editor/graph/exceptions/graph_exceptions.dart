part of '../graph.dart';

class GraphExceptions implements Exception {
  String cause;

  GraphExceptions(this.cause);
}

class GraphExecutionException implements Exception {
  String cause;

  GraphExecutionException(this.cause);
}
