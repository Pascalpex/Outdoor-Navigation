import 'package:outdoor_navigation/src/abstract_outdoor_navigation.dart';
import 'package:outdoor_navigation/src/impl/outdoor_navigation_impl.dart';

class OutdoorNavigationProvider {
  static OutdoorNavigation getOutdoorNavigation() {
    return OutdoorNavigationImpl();
  }
}
