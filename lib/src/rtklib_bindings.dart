// rtklib_bindings.dart
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

const int maxOutputBuffer = 8192; // Maximum buffer size for the solution output

// --- Native Function Signatures (Typedefs) for the new direct injection method ---

// --- Typedefs for basic server control and status (remain the same) ---
typedef _StopServerNative = ffi.Void Function();
typedef _InitServerNative = ffi.Int32 Function();
typedef _StartServerNative = ffi.Int32 Function();
typedef _PrintServerStatusNative = ffi.Void Function();
typedef _InputRoverObsNative =
    ffi.Int32 Function(
      ffi.Int64,
      ffi.Pointer<ffi.Int32>,
      ffi.Pointer<ffi.Int32>,
      ffi.Pointer<ffi.Double>,
      ffi.Pointer<ffi.Double>,
      ffi.Pointer<ffi.Double>,
      ffi.Pointer<ffi.Int32>,
      ffi.Pointer<ffi.Double>,
      ffi.Pointer<ffi.Double>,
      ffi.Int32,
    );
typedef _GetRtkSolutionNative = ffi.Int32 Function(ffi.Pointer<ffi.Uint8>, ffi.Int32);

typedef StopServerDart = void Function();
typedef InitServerDart = int Function();
typedef StartServerDart = int Function();
typedef PrintServerStatusDart = void Function();
typedef InputRoverObsDart =
    int Function(
      int,
      ffi.Pointer<ffi.Int32>,
      ffi.Pointer<ffi.Int32>,
      ffi.Pointer<ffi.Double>,
      ffi.Pointer<ffi.Double>,
      ffi.Pointer<ffi.Double>,
      ffi.Pointer<ffi.Int32>,
      ffi.Pointer<ffi.Double>,
      ffi.Pointer<ffi.Double>,
      int,
    );
typedef GetRtkSolutionDart = int Function(ffi.Pointer<ffi.Uint8>, int);

/// Manages the FFI bridge to the native RTKLIB wrapper library.
/// This class handles server initialization, data processing, and state management.
class RtklibBindings {
  // --- FFI Function Pointers ---
  late final InitServerDart _initServer;
  late final StartServerDart _startServer;
  late final StopServerDart _stopServer;
  late final PrintServerStatusDart _printServerStatus;
  late final InputRoverObsDart _inputRoverObservation;
  late final GetRtkSolutionDart _getRtkSolution;

  // Persistent buffer for reading solution data from the C++ layer
  final _readBuffer = calloc<ffi.Uint8>(maxOutputBuffer);

  late final ffi.DynamicLibrary _dylib;

  RtklibBindings() {
    _dylib = ffi.DynamicLibrary.open(_getLibraryPath());

    // Look up all the required C functions
    _initServer = _dylib.lookup<ffi.NativeFunction<_InitServerNative>>('init_rtk_server').asFunction<InitServerDart>();
    _stopServer = _dylib.lookup<ffi.NativeFunction<_StopServerNative>>('stop_rtk_server').asFunction<StopServerDart>();
    _startServer = _dylib.lookup<ffi.NativeFunction<_StartServerNative>>('start_rtk_server').asFunction<StartServerDart>();
    _printServerStatus = _dylib.lookup<ffi.NativeFunction<_PrintServerStatusNative>>('print_rtk_server_status_debug').asFunction<PrintServerStatusDart>();
    _inputRoverObservation = _dylib.lookup<ffi.NativeFunction<_InputRoverObsNative>>('input_rover_observation').asFunction<InputRoverObsDart>();
    _getRtkSolution = _dylib.lookup<ffi.NativeFunction<_GetRtkSolutionNative>>('get_rtk_solution').asFunction<GetRtkSolutionDart>();
  }

  static String _getLibraryPath() {
    if (Platform.isMacOS) return 'libgnss_rtklib.dylib';
    if (Platform.isWindows) return 'gnss_rtklib.dll';
    return 'libgnss_rtklib.so';
  }

  /// Initializes the RTK server. Must be called before starting.
  void initServer() {
    final result = _initServer();
    print("RTKLIB: Server initialized with result: $result");
  }

  /// Starts the RTK server thread and connects to the NTRIP caster.
  void startServer() {
    final int result = _startServer();
    if (result == 0) {
      print("RTKLIB: Failed to start or stabilize RTK Server via FFI.");
      return;
    }
    print("RTKLIB: Server started successfully via FFI.");
  }

