import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:tiler_app/data/ForecastResponse.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/executionConstants.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/helperClass.dart';
import 'package:tiler_app/styles.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/util.dart';
import '../../../constants.dart' as Constants;

import 'googleMapSingleRoute.dart';

class DayCast extends StatefulWidget {
  PeekDay peekDay;
  DayCast(this.peekDay);
  @override
  _WidgetGoogleMapState createState() => _WidgetGoogleMapState();
}

class _WidgetGoogleMapState extends State<DayCast> {
  Set<Marker> markers = {};

  LatLng? source;

  Map<PolylineId, Polyline> polyLines = <PolylineId, Polyline>{};

  int polyLineIdCounter = 1;

  GoogleMapController? mapController;

  List<LatLng> listLocations = [];
  LatitudeAndLongitude? defaultLocation;
  double minLevel = 1;
  double maxLevel = 14;
  double zoomLevel = 14;

  @override
  void initState() {
    super.initState();
    if (this.widget.peekDay != null) {
      if (this.widget.peekDay.subEvents != null) {
        LatitudeAndLongitude? previousLocation = null;
        List<LatitudeAndLongitude> latitudeAndLongitudes = [];
        for (var eachSubEvent in this.widget.peekDay!.subEvents!) {
          if (eachSubEvent.location != null &&
              eachSubEvent.location!.isNotNullAndNotDefault &&
              eachSubEvent.location!.latitude != null &&
              eachSubEvent.location!.longitude != null) {
            LatitudeAndLongitude? currentLocation =
                eachSubEvent.location!.toLatitudeAndLongitude;
            if (currentLocation != null) {
              bool isSameLocation = false;
              if (previousLocation != null) {
                double travelDistance = LatitudeAndLongitude.distance(
                    previousLocation, currentLocation);
                if (travelDistance < sameLocationRadius) {
                  isSameLocation = true;
                }
              }

              if (!isSameLocation) {
                LatLng latLong = LatLng(eachSubEvent.location!.latitude!,
                    eachSubEvent.location!.longitude!);
                listLocations.add(latLong);
                LatitudeAndLongitude? eachLatLong =
                    eachSubEvent.location!.toLatitudeAndLongitude;
                if (eachLatLong != null) {
                  latitudeAndLongitudes.add(eachLatLong);
                }
              }
              previousLocation = currentLocation;
            }
          }
        }
        if (listLocations.isNotEmpty) {
          defaultLocation = LatitudeAndLongitude.averageLatLong(listLocations
              .map((e) => LatitudeAndLongitude(e.latitude, e.longitude))
              .toList());
        }
        updateZoomLevel(latitudeAndLongitudes);
      }
    }
    _determinePosition().then((value) {
      setState(() {
        source = LatLng(value.latitude, value.longitude);
      });
      sendRequest();
    });
  }

  updateZoomLevel(List<LatitudeAndLongitude> LatitudeAndLongitudes) {
    const double y = 14.0 + (13 / 12799);
    const double x = (-13 / 6400.0);
    if (LatitudeAndLongitudes.isNotEmpty && defaultLocation != null) {
      double maxDistance = -1;
      LatitudeAndLongitudes.forEach((eachLongLat) {
        double distance =
            LatitudeAndLongitude.distance(eachLongLat, defaultLocation!);
        if (distance > maxDistance) {
          maxDistance = distance;
        }
      });
      // maxDistance = 1200;
      if (maxDistance > 0.1) {
        double updatedZoomLevel = (y + (maxDistance * x));
        zoomLevel = updatedZoomLevel;
        if (updatedZoomLevel > maxLevel) {
          zoomLevel = maxLevel;
        }
        if (updatedZoomLevel < minLevel) {
          zoomLevel = minLevel;
        }
      }
    }
  }

  Widget renderMap() {
    return GoogleMap(
      polylines: Set<Polyline>.of(polyLines.values),
      markers: markers,
      mapToolbarEnabled: true,
      zoomControlsEnabled: true,
      zoomGesturesEnabled: true,
      onMapCreated: (c) {
        mapController = c;
      },
      myLocationEnabled: true,
      initialCameraPosition: CameraPosition(
        target: defaultLocation != null
            ? LatLng(defaultLocation!.latitude, defaultLocation!.longitude)
            : source!,
        zoom: zoomLevel,
      ),
      mapType: MapType.normal,
    );
  }

  Widget renderTiles() {
    return DayGridWidget(
      peekDay: this.widget.peekDay,
      onTileTap: onTileGridTap,
    );
  }

  void onTileGridTap({TilerEvent? tilerEvent}) {
    if (tilerEvent != null && tilerEvent.id.isNot_NullEmptyOrWhiteSpace()) {
      if (mapController != null) {
        if (tilerEvent.location?.isNotNullAndNotDefault == true) {
          LatitudeAndLongitude? latitudeAndLongitudetilerEvent =
              tilerEvent.location?.toLatitudeAndLongitude;
          if (latitudeAndLongitudetilerEvent != null) {
            mapController!.animateCamera(CameraUpdate.newLatLng(LatLng(
                latitudeAndLongitudetilerEvent.latitude,
                latitudeAndLongitudetilerEvent.longitude)));
          }
        }
      }
    }
  }

