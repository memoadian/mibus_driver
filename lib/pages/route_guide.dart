import 'dart:convert';
import 'dart:developer';
import 'dart:math';
import 'dart:typed_data';
import '/models_api/point_map.dart';
import '/providers/directions_provider.dart';
import '/services/socket.dart';
import '/widgets/drawer_widget.dart';
import '/widgets/routes_available.dart';
import '/widgets/sheet_on_route.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:google_maps_webservice/directions.dart' as dirs;
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
  static const _initialCameraPosition = CameraPosition(
    target: LatLng(19.4445517, -99.0851149),
    zoom: 12,
  );

  // set initial positions
  LatLng _fromPoint = const LatLng(19.311980, -99.042600);
  LatLng _toPoint = const LatLng(19.314345, -99.039363);
  List<dirs.Waypoint> _points = [];
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
  List<PolylineWayPoint> _polywaypts = [];

  //driver data
  final storage = const FlutterSecureStorage();
  String _name = '';
  String _driverId = '';
  String _selectedRoute = '';
  String _selectedRouteId = '';
  bool _onRoute = false;

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

  /// Get Permissions
  /// Get the permissions to use the location
  void _getPermissions() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
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

  /// Get the route data
  void _getRouteData() async {
    _prefs = await SharedPreferences.getInstance();
    _selectedRouteId = _prefs?.getString('routeId') ?? '';
  }

  void _initTime() {
    _currentTimeStamp = DateTime.now().millisecondsSinceEpoch;
  }

  void _setCheckedIcon() async {
    _markerIcon = await getBytesFromAsset('assets/location.png', 100);
  }

  Future<void> _getDriverData() async {
    _name = await storage.read(key: 'name') ?? '';
    _driverId = await storage.read(key: 'id') ?? '';
    setState(() {});
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Future<void> _getNextPoint() async {
    String routeId = _prefs?.getString("routeId") ?? '';

    String url = "${consts.baseUrl}/routes/next_point/$routeId";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final result = json.decode(response.body)['nextPoint'];
      final point = PointMap.fromJson(result);

      _prefs?.setString('nextLat', point.lat.toString());
      _prefs?.setString('nextLng', point.lng.toString());
      _prefs?.setString('nextPointId', point.id);
    } else {
      Toast.show(
        'Error',
        context,
        duration: Toast.lengthLong,
      );
    }
  }

  void _clearMarkers() {
    _markers.clear();
    setState(() {});
  }

  dynamic _updateRoute(dynamic route) {
    inspect(route);
    _rebuildPolyline(route);
    setState(() {});
  }

  ///Init route data
  dynamic _initRoute(dynamic _isOnRoute) {
    _onRoute = _isOnRoute;
    _prefs?.setString("routeId", _selectedRouteId);
    _joinToRoute(context);
    setState(() {});
  }

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
    }
  }

  void _sendDataSocket(socketService, newLocation) {
    var nextLat = _prefs?.getString('nextLat');
    var nextLng = _prefs?.getString('nextLng');
    if (_onRoute) {
      var _newTime = DateTime.now().millisecondsSinceEpoch;
      if (_newTime - _currentTimeStamp >= 1000) {
        _currentTimeStamp = _newTime;
        if (nextLng != null && nextLat != null) {
          socketService.socket.emit("sendLocation", {
            "uuid": _name,
            "lat": newLocation.latitude,
            "lng": newLocation.longitude,
            "destination_lat": _prefs?.getString('nextLat'),
            "destination_lng": _prefs?.getString('nextLng'),
            "route": _selectedRoute,
            "routeId": _selectedRouteId,
            "nextPointId": _prefs?.getString('nextPointId'),
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);

    location.onLocationChanged.listen((LocationData newLocation) {
      _sendDataSocket(socketService, newLocation);
    });

    socketService.socket.on("rebuildRoute", (payload) {
      _getNextPoint();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('MiBus Conductor'),
      ),
      body: Consumer<DirectionProvider>(
        builder: (context, api, child) {
          return GoogleMap(
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            initialCameraPosition: _initialCameraPosition,
            myLocationEnabled: true,
            markers: _markers,
            polylines: Set<Polyline>.of(polylines.values), //api.currentRoute,
            onMapCreated: _onMapCreated,
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
                    selectedRoute: _selectedRoute,
                    selectedRouteId: _selectedRouteId,
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

  void _centerView(BuildContext context) async {
    var api = Provider.of<DirectionProvider>(context, listen: false);
    await _mapController!.getVisibleRegion();

    api.findDirections(_fromPoint, _toPoint, _points);

    var left = min(_fromPoint.latitude, _toPoint.latitude);
    var right = max(_fromPoint.latitude, _toPoint.latitude);
    var top = max(_fromPoint.longitude, _toPoint.longitude);
    var bottom = min(_fromPoint.longitude, _toPoint.longitude);

    for (var point in api.currentRoute.first.points) {
      left = min(left, point.latitude);
      right = max(right, point.latitude);
      top = max(top, point.longitude);
      bottom = min(bottom, point.longitude);
    }

    var bounds = LatLngBounds(
      southwest: LatLng(left, bottom),
      northeast: LatLng(right, top),
    );

    var cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 50);
    _mapController!.animateCamera(cameraUpdate);
  }

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

  void _rebuildPolyline(route) {
    _clearMarkers();

    for (var e in route.points) {
      _addMarker(point: e, prefix: 'e');
    }
    _addMarker(point: route.origin, prefix: 'o');
    _addMarker(point: route.destiny, prefix: 'd');
    _selectedRoute = route.name;
    _selectedRouteId = route.id;
    _fromPoint = LatLng(
      double.parse(route.origin.lat),
      double.parse(route.origin.lng),
    );
    _toPoint = LatLng(
      double.parse(route.destiny.lat),
      double.parse(route.destiny.lng),
    );
    _points = route.points
        .map<dirs.Waypoint>(
          (e) => dirs.Waypoint(e.name),
        )
        .toList();
    _polywaypts = route.points
        .map<PolylineWayPoint>(
          (e) => PolylineWayPoint(location: e.name),
        )
        .toList();
    setState(() {});
    _centerView(context);
    _getPolyline();
  }

  void _getPolyline() async {
    polylineCoordinates.clear();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey,
      PointLatLng(_fromPoint.latitude, _fromPoint.longitude),
      PointLatLng(_toPoint.latitude, _toPoint.longitude),
      travelMode: TravelMode.driving,
      wayPoints: _polywaypts,
    );
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
    }
    _addPolyLine();
  }

  void _addPolyLine() {
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

  @override
  void dispose() {
    _googleMapController.dispose();
    super.dispose();
  }
}
