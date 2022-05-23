import 'package:flutter/material.dart';
import 'dart:async';
import 'package:location/location.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mapbox_navigation/library.dart';
import 'package:latlong2/latlong.dart';

void main()=> runApp(MyApp());


class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _instruction = "";

  late MapBoxNavigation _directions;
  late MapBoxOptions _options;

  bool _isMultipleStop = false;
  late double _distanceRemaining, _durationRemaining;
  late MapBoxNavigationViewController _controller;
  bool _routeBuilt = false;
  bool _isNavigating = false;
  var wayPoints = <WayPoint>[];
  late LatLng currentLocation;

  @override
  void initState() {
    super.initState();
    initializeLocationAndSave().whenComplete(() => initialize());
  }

  Future<void> initializeLocationAndSave() async {
    // Ensure all permissions are collected for Locations
    Location _location = Location();
    bool? _serviceEnabled;
    PermissionStatus? _permissionGranted;

    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
    }

    // Get the current user location
    LocationData _locationData = await _location.getLocation();
    currentLocation =
        LatLng(_locationData.latitude!, _locationData.longitude!);
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initialize() async {
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    _directions = MapBoxNavigation(onRouteEvent: _onEmbeddedRouteEvent);
    _options = MapBoxOptions(
        initialLatitude: 36.1175275,
        initialLongitude: -115.1839524,
        zoom: 20.0,
        tilt: 0.0,
        bearing: 0.0,
        enableRefresh: false,
        alternatives: true,
        voiceInstructionsEnabled: true,
        simulateRoute: false,
        bannerInstructionsEnabled: true,
        allowsUTurnAtWayPoints: true,
        mode: MapBoxNavigationMode.drivingWithTraffic,
        units: VoiceUnits.imperial,
        animateBuildRoute: true,
        longPressDestinationEnabled: true,
        language: "zh-tw");

    final _currentlocation = WayPoint(
        name: "Way Point 1",
        latitude: currentLocation.latitude,
        longitude: currentLocation.longitude);

    final _destination = WayPoint(
        name: "destination",
        latitude: 22.73229737694524,
        longitude: 120.28648576146473);

    wayPoints.add(_currentlocation);
    wayPoints.add(_destination);

    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await _directions.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    setState(() {
    });


    // Start the trip
    await _directions.startNavigation(wayPoints: wayPoints, options: _options);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
        ),
      ),
    );
  }

  Future<void> _onEmbeddedRouteEvent(e) async {
    _distanceRemaining = await _directions.distanceRemaining;
    _durationRemaining = await _directions.durationRemaining;

    switch (e.eventType) {
      case MapBoxEvent.progress_change:
        var progressEvent = e.data as RouteProgressEvent;
        if (progressEvent.currentStepInstruction != null)
          _instruction = progressEvent.currentStepInstruction!;
        break;
      case MapBoxEvent.route_building:
      case MapBoxEvent.route_built:
        setState(() {
          _routeBuilt = true;
        });
        break;
      case MapBoxEvent.route_build_failed:
        setState(() {
          _routeBuilt = false;
        });
        break;
      case MapBoxEvent.navigation_running:
        setState(() {
          _isNavigating = true;
        });
        break;
      case MapBoxEvent.on_arrival:
        if (!_isMultipleStop) {
          await Future.delayed(Duration(seconds: 3));
          await _controller.finishNavigation();
        } else {}
        break;
      case MapBoxEvent.navigation_finished:
      case MapBoxEvent.navigation_cancelled:
        setState(() {
          _routeBuilt = false;
          _isNavigating = false;
        });
        break;
      default:
        break;
    }
    setState(() {});
  }
}