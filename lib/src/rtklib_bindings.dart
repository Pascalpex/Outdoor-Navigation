import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

// FFI typedefs
typedef NtripInitFunc = Int32 Function();
typedef NtripInitDart = int Function();

typedef NtripConnectFunc = Int32 Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);
typedef NtripConnectDart = int Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>);

typedef NtripDisconnectFunc = Int32 Function(Int32);
typedef NtripDisconnectDart = int Function(int);

typedef NtripReadFunc = Int32 Function(Int32, Pointer<Uint8>, Int32);
typedef NtripReadDart = int Function(int, Pointer<Uint8>, int);

typedef NtripGetErrorFunc = Int32 Function(Pointer<Utf8>, Int32);
typedef NtripGetErrorDart = int Function(Pointer<Utf8>, int);

// RTK related typedefs
typedef RtkCreateFunc = Pointer Function();
typedef RtkCreateDart = Pointer Function();

typedef RtkDestroyFunc = Void Function(Pointer);
typedef RtkDestroyDart = void Function(Pointer);

typedef RtkInitOptionsFunc = Int32 Function(Pointer, Int32, Int32);
typedef RtkInitOptionsDart = int Function(Pointer, int, int);

typedef RtkInputObsFunc = Int32 Function(Pointer, Pointer<Uint8>, Int32, Int32);
typedef RtkInputObsDart = int Function(Pointer, Pointer<Uint8>, int, int);

typedef RtkGetSolutionFunc = Int32 Function(Pointer, Pointer<Double>, Pointer<Float>, Pointer<Int32>);
typedef RtkGetSolutionDart = int Function(Pointer, Pointer<Double>, Pointer<Float>, Pointer<Int32>);

class RtklibBindings {
  late final DynamicLibrary _lib;

  // NTRIP client bindings
  late final NtripInitDart _ntripInit;
  late final NtripConnectDart _ntripConnect;
  late final NtripDisconnectDart _ntripDisconnect;
  late final NtripReadDart _ntripRead;
  late final NtripGetErrorDart _ntripGetError;

  // RTK bindings
  late final RtkCreateDart _rtkCreate;
  late final RtkDestroyDart _rtkDestroy;
  late final RtkInitOptionsDart _rtkInitOptions;
  late final RtkInputObsDart _rtkInputObs;
  late final RtkGetSolutionDart _rtkGetSolution;

  RtklibBindings() {
    _lib = DynamicLibrary.open('librtklib_wrapper.so');

    // Load NTRIP functions
    _ntripInit = _lib.lookupFunction<NtripInitFunc, NtripInitDart>('ntrip_init');
    _ntripConnect = _lib.lookupFunction<NtripConnectFunc, NtripConnectDart>('ntrip_connect');
    _ntripDisconnect = _lib.lookupFunction<NtripDisconnectFunc, NtripDisconnectDart>('ntrip_disconnect');
    _ntripRead = _lib.lookupFunction<NtripReadFunc, NtripReadDart>('ntrip_read');
    _ntripGetError = _lib.lookupFunction<NtripGetErrorFunc, NtripGetErrorDart>('ntrip_get_error');

    // Load RTK functions
    _rtkCreate = _lib.lookupFunction<RtkCreateFunc, RtkCreateDart>('rtk_create');
    _rtkDestroy = _lib.lookupFunction<RtkDestroyFunc, RtkDestroyDart>('rtk_destroy');
    _rtkInitOptions = _lib.lookupFunction<RtkInitOptionsFunc, RtkInitOptionsDart>('rtk_init_options');
    _rtkInputObs = _lib.lookupFunction<RtkInputObsFunc, RtkInputObsDart>('rtk_input_obs');
    _rtkGetSolution = _lib.lookupFunction<RtkGetSolutionFunc, RtkGetSolutionDart>('rtk_get_solution');
  }

  // NTRIP client methods
  int ntripInit() {
    return _ntripInit();
  }

  int ntripConnect(String url, String user, String passwd) {
    final urlPtr = url.toNativeUtf8();
    final userPtr = user.toNativeUtf8();
    final passwdPtr = passwd.toNativeUtf8();

    try {
      return _ntripConnect(urlPtr, userPtr, passwdPtr);
    } finally {
      calloc.free(urlPtr);
      calloc.free(userPtr);
      calloc.free(passwdPtr);
    }
  }

  int ntripDisconnect(int stream) {
    return _ntripDisconnect(stream);
  }

  int ntripRead(int stream, Pointer<Uint8> buffer, int size) {
    return _ntripRead(stream, buffer, size);
  }

  String ntripGetError() {
    final bufferSize = 1024;
    final buffer = calloc<Uint8>(bufferSize);

    try {
      _ntripGetError(buffer as Pointer<Utf8>, bufferSize);
      return buffer.cast<Utf8>().toDartString();
    } finally {
      calloc.free(buffer);
    }
  }

  // RTK methods
  Pointer rtkCreate() {
    return _rtkCreate();
  }

  void rtkDestroy(Pointer rtkPtr) {
    _rtkDestroy(rtkPtr);
  }

  int rtkInitOptions(Pointer rtkPtr, int mode, int solType) {
    return _rtkInitOptions(rtkPtr, mode, solType);
  }

  int rtkInputObs(Pointer rtkPtr, Uint8List data, int format) {
    final dataPtr = calloc<Uint8>(data.length);

    try {
      // Copy data to native buffer
      for (int i = 0; i < data.length; i++) {
        dataPtr[i] = data[i];
      }

      return _rtkInputObs(rtkPtr, dataPtr, data.length, format);
    } finally {
      calloc.free(dataPtr);
    }
  }

  Map<String, dynamic> rtkGetSolution(Pointer rtkPtr) {
    final posPtr = calloc<Double>(3);
    final qrPtr = calloc<Float>(6);
    final statPtr = calloc<Int32>(1);

    try {
      int result = _rtkGetSolution(rtkPtr, posPtr, qrPtr, statPtr);

      if (result == 0) {
        return {'success': false};
      }

      List<double> position = [posPtr[0], posPtr[1], posPtr[2]];

      List<double> quality = [qrPtr[0], qrPtr[1], qrPtr[2], qrPtr[3], qrPtr[4], qrPtr[5]];

      return {'success': true, 'position': position, 'quality': quality, 'status': statPtr[0]};
    } finally {
      calloc.free(posPtr);
      calloc.free(qrPtr);
      calloc.free(statPtr);
    }
  }
}
