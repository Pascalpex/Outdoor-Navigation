// rtklib_bindings.dart
import 'dart:ffi' as ffi;
import 'dart:io' show Platform;

import 'package:ffi/ffi.dart' as pffi;

typedef VoidExampleNativ = ffi.Void Function();
typedef IntExampleNativ = ffi.Int32 Function();

typedef VoidExampleDart = void Function();
typedef IntExampleDart = int Function();

// Native function signature
typedef StopServerNativ = ffi.Void Function();
typedef InitServerNativ = ffi.Int Function();
typedef StartServerNativ = ffi.Int Function();

// Dart function signature
typedef StopServerDart = void Function();
typedef InitServerDart = int Function();
typedef StartServerDart = int Function();

class RtklibBindings {
  late final StopServerDart _stopServer;
  late final InitServerDart _initServer;
  late final StartServerDart _startServer;

  late final ffi.DynamicLibrary _dylib;
  late final VoidExampleDart _exampleVoid;
  late final IntExampleDart _exampleInt;

  RtklibBindings({String? libraryPath}) {
    _dylib = ffi.DynamicLibrary.open(_getLibraryPath());

    _exampleVoid = _dylib.lookup<ffi.NativeFunction<VoidExampleNativ>>('example_void').asFunction<VoidExampleDart>();
    _exampleInt = _dylib.lookup<ffi.NativeFunction<IntExampleNativ>>('example_int').asFunction<IntExampleDart>();

    _exampleVoid();
    _exampleInt();

    _stopServer = _dylib.lookup<ffi.NativeFunction<StopServerNativ>>('stop_rtk_server').asFunction<StopServerDart>();
    _initServer = _dylib.lookup<ffi.NativeFunction<InitServerNativ>>('init_rtk_server').asFunction<InitServerDart>();
    _startServer = _dylib.lookup<ffi.NativeFunction<StartServerNativ>>('start_rtk_server').asFunction<StartServerDart>();
  }

  static String _getLibraryPath() {
    if (Platform.isMacOS) return 'libgnss_rtklib.dylib';
    if (Platform.isWindows) return 'gnss_rtklib.dll';
    // Assume Linux or other Unix-like for the .so extension
    return 'libgnss_rtklib.so';
  }

  void stopServer() {
    _stopServer();
    print("server stopped");
  }

  void initServer() {
    print(_initServer());
    print("server initialized");
  }

  void startServer() {
    _initServer();
    _startServer();
  }
}
