import 'point_map.dart';

class RouteMap {
  String id;
  String name;
  String company;
  PointMap origin;
  PointMap destiny;
  List<PointMap> points;

  RouteMap({
    this.id = "",
    this.name = "",
    this.company = "",
    required this.origin,
    required this.destiny,
    required this.points,
  });

  factory RouteMap.fromJson(Map<String, dynamic> json) {
    var list = json['points'] as List;
    var pointsList = list.map((e) => PointMap.fromJson(e)).toList();
    return RouteMap(
      id: json['id'],
      name: json['name'],
      company: json['company'],
      origin: PointMap.fromJson(json['origin']),
      destiny: PointMap.fromJson(json['destiny']),
      points: pointsList,
    );
  }

  Map toMap() {
    var map = <String, dynamic>{};

    map['id'] = id;
    map['name'] = name;
    map['company'] = company;
    map['origin'] = origin;
    map['destiny'] = destiny;
    map['points'] = points;

    return map;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'company': company,
      'origin': origin.toJson(),
      'destiny': destiny.toJson(),
      'points': points,
    };
  }

  toList() {}
}
