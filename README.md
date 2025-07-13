# Outdoor Navigation

A Flutter plugin for advanced outdoor navigation and GNSS data access, including high-precision RTKLIB integration.

---

## API

### OutdoorNavigationProvider

Provides an implementation of the OutdoorNavigation interface, combining device location and RTKLIB-based high-precision positioning.

#### Methods

- `Future<LatLng?> getLocation()`
  - Returns the current position as a `LatLng` object.
  - Uses the RTKLIB solution if available; otherwise, falls back to device location.

- `void dispose()`
  - Cleans up resources, stops the RTKLIB server, and cancels streams and timers.

- `void showLogs()`
  - Prints RTKLIB server status and diagnostic information to LogCat.

#### Usage

See the [`example`](example/README.md) for practical usage.

---

### GnssPlugin (Android)

The Android `GnssPlugin` class (Kotlin) handles registration for GNSS measurement events via Android's `LocationManager` and streams raw satellite data to Flutter.

- Listens for GNSS measurements and extracts key parameters for each satellite:
  - Satellite ID (`svid`)
  - Constellation type (GPS, GLONASS, Galileo, etc.)
  - Carrier frequency
  - Signal strength (`cn0DbHz`)
  - Accumulated delta range
  - Pseudorange rate
  - Calculated pseudorange
- Emits data to Flutter via event channels.

---

### GnssPlugin (Dart)
 
Receives GNSS measurement data and NMEA messages from the Android `GnssPlugin` (Kotlin) via event channels and provides Dart streams (`gnssStream`, `nmeaStream`) for satellite measurements and NMEA messages.  
This makes native GNSS data available for Flutter applications in real time, which can then be used to call the native C functions that use RTKLIB.

---

## Native Part

RTKLIB integration is handled via native bindings and a C wrapper.  
The Dart class `RtklibBindings` manages the FFI bridge to the native RTKLIB wrapper library, allowing you to start/stop the RTK server, inject GNSS observations, and retrieve high-precision positioning solutions.

### How to Connect Native C Functions to Dart

Native functions (such as `get_rtk_solution` in `rtklib_wrapper.c`/`.h`) are exposed to Dart using FFI via the `RtklibBindings` class.

**Example: Mapping a C function to Dart**

Suppose you have the following C function in your header:

```c
// rtklib_wrapper.h
int get_rtk_solution(char *buffer, int buffer_size);
```

You declare the corresponding Dart FFI typedefs and lookups:

```dart
typedef _GetRtkSolutionNative = ffi.Int32 Function(ffi.Pointer<ffi.Uint8>, ffi.Int32);
typedef GetRtkSolutionDart = int Function(ffi.Pointer<ffi.Uint8>, int);

class RtklibBindings {
  late final GetRtkSolutionDart _getRtkSolution;

  RtklibBindings() {
    final dylib = ffi.DynamicLibrary.open(_getLibraryPath());
    _getRtkSolution = dylib
      .lookup<ffi.NativeFunction<_GetRtkSolutionNative>>('get_rtk_solution')
      .asFunction<GetRtkSolutionDart>();
  }

  // Dart method that calls the native function
  Map<String, dynamic>? getLatestSolution() {
    final int length = _getRtkSolution(_readBuffer, maxOutputBuffer);
    // ...
  }
}
```

This pattern is used for all native functions in the wrapper:  
You define the C function, declare the Dart FFI signature, look it up in the dynamic library, and then call it from Dart as a regular method.

The header file [`rtklib_wrapper.h`](lib/src/library/my_interface/rtklib_wrapper.h) defines all available native functions for use via FFI.

---

### C Wrapper Configuration

**Important:**  
When using the native wrapper (`rtklib_wrapper.c`), you must manually configure the `start_rtk_server` function to match your NTRIP credentials, mountpoints, and reference position:

```c
char *ntrip_correction_base = "...";
char *ntrip_ephemeris = "...";
double lat = ...;
double lon = ...;
double alt = ...;
```

Adjust these values to connect to your own NTRIP caster and set the correct reference location for your application.

For more details on configuration and advanced usage, refer to the RTKLIB manual and experiment with the processing options in the wrapper.

---
