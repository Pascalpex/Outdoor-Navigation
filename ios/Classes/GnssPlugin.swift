import Flutter
import UIKit

public class GnssPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterEventChannel(name: "gnss_plugin/raw_stream", binaryMessenger: registrar.messenger())
    channel.setStreamHandler(GnssPlugin())
    let nmeaChannel = FlutterEventChannel(name: "gnss_plugin/nmea_stream", binaryMessenger: registrar.messenger())
    nmeaChannel.setStreamHandler(GnssPlugin())
  }

  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    return nil
  }
}
