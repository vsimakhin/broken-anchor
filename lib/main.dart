import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';

import 'package:broken_anchor/helpers.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const String _title = 'Broken Anchor';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const Anchor(),
    );
  }
}

class Anchor extends StatefulWidget {
  const Anchor({super.key});

  @override
  State<Anchor> createState() => _AnchorState();
}

class _AnchorState extends State<Anchor> {
  bool servicestatus = false;
  bool haspermission = false;
  late LocationPermission permission;

  double _distance = 0;
  String _status = '';
  bool _isTracking = false;
  double _targetDistance = 100;

  Position _boat = Position(
    longitude: 0,
    latitude: 0,
    timestamp: DateTime.now(),
    accuracy: 0,
    altitude: 0,
    heading: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  Position _anchor = Position(
    longitude: 0,
    latitude: 0,
    timestamp: DateTime.now(),
    accuracy: 0,
    altitude: 0,
    heading: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  // map
  GeoPoint _anchorPoint = GeoPoint(latitude: 0, longitude: 0);
  final MarkerIcon _anchorMarker = MarkerIcon(assetMarker: AssetMarker(image: const AssetImage('icons/anchor.png')));

  GeoPoint _boatPoint = GeoPoint(latitude: 0, longitude: 0);
  final MarkerIcon _boatMarker = MarkerIcon(assetMarker: AssetMarker(image: const AssetImage('icons/boat.png')));

  @override
  void initState() {
    checkGps();
    super.initState();
  }

  Future<void> _drawDistanceCircle() async {
    await _map.removeCircle("_target_distance");

    if (_isTracking) {
      await _map.drawCircle(CircleOSM(
        key: "_target_distance",
        centerPoint: _anchorPoint,
        radius: _targetDistance,
        color: Colors.green,
        strokeWidth: 0.3,
      ));
    }
  }

  Future<void> _drawBoatAccuracyCircle() async {
    await _map.removeCircle("_boat_accuracy");

    await _map.drawCircle(CircleOSM(
      key: "_boat_accuracy",
      centerPoint: _boatPoint,
      radius: _boat.accuracy,
      color: Colors.blueGrey,
      strokeWidth: 0.3,
    ));
  }

  checkGps() async {
    servicestatus = await Geolocator.isLocationServiceEnabled();
    if (servicestatus) {
      permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _status = 'Location permissions are denied';
        } else if (permission == LocationPermission.deniedForever) {
          _status = 'Location permissions are permanently denied';
        } else {
          haspermission = true;
        }
      } else {
        haspermission = true;
      }

      if (haspermission) {
        _status = 'GPS is enabled';
        setState(() {});
        getLocation();
      }
    } else {
      _status = "GPS Service is not enabled, turn on GPS location";
    }

    setState(() {});
  }

