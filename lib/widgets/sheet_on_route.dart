import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mibusdriver/models_api/options_end.dart';
import '../consts/consts.dart' as consts;
import 'package:toast/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SheetOnRoute extends StatefulWidget {
  final String? driverId;
  final Function(dynamic isOnRoute) notifyParent;

  const SheetOnRoute({
    Key? key,
    this.driverId,
    required this.notifyParent,
  }) : super(key: key);

  @override
  _SheetOnRouteState createState() => _SheetOnRouteState();
}

class _SheetOnRouteState extends State<SheetOnRoute> {
  final _storage = const FlutterSecureStorage();
  SharedPreferences? _prefs;
  String _route = "";
  bool _onRoute = false;
  String _hint = "Finalizado";
  String _auth = '';

  final List<OptionsEnd> _data = [
    OptionsEnd(key: "1", value: "Finalizado"),
    OptionsEnd(key: "2", value: "Falla mecánica"),
    OptionsEnd(key: "3", value: "Avería"),
  ];

  @override
  initState() {
    _isOnRoute();
    _getDriverData();
    super.initState();
  }

  _isOnRoute() async {
    _prefs = await SharedPreferences.getInstance();
    _route = _prefs?.getString('route') ?? "";
    _onRoute = _prefs?.getBool('onRoute') ?? false;
    setState(() {});
  }

  Future<void> _getDriverData() async {
    _auth = await _storage.read(key: 'auth') ?? '';
    setState(() {});
  }

  Future<void> _initRoute() async {
    _showDialog("Iniciando Ruta");

    var s = _prefs?.getString('routeId') ?? '';
    String url = '${consts.baseUrl}/routes/init/$s';
    final Uri uri = Uri.parse(url);

    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        "Authorization": "Bearer $_auth"
      },
      body: jsonEncode(<String, String>{
        'driverId': widget.driverId!,
      }),
    );

    final result = json.decode(response.body);

    if (response.statusCode == 200) {
      _onRoute = true;
      widget.notifyParent(true);
      _prefs?.setBool('on_route', true);
      Toast.show(
        'Se ha iniciado la ruta',
      );
    } else {
      Toast.show(result['message']);
    }
    Navigator.pop(context);
    setState(() {});
  }

  Future<void> _endRoute() async {
    _showDialog("Finalizando Ruta");
    var s = _prefs?.getString('routeId') ?? '';
    String url = '${consts.baseUrl}/routes/finish/$s';

    final Uri uri = Uri.parse(url);
    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        "Authorization": "Bearer $_auth"
      },
      body: jsonEncode(<String, String>{
        'driverId': widget.driverId!,
      }),
    );

    final result = json.decode(response.body);

    if (response.statusCode == 200) {
      Toast.show('Se ha finalizado la ruta');
    } else {
      Toast.show(result['message']);
    }
    _onRoute = false;
    _prefs?.setString('route', '');
    _prefs?.setString('routeId', '');
    _prefs?.setBool('on_route', false);
    widget.notifyParent(false);
    Navigator.pop(context);
    Future.delayed(const Duration(milliseconds: 200), () {
      Navigator.pop(context);
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 12),
            child: (_route != '')
                ? const Text(
                    "Ruta seleccionada:",
                    style: TextStyle(fontSize: 14),
                  )
                : const Text(
                    "Selecciona una ruta primero",
                    style: TextStyle(fontSize: 14),
                  ),
          ),
          Container(
            padding: (_route != '')
                ? const EdgeInsets.only(top: 10, bottom: 10)
                : const EdgeInsets.only(top: 0),
            child: (_route != '')
                ? Text(
                    _route,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                : const Center(),
          ),
          (!_onRoute)
              ? ElevatedButton(
                  onPressed: () {
                    if (_route != '') {
                      _initRoute();
                    } else {
                      Toast.show("Selecciona una ruta primero");
                    }
                    setState(() {});
                  },
                  child: const Text(
                    "Iniciar Ruta",
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Colors.red,
                  ),
                  onPressed: () {
                    //if (widget.selectedRoute != '') {
                    //_endRoute();
                    //}
                    _formEndRoute("Finalizar Ruta");
                    setState(() {});
                  },
                  child: const Text(
                    "Terminar Ruta",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
        ],
      ),
    );
  }

  void _showDialog(String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
            ],
          ),
        );
      },
    );
  }

  void _formEndRoute(String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: DropdownButton<OptionsEnd>(
                      hint: Text(_hint),
                      isExpanded: true,
                      onChanged: (value) {
                        _hint = value!.value!; //texto
                        setState(() {});
                      },
                      items: _data
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Text(v.value!),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _endRoute(),
                    child: const Text("Finalizar"),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
