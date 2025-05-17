// rtklib_bindings.dart
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart' as pffi;
import 'dart:io' show Platform;

// Native function signature
typedef StopServerNativ = ffi.Void Function();

// Dart function signature
typedef StopServerDart = void Function();

class RtklibBindings {
  late final ffi.DynamicLibrary _dylib;
  late final StopServerDart _stopServer;

  RtklibBindings({String? libraryPath}) {
    _dylib = ffi.DynamicLibrary.open(libraryPath ?? _getLibraryPath());

    _stopServer = _dylib.lookup<ffi.NativeFunction<StopServerNativ>>('stop_rtk_server').asFunction<StopServerDart>();
  }

  static String _getLibraryPath() {
    if (Platform.isMacOS) return 'libgnss_rtklib.dylib';
    if (Platform.isWindows) return 'gnss_rtklib.dll';
    // Assume Linux or other Unix-like for the .so extension
    return 'libgnss_rtklib.so';
  }

  void stopServer() {
    print("stoping");
    _stopServer();
    print("stopped");
  }
}
