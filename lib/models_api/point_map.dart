class PointMap {
  String id;
  String name;
  String lat;
  String lng;
  bool checked;

  PointMap({
    this.id = "",
    this.name = "",
    this.lat = "",
    this.lng = "",
    this.checked = false,
  });

  factory PointMap.fromJson(Map<String, dynamic> json) {
    return PointMap(
      id: json['_id'],
      name: json['name'],
      lat: json['lat'],
      lng: json['lng'],
      checked: json['checked'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'lat': lat,
      'lng': lng,
      'checked': checked,
    };
  }
}
