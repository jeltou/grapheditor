part of '../graph.dart';

abstract class AbstractEdge with GraphObjectShared {
  String id;
  String edgeType = "AbstractEdge";
  AbstractNode from;
  AbstractNode to;

  AbstractEdge(this.from, this.to, {String? id}) : id = id ?? '' {
    if (this.id.isEmpty) {
      this.id = generateMewId();
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AbstractEdge && other.id == id;
  }

  AbstractEdge fromMap(Map<String, dynamic> data);

  Map<String, dynamic> toMap() {
    return {"edgeType": edgeType};
  }
}
