import 'dart:convert';
import '/models_api/route_map.dart';
import '/services/socket.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../consts/consts.dart' as consts;

class RoutesAvailable extends StatefulWidget {
  final Function(dynamic route) notifyParent;
  final String driverId;

  const RoutesAvailable({
    Key? key,
    required this.notifyParent,
    required this.driverId,
  }) : super(key: key);

  @override
  _RoutesAvailableState createState() => _RoutesAvailableState();
}

class _RoutesAvailableState extends State<RoutesAvailable> {
  final _storage = const FlutterSecureStorage();

  List<RouteMap> _routes = [];
  late RouteMap _route;
  int _currentTimeStamp = 0;

  String _auth = '';

  @override
  void initState() {
    _getData();
    _initTime();
    super.initState();
  }

  Future<void> _getData() async {
    _auth = await _storage.read(key: 'auth') ?? '';

    setState(() {
      _auth = _auth;
    });

    _getRoutes();
  }

  void _initTime() {
    _currentTimeStamp = DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> _getRoutes() async {
    String routesUrl = '${consts.baseUrl}/routes/driver/${widget.driverId}';
    final Uri url = Uri.parse(routesUrl);

    final response = await http.get(
      url,
      headers: {"Authorization": "Bearer $_auth"},
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      Iterable _list = result["routes"];

      _routes = _list.map((model) => RouteMap.fromJson(model)).toList();
      setState(() {});
    } else {
      throw Exception('Failed to load routes');
    }
  }

  Future<void> _getRoute(id) async {
    String routeUrl = '${consts.baseUrl}/routes/$id';

    var _newTime = DateTime.now().millisecondsSinceEpoch;
    if (_newTime - _currentTimeStamp >= 10000) {
      _currentTimeStamp = _newTime;
      final Uri url = Uri.parse(routeUrl);

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final result = json.decode(response.body)['route'];
        _route = RouteMap.fromJson(result);
        widget.notifyParent(_route);
      } else {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);

    socketService.socket.on("rebuildRoute", (payload) {
      var routeId = payload['routeId'];
      _getRoute(routeId);
    });

    return SingleChildScrollView(
      child: Column(
        children: [
          InkWell(
            onTap: () => _getRoutes,
            child: Padding(
              padding: const EdgeInsets.only(top: 30, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "Rutas Disponibles",
                    style: TextStyle(fontSize: 20),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Icon(
                      Icons.refresh,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          (_routes.isEmpty)
              ? Container(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: const CircularProgressIndicator(),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: _routeBuilder,
                  itemCount: _routes.length,
                ),
        ],
      ),
    );
  }

  Widget _routeBuilder(BuildContext context, int index) {
    return InkWell(
      onTap: () => widget.notifyParent(_routes[index]),
      child: ListTile(
        leading: const Icon(Icons.map),
        title: Text(_routes[index].name),
      ),
    );
  }
}
