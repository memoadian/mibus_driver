import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;
import '../consts/consts.dart' as consts;

class QRScanner extends StatelessWidget {
  const QRScanner({Key? key}) : super(key: key);

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
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, 'qr_reader');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[400],
              fixedSize: const Size(300, 50),
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            label: const Text('Registrar Ascenso'),
            icon: const Icon(Icons.upload),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, 'qr_down');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[400],
                fixedSize: const Size(300, 50),
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              label: const Text('Registrar Descenso'),
              icon: const Icon(Icons.download),
            ),
          ),
        ],
      ),
    );
  }
}

class QRReader extends StatefulWidget {
  const QRReader({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRReaderState();
}

class _QRReaderState extends State<QRReader> {
  final _storage = const FlutterSecureStorage();
  String _driverId = '';
  String _auth = '';

  SharedPreferences? _prefs;
  String _selectedRouteId = '';

  @override
  initState() {
    _getDriverData();
    _getRouteData();
    super.initState();
  }

  Future<void> _getDriverData() async {
    _auth = await _storage.read(key: 'auth') ?? '';
    _driverId = await _storage.read(key: 'id') ?? '';
    setState(() {});
  }

  _getRouteData() async {
    _prefs = await SharedPreferences.getInstance();
    _selectedRouteId = _prefs?.getString('routeId') ?? '';
  }

  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  void back() {
    controller!.stopCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: _buildQrView(context),
          ),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  if (result != null)
                    Text(
                      'Resultado: ${result!.code}',
                    )
                  else
                    const Text('Escanear el código'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                          onPressed: () async {
                            await controller?.toggleFlash();
                            setState(() {});
                          },
                          child: FutureBuilder(
                            future: controller?.getFlashStatus(),
                            builder: (context, snapshot) {
                              return Text('Flash: ${snapshot.data}');
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 300.0
        : 300.0;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      back();
      setState(() {
        result = scanData;
        if (result != null) {
          _setEmployeeOnRoute(result!.code);
        }
      });
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('no Permission'),
        ),
      );
    }
  }

  Future<void> _setEmployeeOnRoute(String? code) async {
    String routesUrl = '${consts.baseUrl}/employees/set/$_selectedRouteId';

    final Uri url = Uri.parse(routesUrl);

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        "Authorization": "Bearer $_auth"
      },
      body: jsonEncode(<String, String>{
        'code': code!,
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
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

class QRReaderDown extends StatefulWidget {
  const QRReaderDown({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRReaderStateDown();
}

class _QRReaderStateDown extends State<QRReaderDown> {
  final _storage = const FlutterSecureStorage();
  String _driverId = '';
  String _auth = '';

  SharedPreferences? _prefs;
  String _selectedRouteId = '';

  @override
  initState() {
    _getDriverData();
    _getRouteData();
    super.initState();
  }

  Future<void> _getDriverData() async {
    _auth = await _storage.read(key: 'auth') ?? '';
    _driverId = await _storage.read(key: 'id') ?? '';
    setState(() {});
  }

  _getRouteData() async {
    _prefs = await SharedPreferences.getInstance();
    _selectedRouteId = _prefs?.getString('routeId') ?? '';
  }

  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  void back() {
    controller!.stopCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: _buildQrView(context),
          ),
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  if (result != null)
                    Text(
                      'Resultado: ${result!.code}',
                    )
                  else
                    const Text('Escanear el código'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                          onPressed: () async {
                            await controller?.toggleFlash();
                            setState(() {});
                          },
                          child: FutureBuilder(
                            future: controller?.getFlashStatus(),
                            builder: (context, snapshot) {
                              return Text('Flash: ${snapshot.data}');
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 300.0
        : 300.0;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      back();
      setState(() {
        result = scanData;
        if (result != null) {
          _setEmployeeOffRoute(result!.code);
        }
      });
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('no Permission'),
        ),
      );
    }
  }

  Future<void> _setEmployeeOffRoute(String? code) async {
    String routesUrl = '${consts.baseUrl}/employees/off/$_selectedRouteId';

    final Uri url = Uri.parse(routesUrl);

    final response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        "Authorization": "Bearer $_auth"
      },
      body: jsonEncode(<String, String>{
        'code': code!,
        'driverId': _driverId,
      }),
    );

    if (response.statusCode == 200) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Empleado fuera de Ruta"),
          content: const Text("El empleado dejó la ruta con éxito"),
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
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
