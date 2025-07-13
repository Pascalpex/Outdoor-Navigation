import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart'; // We'll need this for the location type
import 'package:outdoor_navigation/outdoor_navigation.dart'; // Your main package import

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late OutdoorNavigation outdoorNavigation;
  Timer? _locationPollingTimer;

  LatLng? _currentLocation;
  String _locationStatus = 'Press "Start Polling" to get location.';
  bool _isPolling = false;
  bool _isDisposed = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _locationPollingTimer?.cancel();
    if (!_isDisposed) {
      (outdoorNavigation as dynamic).dispose();
    }
    super.dispose();
  }

  void _initializeNavigationService() {
    if (_isDisposed) {
      outdoorNavigation = OutdoorNavigationProvider.getOutdoorNavigation();
      _isDisposed = false;
    }
  }

  void _startLocationPolling() {
    if (_isPolling) return;

    _initializeNavigationService();
    _fetchLocation();
    _locationPollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchLocation();
    });

    setState(() {
      _isPolling = true;
      _locationStatus = 'Polling for location...';
    });
  }

  void _stopLocationPolling() {
    _locationPollingTimer?.cancel();
    setState(() {
      _isPolling = false;
      _locationStatus = 'Polling stopped. RTK service is still active.';
    });
  }

  void _stopAndCleanup() {
    if (_isDisposed) return;

    _locationPollingTimer?.cancel();
    (outdoorNavigation as dynamic).dispose();

    setState(() {
      _isPolling = false;
      _isDisposed = true;
      _currentLocation = null;
      _locationStatus = 'All services stopped and cleaned up.';
    });
  }

  Future<void> _fetchLocation() async {
    if (_isDisposed) return;

    final location = await outdoorNavigation.getLocation();
    if (mounted) {
      setState(() {
        _currentLocation = location;
        if (location == null) {
          _locationStatus = 'Could not get location fix.';
        } else {
          _locationStatus = 'Location Updated!';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Outdoor Navigation Test")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text('Current Location:', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      if (_currentLocation != null)
                        Text(
                          'Lat: ${_currentLocation!.latitude.toStringAsFixed(8)}\nLon: ${_currentLocation!.longitude.toStringAsFixed(8)}',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 8),
                      Text(_locationStatus),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _isPolling ? null : _startLocationPolling, child: const Text('START POLLING')),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: !_isPolling ? null : _stopLocationPolling, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: const Text('STOP POLLING')),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: _isDisposed ? null : _stopAndCleanup, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('STOP & CLEANUP RTK')),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _isDisposed || !_isPolling ? null : outdoorNavigation.showLogs, child: const Text('Print Satus in LogCat')),
            ],
          ),
        ),
      ),
    );
  }
}