  getLocation() async {
    _boat = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(() {});

    LocationSettings locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.best, //accuracy of the location data
      // distanceFilter: 1, //minimum distance (measured in meters) a
      //device must move horizontally before an update event is generated;
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText: "Broken Anchor will continue to receive your location",
        notificationTitle: "Running in Background",
        enableWakeLock: true,
      ),
    );

    StreamSubscription<Position> positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      if (_isTracking) {
        _distance = Geolocator.distanceBetween(_anchor.latitude, _anchor.longitude, _boat.latitude, _boat.longitude);
      }

      _boat = position;

      final _boatOldPoint = _boatPoint;
      _boatPoint = GeoPoint(latitude: _boat.latitude, longitude: _boat.longitude);
      _map.changeLocationMarker(oldLocation: _boatOldPoint, newLocation: _boatPoint);
      _drawBoatAccuracyCircle();

      setState(() {});
    });
  }

  void onAnchorTap() async {
    _isTracking = !_isTracking;

    if (_isTracking) {
      _status = "Tracking anchor";
      _anchor = _boat;

      // map
      // _map.enableTracking(enableStopFollow: true);

      // anchor
      _anchorPoint = GeoPoint(latitude: _anchor.latitude, longitude: _anchor.longitude);
      await _map.addMarker(_anchorPoint, markerIcon: _anchorMarker);

      await _map.drawCircle(CircleOSM(
        key: "_anchor_accuracy",
        centerPoint: _anchorPoint,
        radius: _anchor.accuracy,
        color: Colors.blueGrey,
        strokeWidth: 0.3,
      ));

      await _drawDistanceCircle();
      setState(() {});
    } else {
      // map
      await _map.removeMarker(_anchorPoint);
      await _map.removeCircle("_anchor_accuracy");
      await _drawDistanceCircle();

      checkGps();
      _anchor = Position(
        longitude: 0,
        latitude: 0,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      _distance = 0;
      // _map.disabledTracking();
    }
  }

  MapController _map = MapController(initMapWithUserPosition: true);

  @override
  Widget build(BuildContext context) {
    final iconColor = getIconColor(_isTracking);
    return Scaffold(
      appBar: AppBar(title: const Text('Broken Anchor')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  height: 250,
                  width: constraints.maxWidth,
                  child: Card(
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: OSMFlutter(
                        onMapIsReady: (value) async {
                          if (value) {
                            await _map.addMarker(_boatPoint, markerIcon: _boatMarker);
                          }
                        },
                        controller: _map,
                        trackMyPosition: false,
                        initZoom: 18,
                        minZoomLevel: 2,
                        maxZoomLevel: 19,
                        stepZoom: 1.0,
                        markerOption: MarkerOption(defaultMarker: _boatMarker),
                      ),
                    ),
                  ),
                ),
                // Anchor
                Card(
                  elevation: 5,
                  child: ListTile(
                    onTap: onAnchorTap,
                    leading: Icon(Icons.anchor, color: iconColor),
                    title: const Text('Anchor coordinates'),
                    subtitle: Column(
                      children: [
                        Row(
                          children: [
                            const Text('Latitude:'),
                            const SizedBox(width: 10),
                            Text(_anchor.latitude.toString()),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('Longtitude:'),
                            const SizedBox(width: 10),
                            Text(_anchor.longitude.toString()),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('Accuracy:'),
                            const SizedBox(width: 10),
                            Text(fmtAccuracy(_anchor.accuracy)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Boat
                Card(
                  elevation: 5,
                  child: ListTile(
                    leading: Icon(Icons.sailing, color: iconColor),
                    title: const Text('Boat'),
                    subtitle: Column(
                      children: [
                        Row(
                          children: [
                            const Text('Latitude:'),
                            const SizedBox(width: 10),
                            Text(_boat.latitude.toString())
                          ],
                        ),
                        Row(
                          children: [
                            const Text('Longtitude:'),
                            const SizedBox(width: 10),
                            Text(_boat.longitude.toString())
                          ],
                        ),
                        Row(
                          children: [
                            const Text('Accuracy:'),
                            const SizedBox(width: 10),
                            Text(fmtAccuracy(_boat.accuracy))
                          ],
                        ),
                        Row(
                          children: [const Text('Speed:'), const SizedBox(width: 10), Text(fmtSpeed(_boat.speed))],
                        ),
                        Row(
                          children: [
                            const Text('Heading:'),
                            const SizedBox(width: 10),
                            Text(fmtHeading(_boat.heading))
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                // Distance card
                Card(
                  elevation: 5,
                  child: ListTile(
                    leading: Icon(Icons.square_foot, color: iconColor),
                    title: Row(
                        children: [const Text('Distance:'), const SizedBox(width: 10), Text(fmtDistance(_distance))]),
                    subtitle: Row(
                      children: [
                        Text('Target: ${_targetDistance.toStringAsFixed(0)} m'),
                        Expanded(
                          child: Slider(
                            value: _targetDistance,
                            max: 150,
                            divisions: 150,
                            label: _targetDistance.toStringAsFixed(0),
                            onChanged: (double value) {
                              setState(() {
                                _targetDistance = value;
                              });
                              _drawDistanceCircle();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Status
                Card(
                  elevation: 5,
                  child: ListTile(
                    leading: Icon(Icons.satellite_alt, color: iconColor),
                    title: const Row(children: [Text('Status')]),
                    subtitle: Row(children: [Text(_status)]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
