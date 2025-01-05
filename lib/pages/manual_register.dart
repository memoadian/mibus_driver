import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../consts/consts.dart' as consts;
import 'package:http/http.dart' as http;
import '/models_api/employee.dart';
import 'package:toast/toast.dart';

class ManualRegister extends StatefulWidget {
  const ManualRegister({Key? key}) : super(key: key);

  @override
  _ManualRegisterState createState() => _ManualRegisterState();
}

class _ManualRegisterState extends State<ManualRegister> {
  final storage = const FlutterSecureStorage();
  final _codeController = TextEditingController();
  SharedPreferences? _prefs;
  int _selectedRouteId = 0;
  String _auth = '';
  String _driverId = '';

  @override
  void initState() {
    _getDriverData();
    _getRouteData();
    super.initState();
  }

  /// Get driver data
  Future<void> _getDriverData() async {
    _auth = await storage.read(key: 'auth') ?? '';
    _driverId = await storage.read(key: 'id') ?? '';
    setState(() {});
  }

  /// Get the route data
  void _getRouteData() async {
    _prefs = await SharedPreferences.getInstance();
    _selectedRouteId = _prefs?.getInt('routeId') ?? 0;
  }

  /// Get data from user by code
  Future<Employee?> _getUserData() async {
    String code = _codeController.text;

    String url = '${consts.baseUrl}/employees/code/$code';
    final Uri uri = Uri.parse(url);

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $_auth',
    });

    if (response.statusCode == 200) {
      final result = json.decode(response.body)['employee'];
      return Employee.fromJson(result);
    } else {
      return null;
    }
  }

  /// set employee on route
  Future<void> _setEmployeeOnRoute(String code) async {
    String routesUrl = '${consts.baseUrl}/employees/set/$_selectedRouteId';

    final Uri url = Uri.parse(routesUrl);

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        "Authorization": "Bearer $_auth",
      },
      body: jsonEncode(<String, String>{
        'code': code,
        'driverId': _driverId,
      }),
    );

    if (response.statusCode == 200) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Empleado en Ruta"),
          content: const Text("El Empleado fue registrado con éxito"),
          actions: [
            TextButton(
              onPressed: () {
                reassemble();
                Navigator.pop(context);
              },
              child: const Text("Aceptar"),
            ),
          ],
        ),
        barrierDismissible: false,
      );
      setState(() {});
    } else {
      var message = json.decode(response.body);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Ocurrió un error"),
          content: Text("${message['message']}"),
          actions: [
            TextButton(
              onPressed: () {
                reassemble();
                Navigator.pop(context);
              },
              child: const Text("Aceptar"),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Ascenso'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: const Text(
              "Ingresa tus datos de registro manual",
              style: TextStyle(fontSize: 20),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: "Código de registro",
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_codeController.text.isNotEmpty) {
                _getUserData();
                setState(() {});
              } else {
                Toast.show("El código no puede estar vacío",
                    duration: Toast.lengthShort);
              }
            },
            child: const Text("Verificar"),
          ),
          Expanded(
            child: FutureBuilder<Employee?>(
              future: _getUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                }
                if (snapshot.hasData && snapshot.data != null) {
                  Employee employee = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Nombre: ${employee.name}",
                          style: const TextStyle(fontSize: 18),
                        ),
                        Text(
                          "ID: ${employee.id}",
                          style: const TextStyle(fontSize: 18),
                        ),
                        Text(
                          "Email: ${employee.email}",
                          style: const TextStyle(fontSize: 18),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _setEmployeeOnRoute(employee.code);
                          },
                          child: const Text("Registrar ascenso"),
                        ),
                      ],
                    ),
                  );
                }
                return const Center(child: Text("Introduce un código válido."));
              },
            ),
          ),
        ],
      ),
    );
  }
}
