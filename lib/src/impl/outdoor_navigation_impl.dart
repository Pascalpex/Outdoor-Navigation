import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:outdoor_navigation/src/abstract_outdoor_navigation.dart';

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
}
