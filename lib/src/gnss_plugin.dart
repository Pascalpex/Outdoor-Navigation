import 'package:flutter/services.dart';

class GnssPlugin {
  static const EventChannel _gnssStream = EventChannel('gnss_plugin/raw_stream');

  static Stream<dynamic> get gnssStream {
    return _gnssStream.receiveBroadcastStream();
  }
}
