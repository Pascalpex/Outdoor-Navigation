# Example: Outdoor Navigation Usage

This example Flutter app demonstrates how to use the [`outdoor_navigation`](/lib/outdoor_navigation.dart) package to access the user's current location.

## Usage

To get the latest position, simply call the `getLocation()` function from an instance of `OutdoorNavigation`:

```dart
import 'package:outdoor_navigation/outdoor_navigation.dart';

final outdoorNavigation = OutdoorNavigationProvider.getOutdoorNavigation();
final position = await outdoorNavigation.getLocation();
```

The package handles all background location updates and calculations for you. You only need to call `getLocation()` whenever you want the most recent and best available position.

## Important Notes & Limitations

- The navigation service runs in the background and constantly updates the position. To save resources, keep your usage minimal and only request location updates when needed.
- Always call `dispose()` on your `OutdoorNavigation` instance when finished to stop the service and free resources.
- The latest position is only returned when you call `getLocation()`, even though it is updated in the background.
- For the best possible position (e.g., RTK corrections), you currently need to modify the library to provide a start position, Ntrip client, ephemeris and correction data, and any required login credentials. This process may be simplified in future updates.

## Example

See [`lib/main.dart`](lib/main.dart) for a complete usage example.