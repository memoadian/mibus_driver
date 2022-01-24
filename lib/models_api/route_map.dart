import 'point_map.dart';

class RouteMap {
  String id;
  String name;
  String company;
  String overview;
  List<PointMap> points;

  RouteMap({
    this.id = "",
    this.name = "",
    this.company = "",
    this.overview = "",
    required this.points,
  });

  factory RouteMap.fromJson(Map<String, dynamic> json) {
    Iterable list = json['points'];
    var pointsList = list.map((e) => PointMap.fromJson(e)).toList();
    return RouteMap(
      id: json['id'],
      name: json['name'],
      company: json['company'],
      overview: json['overview'],
      points: pointsList,
    );
  }

  Map toMap() {
    var map = <String, dynamic>{};

    map['id'] = id;
    map['name'] = name;
    map['company'] = company;
    map['overview'] = overview;
    map['points'] = points;

    return map;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'company': company,
      'points': points,
    };
  }

  toList() {}
}
