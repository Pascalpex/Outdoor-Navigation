import 'package:location/location.dart';
import 'package:outdoor_navigation/src/abstract_outdoor_navigation.dart';
import 'package:outdoor_navigation/src/model/location.dart';

class OutdoorNavigationImpl implements OutdoorNavigation {
  @override
  Future<HHNLocation> getLocation() async {
    Location location = Location();

    LocationData locationData = await location.getLocation();
    if (locationData.latitude != null && locationData.longitude != null) {
      return HHNLocation(latitude: locationData.latitude!, longitude: locationData.longitude!, valid: true);
    } else {
      return HHNLocation(latitude: 0, longitude: 0, valid: false);
    }
  }
}
