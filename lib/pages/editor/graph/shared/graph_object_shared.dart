part of '../graph.dart';

Uuid uuid = Uuid();

mixin GraphObjectShared {
  String generateMewId() {
    return uuid.v4();
  }
}

