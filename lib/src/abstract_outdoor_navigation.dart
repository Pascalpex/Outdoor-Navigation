import 'package:latlong2/latlong.dart';

/// The OutdoorNavigation class provides all outdoor related location services.
///
/// To obtain an instance use OutdoorNavigationProvider#getOutdoorNavigation.
abstract class OutdoorNavigation {
  /// Gives the latitude and longitude coordinates of the user.
  ///
  /// Will ask for permission on first usage.
  Future<LatLng?> getLocation();
}
