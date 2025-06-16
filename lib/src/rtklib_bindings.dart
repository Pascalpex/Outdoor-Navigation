// rtklib_bindings.dart
import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io' show Platform;

import 'package:ffi/ffi.dart';
import 'package:outdoor_navigation/src/gnss_plugin.dart';

const int maxStrmsg = 1024;
const int ntripDataPeekSize = 128;

final class RtkNtripDebugInfoStruct extends ffi.Struct {
  @ffi.Int32()
  external int stream_state;

  // For char arrays, we use an Array of Uint8
  // This requires a bit of care when accessing as a String.
  @ffi.Array(maxStrmsg) // Size of the array
  external ffi.Array<ffi.Uint8> _stream_msg_bytes;

  @ffi.Int32()
  external int bytes_in_server_buffer;

  @ffi.Int32()
  external int bytes_peeked;

  @ffi.Array(ntripDataPeekSize)
  external ffi.Array<ffi.Uint8> _data_peek_buffer_bytes;

  @ffi.Int32()
  external int rtk_server_state;

  // Helper to get stream_msg as a Dart String
  String get stream_msg {
    final List<int> charCodes = [];
    for (int i = 0; i < maxStrmsg; i++) {
      if (_stream_msg_bytes[i] == 0) break; // Null terminator
      charCodes.add(_stream_msg_bytes[i]);
    }
    return String.fromCharCodes(charCodes);
  }

  // Helper to get data_peek_buffer as a List<int> (Uint8List)
  List<int> get data_peek_buffer {
    final List<int> data = [];
    for (int i = 0; i < bytes_peeked; i++) {
      // Only read up to bytes_peeked
      data.add(_data_peek_buffer_bytes[i]);
    }
    return data;
  }
}

// Signature of the C function: void get_rtk_ntrip_debug_info(RtkNtripDebugInfo* debug_info);
typedef GetRtkNtripDebugInfoNative = ffi.Void Function(ffi.Pointer<RtkNtripDebugInfoStruct> debugInfo);
// Signature of the Dart function
typedef GetRtkNtripDebugInfoDart = void Function(ffi.Pointer<RtkNtripDebugInfoStruct> debugInfo);

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
  late final GetRtkNtripDebugInfoDart _getRtkNtripDebugInfo;
  Timer? _debugPollingTimer;

  late final ffi.DynamicLibrary _dylib;

  RtklibBindings({String? libraryPath}) {
    _dylib = ffi.DynamicLibrary.open(_getLibraryPath());

    _stopServer = _dylib.lookup<ffi.NativeFunction<StopServerNativ>>('stop_rtk_server').asFunction<StopServerDart>();
    _initServer = _dylib.lookup<ffi.NativeFunction<InitServerNativ>>('init_rtk_server').asFunction<InitServerDart>();
    _startServer = _dylib.lookup<ffi.NativeFunction<StartServerNativ>>('start_rtk_server').asFunction<StartServerDart>();
    _getRtkNtripDebugInfo = _dylib.lookup<ffi.NativeFunction<GetRtkNtripDebugInfoNative>>('get_rtk_ntrip_debug_info').asFunction<GetRtkNtripDebugInfoDart>();
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
    final int result = _startServer();
    if (result == 0) {
      print("Failed to start RTK Server via FFI. Result: $result");
      return;
    }
    print("RTK Server started successfully via FFI.");
    ffi.Pointer<RtkNtripDebugInfoStruct>? _debugInfoPointer = calloc<RtkNtripDebugInfoStruct>();
    _debugPollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      print("Timer tick: ${timer.tick}");
      if (_debugInfoPointer == null) return;

      // Call the C function, passing the pointer to our allocated struct
      _getRtkNtripDebugInfo(_debugInfoPointer!);

      // Access the fields from the struct pointed to by _debugInfoPointer
      // The .ref property dereferences the pointer to get the struct instance
      final RtkNtripDebugInfoStruct info = _debugInfoPointer!.ref;

      print("--- RTK Debug Poll ---");
      print("RTK Server State: ${info.rtk_server_state}");
      print("NTRIP Stream State: ${info.stream_state}");
      print("NTRIP Stream Msg: '${info.stream_msg}'"); // Uses the getter
      print("NTRIP Bytes in Svr Buffer: ${info.bytes_in_server_buffer}");

      if (info.bytes_peeked > 0) {
        final List<int> dataBytes = info.data_peek_buffer; // Uses the getter
        String hexString = "";
        for (int byteVal in dataBytes) {
          hexString += "${byteVal.toRadixString(16).padLeft(2, '0').toUpperCase()} ";
        }
        print("NTRIP Data Peek (${info.bytes_peeked} bytes): $hexString");
      } else if (info.stream_state == 1 /* OPEN */ && info.bytes_in_server_buffer == 0) {
        print("NTRIP stream open, but no data in server buffer yet.");
      }
      print("----------------------");

      if (info.rtk_server_state == 0) {
        print("RTK Server has stopped. Stopping debug poll.");
        _debugPollingTimer?.cancel();
        _debugPollingTimer = null;
        if (_debugInfoPointer != null) {
          calloc.free(_debugInfoPointer!);
          _debugInfoPointer = null;
        }
        print("RTK debug polling stopped.");
      }
    });
  }
}
