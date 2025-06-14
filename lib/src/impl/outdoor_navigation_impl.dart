import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:outdoor_navigation/outdoor_navigation.dart';
import 'package:outdoor_navigation/src/abstract_outdoor_navigation.dart';
import 'package:outdoor_navigation/src/gnss_plugin.dart';
import 'package:outdoor_navigation/src/model/gnss_satelite.dart';

class OutdoorNavigationImpl implements OutdoorNavigation {
  @override
  Future<LatLng?> getLocation() async {
    Location location = Location();

    LocationData locationData = await location.getLocation();
    if (locationData.latitude != null && locationData.longitude != null) {
      return LatLng(locationData.latitude!, locationData.longitude!);
    } else {
      return null;
    }
  }

  @override
  Stream<List<GnssSatelite>> getGnssStream() {
    return GnssPlugin.gnssStream;
  }

  @override
  Stream<NmeaMessage> getNmeaStream() {
    return GnssPlugin.nmeaStream;
  }

  @override
  Future<void> startRTKServer() {
    final RtklibBindings rtklibBindings = RtklibBindings();
    rtklibBindings.startServer();
    return Future.value();
  }
}