  /// Stops the RTK server thread and disconnects streams.
  void stopServer() {
    _stopServer();
    print("RTKLIB: Server stop command issued.");
  }

  void processGnssData(Map<String, dynamic> gnssData) {
    ffi.Pointer<ffi.Int32> svidsPtr = ffi.nullptr;
    ffi.Pointer<ffi.Int32> constsPtr = ffi.nullptr;
    ffi.Pointer<ffi.Double> cn0sPtr = ffi.nullptr;
    ffi.Pointer<ffi.Double> freqsPtr = ffi.nullptr;
    ffi.Pointer<ffi.Double> adrsPtr = ffi.nullptr;
    ffi.Pointer<ffi.Int32> adrStatesPtr = ffi.nullptr;
    ffi.Pointer<ffi.Double> pratesPtr = ffi.nullptr;
    ffi.Pointer<ffi.Double> prsPtr = ffi.nullptr;

    try {
      final gpsTimeNanos = gnssData['gpsTimeNanos'] as int;
      final svids = gnssData['svids'] as Int32List;
      final consts = gnssData['constellationTypes'] as Int32List;
      final cn0s = gnssData['cn0DbHzs'] as Float64List;
      final freqs = gnssData['carrierFrequenciesHz'] as Float64List;
      final adrs = gnssData['accumulatedDeltaRangeMeters'] as Float64List;
      final adrStates = gnssData['accumulatedDeltaRangeStates'] as Int32List;
      final prates = gnssData['pseudorangeRateMetersPerSecond'] as Float64List;
      final prs = gnssData['pseudoranges'] as Float64List;

      // Allocate memory on the native heap and copy data from Dart lists
      svidsPtr = calloc<ffi.Int32>(svids.length)..asTypedList(svids.length).setAll(0, svids);
      constsPtr = calloc<ffi.Int32>(consts.length)..asTypedList(consts.length).setAll(0, consts);
      cn0sPtr = calloc<ffi.Double>(cn0s.length)..asTypedList(cn0s.length).setAll(0, cn0s);
      freqsPtr = calloc<ffi.Double>(freqs.length)..asTypedList(freqs.length).setAll(0, freqs);
      adrsPtr = calloc<ffi.Double>(adrs.length)..asTypedList(adrs.length).setAll(0, adrs);
      adrStatesPtr = calloc<ffi.Int32>(adrStates.length)..asTypedList(adrStates.length).setAll(0, adrStates);
      pratesPtr = calloc<ffi.Double>(prates.length)..asTypedList(prates.length).setAll(0, prates);
      prsPtr = calloc<ffi.Double>(prs.length)..asTypedList(prs.length).setAll(0, prs);

      _inputRoverObservation(gpsTimeNanos, svidsPtr, constsPtr, cn0sPtr, freqsPtr, adrsPtr, adrStatesPtr, pratesPtr, prsPtr, svids.length);
    } finally {
      if (svidsPtr != ffi.nullptr) calloc.free(svidsPtr);
      if (constsPtr != ffi.nullptr) calloc.free(constsPtr);
      if (cn0sPtr != ffi.nullptr) calloc.free(cn0sPtr);
      if (freqsPtr != ffi.nullptr) calloc.free(freqsPtr);
      if (adrsPtr != ffi.nullptr) calloc.free(adrsPtr);
      if (adrStatesPtr != ffi.nullptr) calloc.free(adrStatesPtr);
      if (pratesPtr != ffi.nullptr) calloc.free(pratesPtr);
      if (prsPtr != ffi.nullptr) calloc.free(prsPtr);
    }
  }

  void printServerStatus() => _printServerStatus();

  Map<String, dynamic>? getLatestSolution() {
    final int length = _getRtkSolution(_readBuffer, maxOutputBuffer);

    if (length <= 0) {
      if (length < 0) {
        print("RTKLIB: Error getting solution from native layer (e.g., buffer too small).");
      }
      return null;
    }

    try {
      final solutionString = utf8.decode(_readBuffer.asTypedList(length));
      return json.decode(solutionString) as Map<String, dynamic>;
    } catch (e) {
      print("RTKLIB: Failed to parse solution JSON from native layer: $e");
      return null;
    }
  }

  void dispose() {
    calloc.free(_readBuffer);
  }
}
