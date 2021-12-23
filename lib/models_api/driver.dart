class Driver {
  String? id;
  String? name;
  String? lastname;
  String? email;
  String? image;
  String? company;

  Driver({
    this.id = "",
    this.name = "",
    this.lastname = "",
    this.email = "",
    this.image = "",
    this.company = "",
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      name: json['name'],
      lastname: json['lastname'],
      email: json['email'],
      image: json['image'],
      company: json['company'],
    );
  }

  Map toMap() {
    var map = <String, dynamic>{};

    map['id'] = id;
    map['name'] = name;
    map['lastname'] = lastname;
    map['email'] = email;
    map['image'] = image;
    map['company'] = company;

    return map;
  }
}
