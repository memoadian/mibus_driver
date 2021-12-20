import 'driver.dart';

class LoginResult {
  String message;
  String? token;
  Driver? driver;

  LoginResult({
    this.message = "",
    this.token = "",
    this.driver,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    if (json['driver'] != null) {
      return LoginResult(
        message: json['message'],
        driver: Driver.fromJson(json['driver']),
        token: json['token'],
      );
    } else {
      return LoginResult(
        message: json['message'],
        token: json['token'],
      );
    }
  }

  Map toMap() {
    var map = <String, dynamic>{};

    map['message'] = message;
    map['driver'] = driver;
    map['token'] = token;

    return map;
  }
}
