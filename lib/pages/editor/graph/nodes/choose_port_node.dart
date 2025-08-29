part of '../graph.dart';

abstract class ChoosePortNode{
  String? choosePort(Map<String, dynamic> ctx) => null;
  List<String> getPorts();
}