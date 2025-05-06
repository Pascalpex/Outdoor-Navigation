import 'package:outdoor_navigation/src/abstract_outdoor_navigation.dart';
import 'package:outdoor_navigation/src/impl/outdoor_navigation_impl.dart';

/// The OutdoorNavigationProvider provides a static method for getting an implementation of OutdoorNavigation.
///
/// See the getOutdoorNavigation Method of this class.
class OutdoorNavigationProvider {
  /// Returns an implementation of OutdoorNavigation.
  static OutdoorNavigation getOutdoorNavigation() {
    return OutdoorNavigationImpl();
  }
}
