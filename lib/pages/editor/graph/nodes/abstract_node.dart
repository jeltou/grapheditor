part of '../graph.dart';

abstract class AbstractNode with GraphObjectShared {
  String id;
  String nodeType = "AbstractNode";
  Offset position;
  double width = 200;
  double height = 100;
  List<AbstractEdge> edges = [];

  AbstractNode({String? id, this.position = Offset.zero}) : id = id ?? '' {
    if (this.id.isEmpty) {
      this.id = generateMewId();
    }
  }

  void addEdge(AbstractEdge edge) {
    edges.add(edge);
  }

  void deleteEdge(AbstractEdge edge) {
    edges.remove(edge);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AbstractNode && other.id == id;
  }

  void setPosition(Offset position) {
    this.position = position;
  }

  AbstractNode fromMap(Map<String, dynamic> data);

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "nodeType": nodeType,
      "position": {"x": position.dx, "y": position.dy},
      "size": {"width": width, "height": height},
    };
  }

  Widget draw(BuildContext context);

  void onTap() {}

  void onDoubleTap() {}
}