  Widget renderLandScape() {
    double padding = 20;
    double mapHeight = 250;
    double restOfWidth =
        MediaQuery.sizeOf(context).width - mapHeight - (padding * 2) - 120;
    double gridWIdth = restOfWidth;
    if (restOfWidth < 100) {
      gridWIdth = 400;
    }
    List<Widget> widgets = [
      Container(
          padding: EdgeInsets.all(padding), width: 400, child: renderMap()),
      Container(
          padding: EdgeInsets.all(padding),
          width: gridWIdth,
          child: renderTiles())
    ];
    if (restOfWidth < 100) {
      return ListView(
        scrollDirection: Axis.horizontal,
        children: widgets,
      );
    }
    return Row(
      children: widgets,
    );
  }

  Widget renderPortrait() {
    double padding = 20;
    double mapHeight = 250;
    double restOfHeight =
        MediaQuery.sizeOf(context).height - mapHeight - (padding * 2) - 65;
    double gridHeight = restOfHeight;
    double minHeight = 200;
    if (restOfHeight < minHeight) {
      gridHeight = 400;
    }
    List<Widget> widgets = [
      Container(
          padding: EdgeInsets.all(padding),
          height: mapHeight,
          child: renderMap()),
      Container(
          padding: EdgeInsets.all(padding),
          height: gridHeight,
          child: renderTiles())
    ];
    if (restOfHeight < minHeight) {
      return ListView(
        scrollDirection: Axis.vertical,
        children: widgets,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: widgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          leading: TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Icon(
              Icons.close,
              color: TileStyles.appBarTextColor,
            ),
          ),
          backgroundColor: TileStyles.appBarColor,
          title: Text(
            AppLocalizations.of(context)!.dayCast,
            style: TileStyles.titleBarStyle,
          ),
        ),
        body: source == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : MediaQuery.of(context).orientation == Orientation.portrait
                ? renderPortrait()
                : renderLandScape());
  }

  void sendRequest() {
    getMultiplePolyLines();
    addMarker();
  }

  _handlePolylineTap(PolylineId polylineId, LatLng finish) {
    setState(() {
      Polyline newPolyline =
          polyLines[polylineId]!.copyWith(colorParam: Colors.blue);

      polyLines[polylineId] = newPolyline;
    });

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => GoogleMapSingleRoute(
                  currentLocation: source!,
                  polylineCoordinates: polyLines[polylineId]!.points,
                  destinationLocation: finish,
                ))).then((value) {
      polyLines.forEach((key, value) {
        if (value.color == Colors.blue) {
          Polyline newPolyline =
              polyLines[value.polylineId]!.copyWith(colorParam: Colors.red);

          polyLines[polylineId] = newPolyline;
        }
        setState(() {});
      });
    });
  }

  // here we simply assign the bytes which we get from the icon common method to the marker
  Future<void> addMarker() async {
    markers.add(Marker(
        markerId: MarkerId(source.toString()),
        position: source!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)));
    listLocations.forEach((element) {
      markers.add(Marker(
          markerId: MarkerId(element.toString()),
          position: element,
          onTap: () {
            HelperClass()
                .onMarkerTapped(source!, element, context, mapController);
          }));
    });
  }

  getMultiplePolyLines() async {
    await Future.forEach(listLocations, (LatLng elem) async {
      await _getRoutePolyline(
        start: source!,
        finish: elem,
        color: Colors.green,
        id: 'firstPolyline $elem',
        width: 4,
      );
    });

    setState(() {});
  }

  Future<Polyline> _getRoutePolyline(
      {required LatLng start,
      required LatLng finish,
      required Color color,
      required String id,
      int width = 6}) async {
    // Generates every polyline between start and finish
    final polylinePoints = PolylinePoints();
    // Holds each polyline coordinate as Lat and Lng pairs
    final List<LatLng> polylineCoordinates = [];

    final startPoint = PointLatLng(start.latitude, start.longitude);
    final finishPoint = PointLatLng(finish.latitude, finish.longitude);
    String APIKEY = dotenv.env[Constants.googleMapsApiKey] ?? "";

    final result = await polylinePoints.getRouteBetweenCoordinates(
      APIKEY,
      startPoint,
      finishPoint,
    );

    if (result.points.isNotEmpty) {
      // loop through all PointLatLng points and convert them
      // to a list of LatLng, required by the Polyline
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(
          LatLng(point.latitude, point.longitude),
        );
      });
    }

    polyLineIdCounter++;

    final Polyline polyline = Polyline(
        polylineId: PolylineId(id),
        consumeTapEvents: true,
        points: polylineCoordinates,
        color: Colors.red,
        width: 4,
        onTap: () {
          _handlePolylineTap(
              PolylineId(
                id,
              ),
              finish); // function that will handle the color change and will be triggered when the polyline was tapped
        });

    setState(() {
      polyLines[PolylineId(id)] = polyline;
    });

    return polyline;
  }
}

// String APIKEY = "Your API Key";

Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    permission = await Geolocator.requestPermission();

    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  return await Geolocator.getCurrentPosition();
}
