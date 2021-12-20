import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../consts/consts.dart' as consts;
import 'package:toast/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SheetOnRoute extends StatefulWidget {
  final String? selectedRoute;
  final String? selectedRouteId;
  final String? driverId;
  final Function(dynamic isOnRoute) notifyParent;

  const SheetOnRoute({
    Key? key,
    this.selectedRoute,
    this.selectedRouteId,
    this.driverId,
    required this.notifyParent,
  }) : super(key: key);

  @override
  _SheetOnRouteState createState() => _SheetOnRouteState();
}

class _SheetOnRouteState extends State<SheetOnRoute> {
  SharedPreferences? _prefs;
  bool _onRoute = false;

  @override
  initState() {
    _isOnRoute();
    super.initState();
  }

  _isOnRoute() async {
    _prefs = await SharedPreferences.getInstance();
    _onRoute = _prefs?.getBool('on_route') ?? false;
    setState(() {});
  }

  Future<void> _initRoute() async {
    _showDialog("Iniciando Ruta");

    var s = widget.selectedRouteId;
    String url = '${consts.baseUrl}/routes/init/$s';
    final Uri uri = Uri.parse(url);

    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
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
      Toast.show('Se ha iniciado la ruta', context);
    } else {
      Toast.show(result['message'], context);
    }
    Navigator.pop(context);
    setState(() {});
  }

  Future<void> _endRoute() async {
    _showDialog("Finalizando Ruta");
    var s = widget.selectedRouteId;
    String url = '${consts.baseUrl}/routes/finish/$s';

    final Uri uri = Uri.parse(url);
    final response = await http.post(
      uri,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'driverId': widget.driverId!,
      }),
    );

    final result = json.decode(response.body);

    if (response.statusCode == 200) {
      _onRoute = false;
      widget.notifyParent(false);
      _prefs?.setBool('on_route', false);
      Toast.show('Se ha finalizado la ruta', context);
    } else {
      Toast.show(result['message'], context);
    }
    _prefs?.setBool('on_route', false);
    Navigator.pop(context);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 12),
            child: (widget.selectedRoute != '')
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
            padding: (widget.selectedRoute != '')
                ? const EdgeInsets.only(top: 10, bottom: 10)
                : const EdgeInsets.only(top: 0),
            child: (widget.selectedRoute != '')
                ? Text(
                    widget.selectedRoute!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                : const Center(),
          ),
          (!_onRoute)
              ? ElevatedButton(
                  onPressed: () {
                    if (widget.selectedRoute != '') {
                      _initRoute();
                    } else {
                      Toast.show("Selecciona una ruta primero", context);
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: DropdownButton(
                    isExpanded: true,
                    value: "0",
                    items: const [
                      DropdownMenuItem(
                        child: Text("Seleccionar"),
                        value: "0",
                      ),
                      DropdownMenuItem(
                        child: Text("Finalizado"),
                        value: "1",
                      ),
                      DropdownMenuItem(
                        child: Text("Falla Mecánica"),
                        value: "2",
                      ),
                      DropdownMenuItem(
                        child: Text("Avería"),
                        value: "3",
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        //_selected = value;
                      });
                    }),
              ),
              ElevatedButton(
                onPressed: () => _endRoute(),
                child: const Text("Finalizar"),
              ),
            ],
          ),
        );
      },
    );
  }
}
