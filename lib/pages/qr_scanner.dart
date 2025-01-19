import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import '../consts/consts.dart' as consts;
import 'package:http/http.dart' as http;

class QRScanner extends StatefulWidget {
  const QRScanner({Key? key}) : super(key: key);

  @override
  _QRScannerState createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  final storage = const FlutterSecureStorage();
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
      appBar: AppBar(title: const Text('Registrar Ascenso')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
                top: 50, left: 100, right: 100, bottom: 60),
            child: Image.asset("assets/qr-code.png"),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
            child: ElevatedButton.icon(
              onPressed: () async {
                String? code = await SimpleBarcodeScanner.scanBarcode(
                  context,
                  barcodeAppBar: const BarcodeAppBar(
                    appBarTitle: 'Test',
                    centerTitle: false,
                    enableBackButton: true,
                    backButtonIcon: Icon(Icons.arrow_back_ios),
                  ),
                  isShowFlashIcon: true,
                  delayMillis: 500,
                  cameraFace: CameraFace.back,
                  scanFormat: ScanFormat.ALL_FORMATS,
                );
                if (code != null) {
                  _setEmployeeOnRoute(code);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[400],
                fixedSize: Size(MediaQuery.of(context).size.width, 50),
              ),
              label: const Text(
                'Registrar Ascenso',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              icon: const Icon(
                Icons.upload,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, 'manual');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[100],
                fixedSize: Size(MediaQuery.of(context).size.width, 50),
              ),
              label: const Text(
                'Registro Manual',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              icon: const Icon(
                Icons.keyboard,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, 'qr_down');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[100],
                fixedSize: Size(MediaQuery.of(context).size.width, 50),
              ),
              label: const Text(
                'Registrar Descenso',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              icon: const Icon(
                Icons.download,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
