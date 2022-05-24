import '/models_api/login_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../consts/consts.dart' as consts;
import 'dart:convert';
import 'package:toast/toast.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  late SharedPreferences prefs;
  late String token;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final storage = const FlutterSecureStorage();
  bool _passwordVisible = false;

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.initState();
  }

  Future<void> _requestLogin(context) async {
    prefs = await SharedPreferences.getInstance();
    String loginUrl = '${consts.baseUrl}/drivers/login';
    final Uri url = Uri.parse(loginUrl);

    try {
      final response = await http.post(url, body: {
        'email': _emailController.text,
        'password': _passwordController.text,
      });

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        var login = LoginResult.fromJson(result);

        await storage.write(key: 'auth', value: login.token);
        await storage.write(key: 'id', value: login.driver?.id);
        await storage.write(key: 'name', value: login.driver?.name);
        await storage.write(key: 'email', value: login.driver?.email);
        await storage.write(key: 'company', value: login.driver?.company);
        await storage.write(key: 'img', value: login.driver?.image);

        Navigator.pop(context);
        Navigator.pushReplacementNamed(context, 'route_guide');
        await prefs.setBool('isLoggedIn', true);
      } else if (response.statusCode == 401) {
        final result = json.decode(response.body);
        var login = LoginResult.fromJson(result);

        Toast.show(
          login.message,
          context,
          duration: Toast.lengthLong,
          gravity: Toast.bottom,
        );
        Navigator.pop(context);
      } else {
        Toast.show(
          "Ocurrió un error al iniciar sesión",
          context,
          duration: Toast.lengthLong,
          gravity: Toast.bottom,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      Toast.show(
        "Error de conexión con el servidor",
        context,
        duration: Toast.lengthLong,
        gravity: Toast.bottom,
      );
      Navigator.pop(context);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
            ),
            child: Column(
              children: [
                Container(
                  width: 200,
                  margin: const EdgeInsets.only(top: 70, bottom: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset("assets/conductor.png"),
                ),
                Container(
                  margin: const EdgeInsets.only(
                    bottom: 8,
                  ),
                  child: const Text(
                    "Bienvenido a MiBus Conductor",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF223263),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(
                    bottom: 28,
                  ),
                  child: const Text(
                    "Inicia sesión para continuar",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF9098B1),
                    ),
                  ),
                ),
                _loginForm(),
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(
                        top: 30,
                        bottom: 10,
                      ),
                      child: InkWell(
                        onTap: () => Navigator.pushNamed(context, "reset"),
                        child: const Text(
                          "¿Olvidaste tu contraseña?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF007AFE),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginForm() {
    return Form(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(
              bottom: 8,
            ),
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                prefixIcon: Icon(
                  Icons.email_outlined,
                ),
                hintText: "Correo Electrónico",
                hintStyle: TextStyle(
                  color: Color(0xFF9098B1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color(0xFFEBF0FF),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color(0xFFcee3f2),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(
              bottom: 16,
            ),
            child: TextFormField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.lock_outline,
                ),
                hintText: "Contraseña",
                hintStyle: const TextStyle(
                  color: Color(0xFF9098B1),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color(0xFFEBF0FF),
                    width: 1.5,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color(0xFFcee3f2),
                    width: 1.5,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Theme.of(context).primaryColorDark,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordVisible = !_passwordVisible;
                    });
                  },
                ),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: const Color(0xFF007AFE),
              ),
              child: const Text(
                "Iniciar Sesión",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                showLoaderDialog(context);
                _requestLogin(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  showLoaderDialog(BuildContext context) {
    AlertDialog alert = AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          Container(
            margin: const EdgeInsets.only(left: 7),
            child: const Text("Loading..."),
          ),
        ],
      ),
    );
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
