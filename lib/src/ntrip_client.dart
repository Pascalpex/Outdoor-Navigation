import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'rtklib_bindings.dart';

/// A client for connecting to NTRIP casters and streaming GNSS correction data.
class NtripClient {
  final RtklibBindings _bindings = RtklibBindings();
  bool _isConnected = false;
  StreamController<Uint8List>? _dataStreamController;

  /// Stream of RTCM data received from the NTRIP caster
  Stream<Uint8List>? get dataStream => _dataStreamController?.stream;

  /// Whether the client is connected to an NTRIP caster
  bool get isConnected => _isConnected;

  NtripClient() {
    // Initialize RTKLIB
    _bindings.ntripInit();
  }

  /// Connect to an NTRIP caster
  ///
  /// [url] should be of the form "ntrip://host:port/mountpoint"
  /// [username] and [password] are used for authentication
  Future<bool> connect(String url, {String username = '', String password = ''}) async {
    if (_isConnected) {
      return false;
    }

    int result = _bindings.ntripConnect(url, username, password);
    if (result > 0) {
      _isConnected = true;
      _dataStreamController = StreamController<Uint8List>.broadcast();

      // Start reading data in an isolate
      _startDataReading();

      return true;
    } else {
      String error = _bindings.ntripGetError();
      throw Exception('Failed to connect to NTRIP caster: $error');
    }
  }

  /// Disconnect from the NTRIP caster
  Future<void> disconnect() async {
    if (!_isConnected) {
      return;
    }

    _isConnected = false;
    _bindings.ntripDisconnect(1);
    await _dataStreamController?.close();
    _dataStreamController = null;
  }

  /// Start reading data from the NTRIP stream in a separate isolate
  void _startDataReading() {
    // In a real implementation, you should use an isolate for this
    // For simplicity, we'll use a timer to periodically read data
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (!_isConnected) {
        timer.cancel();
        return;
      }

      try {
        // Allocate buffer for data
        final bufferSize = 4096;
        final buffer = calloc<Uint8>(bufferSize);

        try {
          // Read data from stream
          int bytesRead = _bindings.ntripRead(1, buffer, bufferSize);

          if (bytesRead > 0) {
            // Copy data to Dart list
            Uint8List data = Uint8List(bytesRead);
            for (int i = 0; i < bytesRead; i++) {
              data[i] = buffer[i];
            }

            // Add data to stream
            _dataStreamController?.add(data);
          }
        } finally {
          calloc.free(buffer);
        }
      } catch (e) {
        print('Error reading NTRIP data: $e');
      }
    });
  }
}
