import 'dart:async';

import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:outdoor_navigation/outdoor_navigation.dart';
import 'package:outdoor_navigation/src/abstract_outdoor_navigation.dart';
import 'package:outdoor_navigation/src/gnss_plugin.dart';
import 'package:outdoor_navigation/src/model/gnss_satelite.dart';
import 'package:outdoor_navigation/src/model/nmea_message.dart';
import 'package:outdoor_navigation/src/rtklib_bindings.dart';

class OutdoorNavigationImpl implements OutdoorNavigation {
  late final RtklibBindings _bindings;
  late final Location _location;

  bool _isRtkStarted = false;
  LatLng? _latestRtkSolution;

  StreamSubscription? _rawMeasurementsSubscription;

  Timer? _solutionPollingTimer;

  final _rtkSolutionController = StreamController<String>.broadcast();

  OutdoorNavigationImpl() {
    _bindings = RtklibBindings();
    _location = Location();
  }

  Future<void> _startRtkProcess() async {
    if (_isRtkStarted) return;

    _bindings.initServer();
    _bindings.startServer();

    _rawMeasurementsSubscription = GnssPlugin.rawMeasurmentStream.listen((Map<String, dynamic> rawData) {
      _bindings.processGnssData(rawData);
    }, onError: (e) => print("RTK Raw Measurements Stream Error: $e"));

    _solutionPollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final solutionMap = _bindings.getLatestSolution();
      if (solutionMap != null) {
        final status = solutionMap['status'] as int?;
        if (status == 1 || status == 2) {
          final lat = solutionMap['latitude'] as double?;
          final lon = solutionMap['longitude'] as double?;
          if (lat != null && lon != null) {
            _latestRtkSolution = LatLng(lat, lon);
          }
        } else {
          _latestRtkSolution = null;
        }
      }
    });
    _isRtkStarted = true;
  }

  @override
  Future<LatLng?> getLocation() async {
    if (!_isRtkStarted) {
      _startRtkProcess();
    }
    if (_latestRtkSolution != null) {
      return _latestRtkSolution;
    }

    LocationData locationData = await _location.getLocation();
    if (locationData.latitude != null && locationData.longitude != null) {
      return LatLng(locationData.latitude!, locationData.longitude!);
    } else {
      return null;
    }
  }

  @override
  void dispose() {
    _rawMeasurementsSubscription?.cancel();
    _solutionPollingTimer?.cancel();
    _rawMeasurementsSubscription = null;
    _solutionPollingTimer = null;
    _isRtkStarted = false;
    _bindings.stopServer();
    _bindings.dispose();
  }

  @override
  void showLogs() {
    _bindings.printServerStatus();
  }
}
