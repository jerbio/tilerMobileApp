// import 'package:flutter/material.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'dart:ui' as ui;
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import 'package:tiler_app/routes/authenticatedUser/forecast/helperClass.dart';
// import 'googleMapSingleRoute.dart';

// /// This widget helps us to draw multiple polylines on the google map
// class WidgetGoogleMap extends StatefulWidget {
//   @override
//   _WidgetGoogleMapState createState() => _WidgetGoogleMapState();
// }

// class _WidgetGoogleMapState extends State<WidgetGoogleMap> {
//   Set<Marker> markers = {};

//   LatLng? source;

//   Map<PolylineId, Polyline> polyLines = <PolylineId, Polyline>{};

//   int polyLineIdCounter = 1;

//   GoogleMapController? mapController;

//   @override
//   void initState() {
//     super.initState();
//     _determinePosition().then((value) {
//       setState(() {
//         source = LatLng(value.latitude, value.longitude);
//       });
//       sendRequest();
//     });
//   }

//   List<LatLng> listLocations = [];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         body: source == null
//             ? const Center(
//                 child: CircularProgressIndicator(),
//               )
//             : GoogleMap(
//                 polylines: Set<Polyline>.of(polyLines.values),
//                 markers: markers,
//                 onMapCreated: (c) {
//                   mapController = c;
//                 },
//                 myLocationEnabled: true,
//                 initialCameraPosition: CameraPosition(
//                   target: source!,
//                   zoom: 14.0,
//                 ),
//                 mapType: MapType.normal,
//               ));
//   }

//   void sendRequest() {
//     getMultiplePolyLines();
//     addMarker();
//   }

//   _handlePolylineTap(PolylineId polylineId, LatLng finish) {
//     setState(() {
//       Polyline newPolyline =
//           polyLines[polylineId]!.copyWith(colorParam: Colors.blue);

//       polyLines[polylineId] = newPolyline;
//     });

//     Navigator.push(
//         context,
//         MaterialPageRoute(
//             builder: (_) => GoogleMapSingleRoute(
//                   currentLocation: source!,
//                   polylineCoordinates: polyLines[polylineId]!.points,
//                   destinationLocation: finish,
//                 ))).then((value) {
//       polyLines.forEach((key, value) {
//         if (value.color == Colors.blue) {
//           Polyline newPolyline =
//               polyLines[value.polylineId]!.copyWith(colorParam: Colors.red);

//           polyLines[polylineId] = newPolyline;
//         }
//         setState(() {});
//       });
//     });
//   }

//   // here we simply assign the bytes which we get from the icon common method to the marker
//   Future<void> addMarker() async {
//     markers.add(Marker(
//         markerId: MarkerId(source.toString()),
//         position: source!,
//         icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)));
//     listLocations.forEach((element) {
//       markers.add(Marker(
//           markerId: MarkerId(element.toString()),
//           position: element,
//           onTap: () {
//             HelperClass()
//                 .onMarkerTapped(source!, element, context, mapController);
//           }));
//     });
//   }

//   getMultiplePolyLines() async {
//     await Future.forEach(listLocations, (LatLng elem) async {
//       await _getRoutePolyline(
//         start: source!,
//         finish: elem,
//         color: Colors.green,
//         id: 'firstPolyline $elem',
//         width: 4,
//       );
//     });

//     setState(() {});
//   }

//   Future<Polyline> _getRoutePolyline(
//       {required LatLng start,
//       required LatLng finish,
//       required Color color,
//       required String id,
//       int width = 6}) async {
//     // Generates every polyline between start and finish
//     final polylinePoints = PolylinePoints();
//     // Holds each polyline coordinate as Lat and Lng pairs
//     final List<LatLng> polylineCoordinates = [];

//     final startPoint = PointLatLng(start.latitude, start.longitude);
//     final finishPoint = PointLatLng(finish.latitude, finish.longitude);

//     final result = await polylinePoints.getRouteBetweenCoordinates(
//       APIKEY,
//       startPoint,
//       finishPoint,
//     );

//     if (result.points.isNotEmpty) {
//       // loop through all PointLatLng points and convert them
//       // to a list of LatLng, required by the Polyline
//       result.points.forEach((PointLatLng point) {
//         polylineCoordinates.add(
//           LatLng(point.latitude, point.longitude),
//         );
//       });
//     }

//     polyLineIdCounter++;

//     final Polyline polyline = Polyline(
//         polylineId: PolylineId(id),
//         consumeTapEvents: true,
//         points: polylineCoordinates,
//         color: Colors.red,
//         width: 4,
//         onTap: () {
//           _handlePolylineTap(
//               PolylineId(
//                 id,
//               ),
//               finish); // function that will handle the color change and will be triggered when the polyline was tapped
//         });

//     setState(() {
//       polyLines[PolylineId(id)] = polyline;
//     });

//     return polyline;
//   }
// }

// String APIKEY = "AIzaSyC05Am_he9ZlvzseciQYN65WDnIMxRE138";

// Future<Position> _determinePosition() async {
//   bool serviceEnabled;
//   LocationPermission permission;
//   serviceEnabled = await Geolocator.isLocationServiceEnabled();
//   if (!serviceEnabled) {
//     permission = await Geolocator.requestPermission();

//     return Future.error('Location services are disabled.');
//   }

//   permission = await Geolocator.checkPermission();
//   if (permission == LocationPermission.denied) {
//     permission = await Geolocator.requestPermission();
//     if (permission == LocationPermission.denied) {
//       return Future.error('Location permissions are denied');
//     }
//   }

//   if (permission == LocationPermission.deniedForever) {
//     return Future.error(
//         'Location permissions are permanently denied, we cannot request permissions.');
//   }

//   return await Geolocator.getCurrentPosition();
// }
