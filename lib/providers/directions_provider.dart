import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
// ignore: import_of_legacy_library_into_null_safe
import 'package:google_maps_webservice/directions.dart';

class DirectionProvider extends ChangeNotifier {
  GoogleMapsDirections directionsApi = GoogleMapsDirections(
    apiKey: "AIzaSyC11BhEN26L3kn-NIZrLZWuJ0ThQOp2dfs",
  );

  Set<maps.Polyline> _route = {};

  Set<maps.Polyline> get currentRoute => _route;

  findDirections(maps.LatLng from, maps.LatLng to, waypoints) async {
    var origin = Location(from.latitude, from.longitude);
    var destiny = Location(to.latitude, to.longitude);
    var result = await directionsApi.directionsWithLocation(
      origin,
      destiny,
      waypoints: waypoints,
      travelMode: TravelMode.driving,
    );

    Set<maps.Polyline> newRoute = {};

    if (result.isOkay) {
      var route = result.routes[0];
      List<maps.LatLng> points = [];

      for (var leg in route.legs) {
        for (var step in leg.steps) {
          points.add(maps.LatLng(
            step.startLocation.lat,
            step.startLocation.lng,
          ));
          points.add(maps.LatLng(
            step.endLocation.lat,
            step.endLocation.lng,
          ));
        }

        var line = maps.Polyline(
          points: points,
          polylineId: const maps.PolylineId("mejor ruta"),
          color: Colors.red,
          width: 4,
        );
        newRoute.add(line);
      }

      _route = newRoute;
      notifyListeners();
    } else {
      //print("ERRROR !!! ${result.status}");
    }
  }
}
