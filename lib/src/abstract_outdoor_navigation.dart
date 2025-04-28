import 'model/location.dart';

abstract class OutdoorNavigation {
  Future<HHNLocation> getLocation();
}
