import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:mibusdriver/models_api/route_map.dart';

import '/models_api/point_map.dart';
import '/providers/directions_provider.dart';
import '/services/socket.dart';
import '/widgets/drawer_widget.dart';
import '/widgets/routes_available.dart';
import '/widgets/sheet_on_route.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:http/http.dart' as http;
import '../consts/consts.dart' as consts;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';

class RouteGuide extends StatefulWidget {
  const RouteGuide({Key? key}) : super(key: key);

  @override
  _RouteGuideState createState() => _RouteGuideState();
}

class _RouteGuideState extends State<RouteGuide> {
  SharedPreferences? _prefs;
  int _currentTimeStamp = 0;
  int _checkTimeStamp = 0;
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(19.4445517, -99.0851149),
    zoom: 12,
  );

  // set initial positions
  final Set<Marker> _markers = <Marker>{};

  //location
  Location location = Location();
  late LocationData _currentLocation;
  late bool _serviceEnabled;
  late PermissionStatus _permissionGranted;

  //maps
  GoogleMapController? _mapController;
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  late GoogleMapController _googleMapController;

  //FLutter polyline
  String googleApiKey = "AIzaSyC11BhEN26L3kn-NIZrLZWuJ0ThQOp2dfs";
  PolylinePoints polylinePoints = PolylinePoints();

  //driver data
  final storage = const FlutterSecureStorage();
  String _name = '';
  String _driverId = '';
  String _selectedRoute = '';
  String _selectedRouteId = '';
  String _auth = '';
  bool _onRoute = false;
  bool _routeFinished = false;

  dynamic _markerIcon;

  @override
  void initState() {
    _getPermissions();
    _getRouteData();
    _initTime();
    _setCheckedIcon();
    _getDriverData();
    super.initState();
  }

  /// CHeck permissions to whow location on init
  Future<bool> _checkPermissions() async {
    _serviceEnabled = await location.serviceEnabled();
    return _serviceEnabled;
  }

  /// Get the permissions to use the location
  void _getPermissions() async {
    try {
      _serviceEnabled = await location.serviceEnabled();
    } on PlatformException catch (e) {
      print(e);
      _serviceEnabled = false;
      _getPermissions();
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _currentLocation = await location.getLocation();
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(_currentLocation.latitude!, _currentLocation.longitude!),
      ),
    );
  }

  /// Get driver data
  Future<void> _getDriverData() async {
    _name = await storage.read(key: 'name') ?? '';
    _driverId = await storage.read(key: 'id') ?? '';
    _auth = await storage.read(key: 'auth') ?? '';
    setState(() {});
  }

  /// Set time init to send location
  void _initTime() {
    _currentTimeStamp = DateTime.now().millisecondsSinceEpoch;
    _checkTimeStamp = DateTime.now().millisecondsSinceEpoch;
  }

  /// Set icon check point on map
  void _setCheckedIcon() async {
    _markerIcon = await getBytesFromAsset('assets/location.png', 100);
  }

  /// Transform icon to bytes to put on map
  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  /// Get the route data
  void _getRouteData() async {
    _prefs = await SharedPreferences.getInstance();
    _selectedRoute = _prefs?.getString('route') ?? '';
    _selectedRouteId = _prefs?.getString('routeId') ?? '';
    _onRoute = _prefs?.getBool('onRoute') ?? false;
    _routeFinished = _prefs?.getBool('routeFinished') ?? false;
  }

  ///Init route data
  dynamic _initRoute(dynamic _isOnRoute) {
    _onRoute = _isOnRoute;
    _prefs?.setBool('onRoute', _onRoute);
    _joinToRoute(context);
    setState(() {});
  }

  /// Join to route socket server
  void _joinToRoute(BuildContext context) async {
    final socketService = Provider.of<SocketService>(context, listen: false);

    if (_onRoute) {
      socketService.socket.emit("join", {
        "route": _selectedRoute,
      });
      _getNextPoint();
    } else {
      socketService.socket.emit("leave", {
        "route": _selectedRoute,
      });
      _prefs?.setBool("routeFinished", false);
      _routeFinished = false;
    }
  }

  /// Register point checked
  void _checkPoint() async {
    final minutes = 0.2;
    final pointId = _prefs?.getString('nextPointId');
    final routeId = _prefs?.getString('routeId');

    String url = '${consts.baseUrl}/points/check/';
    final Uri uri = Uri.parse(url);

    if (_routeFinished) {
      return;
    }

    var _newTime = DateTime.now().millisecondsSinceEpoch;
    if (_newTime - _checkTimeStamp >= 60000 * minutes) {
      _checkTimeStamp = _newTime;
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_auth',
        },
        body: json.encode(
          {
            "nextPointId": pointId,
            "routeId": routeId,
          },
        ),
      );

      final result = json.decode(response.body);
      print(result);

      if (response.statusCode == 200) {
        _getNextPoint();
      } else {
        Toast.show(
          result['message'],
          duration: Toast.lengthLong,
        );
      }
    } else {
      final left = (60000 * minutes - (_newTime - _checkTimeStamp)) / 1000;
      print("faltan $left segundos");
    }
  }

  /// Get next point to check in on the route
  Future<void> _getNextPoint() async {
    String routeId = _prefs?.getString("routeId") ?? '';
    var _routeFinished = _prefs?.getBool("routeFinished") ?? false;

    String url = "${consts.baseUrl}/routes/next_point/$routeId";
    Uri uri = Uri.parse(url);

    if (!_routeFinished) {
      final response = await http.get(uri, headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_auth',
      });

      if (response.statusCode == 200) {
        final result = json.decode(response.body)['nextPoint'];
        final point = PointMap.fromJson(result);

        _prefs?.setString('nextLat', point.lat.toString());
        _prefs?.setString('nextLng', point.lng.toString());
        _prefs?.setString('nextPointId', point.id);

        _getRoute(routeId);
      } else {
        _finishRoute(routeId);
      }

      var socket = Provider.of<SocketService>(context, listen: false);
      socket.socket.emit("rebuildRoute", {
        "route": _selectedRoute,
        "routeId": routeId,
      });
    } else {
      Toast.show(
        "ruta finalizada",
        duration: Toast.lengthLong,
      );
    }
  }

  /// get route points
  /// @param routeId
  Future<void> _getRoute(routeId) async {
    String routeUrl = '${consts.baseUrl}/routes/$routeId';
    final Uri url = Uri.parse(routeUrl);

    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $_auth',
    });

    if (response.statusCode == 200) {
      final _result = json.decode(response.body)['route'];
      final _route = RouteMap.fromJson(_result);

      _rebuildMarkers(_route);
    } else {
      Toast.show(
        response.body,
        duration: Toast.lengthLong,
      );
    }
  }

  /// Ser route on map
  dynamic _updateRoute(dynamic route) {
    _selectedRoute = route.name;
    _selectedRouteId = route.id;
    _prefs!.setString("route", _selectedRoute);
    _prefs!.setString("routeId", _selectedRouteId);
    _joinToRoute(context);
    _rebuildMarkers(route);
  }

  Future<void> _finishRoute(routeId) async {
    String url = "${consts.baseUrl}/routes/finish/$routeId";
    Uri uri = Uri.parse(url);

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_auth',
      },
    );

    if (response.statusCode == 200) {
      _prefs?.setBool("routeFinished", true);
      _routeFinished = true;
      _onRoute = false;
      _prefs?.setBool("onRoute", false);
      _prefs?.remove('nextLat');
      _prefs?.remove('nextLng');
      _prefs?.remove('nextPointId');
      _checkLastPoint(routeId);
      _getRoute(routeId);
    } else {
      Toast.show(
        response.body,
        duration: Toast.lengthLong,
      );
    }
  }

  Future<void> _checkLastPoint(routeId) async {
    String url = "${consts.baseUrl}/checkpoints/last/$routeId";
    Uri uri = Uri.parse(url);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $_auth',
      },
    );

    if (response.statusCode == 200) {
      Toast.show(
        "Ruta finalizada con éxito",
        duration: Toast.lengthLong,
      );
    }
  }

  /// Send data socket to server
  void _sendDataSocket(socketService, newLocation) {
    if (_onRoute) {
      var _newTime = DateTime.now().millisecondsSinceEpoch;
      if (_newTime - _currentTimeStamp >= 1000) {
        _currentTimeStamp = _newTime;
        print("enviando ubicacion");
        socketService.socket.emit("sendLocation", {
          "uuid": _name,
          "lat": newLocation.latitude,
          "lng": newLocation.longitude,
          "route": _selectedRoute,
          "routeId": _selectedRouteId,
          //"nextPointId": _prefs?.getString('nextPointId'),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ToastContext().init(context);
    final socketService = Provider.of<SocketService>(context);

    location.onLocationChanged.listen((LocationData loc) {
      var nextLat = double.parse(_prefs?.getString('nextLat') ?? '0');
      var nextLng = double.parse(_prefs?.getString('nextLng') ?? '0');
      _sendDataSocket(socketService, loc);
      var lat = loc.latitude;
      var lng = loc.longitude;
      var _distance = _haversine(lat!, lng!, nextLat, nextLng);
      if (!_routeFinished) {
        print("la distancia es $_distance");
      }
      if (_distance <= 0.02) {
        _checkPoint();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('MiBus Conductor'),
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.all(10),
            child: Image.asset("assets/icons/icon.png"),
          ),
        ],
      ),
      body: Consumer<DirectionProvider>(
        builder: (context, api, child) {
          return FutureBuilder(
            initialData: false,
            future: _checkPermissions(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return GoogleMap(
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                  initialCameraPosition: _initialCameraPosition,
                  myLocationEnabled: true,
                  markers: _markers,
                  polylines:
                      Set<Polyline>.of(polylines.values), //api.currentRoute,
                  onMapCreated: _onMapCreated,
                );
              }
              return Center(
                child: CircularProgressIndicator(),
              );
            },
          );
        },
      ),
      drawer: const DrawerWidget(),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 10, bottom: 30),
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.pushNamed(context, 'qr');
                },
                child: const Icon(Icons.qr_code),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 30, right: 10),
              child: FloatingActionButton(
                onPressed: () => showModalBottomSheet(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  context: context,
                  builder: (_) => RoutesAvailable(
                    notifyParent: _updateRoute,
                    driverId: _driverId,
                  ),
                ),
                child: const Icon(Icons.map),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, bottom: 30),
              child: FloatingActionButton(
                onPressed: () => showModalBottomSheet(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  context: context,
                  builder: (_) => SheetOnRoute(
                    driverId: _driverId,
                    notifyParent: _initRoute,
                  ),
                ),
                child: const Icon(Icons.drive_eta),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  /// Center view on select route
  void _centerView(RouteMap route) async {
    //var api = Provider.of<DirectionProvider>(context, listen: false);
    await _mapController!.getVisibleRegion();

    //api.findDirections(_fromPoint, _toPoint, _points);

    var _fromLat = double.parse(route.points[0].lat);
    var _fromLng = double.parse(route.points[0].lng);
    var _toLat = double.parse(route.points[route.points.length - 1].lat);
    var _toLng = double.parse(route.points[route.points.length - 1].lng);

    var left = min(_fromLat, _toLat);
    var right = max(_fromLat, _toLat);
    var top = max(_fromLng, _toLng);
    var bottom = min(_fromLng, _toLng);

    for (var point in route.points) {
      left = min(left, double.parse(point.lat));
      right = max(right, double.parse(point.lat));
      top = max(top, double.parse(point.lng));
      bottom = min(bottom, double.parse(point.lng));
    }

    var bounds = LatLngBounds(
      southwest: LatLng(left, bottom),
      northeast: LatLng(right, top),
    );

    var cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 50);
    _mapController!.animateCamera(cameraUpdate);
    //});
  }

  /// clear markers and polylines
  void _clearMarkers() {
    _markers.clear();
  }

  /// Add marker to map
  void _addMarker({required PointMap point, var prefix}) {
    Marker marker = Marker(
      markerId: MarkerId("${prefix}_${point.name}"),
      position: LatLng(
        double.parse(point.lat),
        double.parse(point.lng),
      ),
      infoWindow: InfoWindow(
        title: (point.name.length >= 30)
            ? point.name.substring(0, 30)
            : point.name,
        snippet: {point.lat, point.lng}.toString(),
      ),
      icon: (point.checked)
          ? BitmapDescriptor.fromBytes(_markerIcon)
          : BitmapDescriptor.defaultMarker,
    );
    _markers.add(marker);
  }

  /// Draw polylin on route selected
  void _rebuildMarkers(route) {
    _clearMarkers();

    for (var e in route.points) {
      _addMarker(point: e, prefix: 'e-${e.lat}${e.lng}');
    }

    _centerView(route);
    _addPolyLine(route);
  }

  /// Add polyline to map
  void _addPolyLine(RouteMap route) {
    var polylineCoordinates = <LatLng>[];
    String _polyline = route.overview;
    List<PointLatLng> points = polylinePoints.decodePolyline(
      _polyline,
    );
    points.forEach((e) {
      polylineCoordinates.add(LatLng(e.latitude, e.longitude));
    });
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 4,
    );
    polylines[id] = polyline;
    setState(() {});
  }

  /// Haversine formula
  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    var R = 6372.8; // In kilometers
    var dLat = _toRadians(lat2 - lat1);
    var dLon = _toRadians(lon2 - lon1);
    lat1 = _toRadians(lat1);
    lat2 = _toRadians(lat2);

    var a = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
    var c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  _toRadians(double degree) {
    return (degree * pi) / 180;
  }

  @override
  void dispose() {
    _googleMapController.dispose();
    super.dispose();
  }
}
