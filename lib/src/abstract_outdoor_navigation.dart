import 'package:latlong2/latlong.dart';

abstract class OutdoorNavigation {
  Future<LatLng?> getLocation();
}
