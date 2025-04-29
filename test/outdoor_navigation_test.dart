import 'package:outdoor_navigation/outdoor_navigation.dart';
import 'package:test/test.dart';

void main() {
  group('Test group', () {
    OutdoorNavigation? outdoorNavigation;
    setUp(() {
      outdoorNavigation = OutdoorNavigationProvider.getOutdoorNavigation();
    });

    test('Provider Test', () {
      expect(outdoorNavigation, isNotNull);
    });

    tearDown(() {
      outdoorNavigation = null;
    });
  });
}
