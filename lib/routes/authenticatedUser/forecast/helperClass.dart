import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../../../constants.dart' as Constants;

class HelperClass {
  List _decodePoly(String poly) {
    var list = poly.codeUnits;
    var lList = [];
    int index = 0;
    int len = poly.length;
    int c = 0;
    do {
      var shift = 0;
      int result = 0;

      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);
      if (result & 1 == 1) {
        result = ~result;
      }
      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);

    for (var i = 2; i < lList.length; i++) lList[i] += lList[i - 2];

    return lList;
  }

  List<LatLng> _convertToLatLng(List points) {
    List<LatLng> result = <LatLng>[];
    for (int i = 0; i < points.length; i++) {
      if (i % 2 != 0) {
        result.add(LatLng(points[i - 1], points[i]));
      }
    }
    return result;
  }

  void onMarkerTapped(LatLng destinationPosition, LatLng currentPosition,
      BuildContext context, GoogleMapController? mapController) async {
    LatLng current = destinationPosition;
    LatLng destination = currentPosition;
    dynamic points = await _getRoute(current, destination);

    mapController!.animateCamera(CameraUpdate.newLatLngZoom(destination, 15));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 500,
        child: GoogleMap(
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>[
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          ].toSet(),
          onMapCreated: (GoogleMapController controller) {
            mapController = controller;
            controller.showMarkerInfoWindow(MarkerId('Desitnation'));
          },
          initialCameraPosition: CameraPosition(
            target: current,
            zoom: 15.0,
          ),
          polylines: {
            Polyline(
              polylineId: PolylineId('route'),
              points: _convertToLatLng(_decodePoly(points)),
              width: 4,
              color: Colors.blue,
            ),
          },
          markers: {
            Marker(
              markerId: MarkerId("Desitnation"),
              position: destination,
              infoWindow: InfoWindow(title: "Order number here"),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed),
            ),
            Marker(
              markerId: MarkerId('Source'),
              position: current,
              infoWindow: InfoWindow(title: "Source"),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue),
            ),
          },
        ),
      ),
    );
  }

  Future<String> _getRoute(LatLng l1, LatLng l2) async {
    String polyPoints;

    String APIKEY = dotenv.env[Constants.googleMapsApiKey] ?? "";
    String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${l1.latitude},${l1.longitude}&destination=${l2.latitude},${l2.longitude}&key=$APIKEY";
    http.Response response = await http.get(Uri.parse(url));

    Map values = jsonDecode(response.body);

    polyPoints = values["routes"].isNotEmpty
        ? values["routes"][0]["overview_polyline"]["points"]
        : "";

    return polyPoints;
  }
}
