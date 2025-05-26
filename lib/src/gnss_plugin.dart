import 'package:flutter/services.dart';
import 'package:outdoor_navigation/src/model/gnss_constellation_type.dart';
import 'package:outdoor_navigation/src/model/gnss_satelite.dart';

class GnssPlugin {
  static const EventChannel _gnssStream = EventChannel('gnss_plugin/raw_stream');

  static Stream<dynamic> get _internalGnssStream {
    return _gnssStream.receiveBroadcastStream();
  }

  static Stream<List<GnssSatelite>> get gnssStream {
    return _internalGnssStream.map((event) {
      List<dynamic> rawSatelites = event["measurements"];
      List<GnssSatelite> satelites = List<GnssSatelite>.empty(growable: true);
      for (dynamic satelite in rawSatelites) {
        GnssSatelite gnssSatelite = GnssSatelite(
          svid: satelite["svid"],
          cn0DbHz: satelite["cn0DbHz"],
          constellationType: GnssConstellationTypeExtension.fromInt(satelite["constellationType"]),
          pseudorangeRateMetersPerSecond: satelite["pseudorangeRateMetersPerSecond"],
          accumulatedDeltaRangeMeters: satelite["accumulatedDeltaRangeMeters"],
          accumulatedDeltaRangeState: satelite["accumulatedDeltaRangeState"],
          accumulatedDeltaRangeUncertaintyMeters: satelite["accumulatedDeltaRangeUncertaintyMeters"],
          basebandCn0DbHz: satelite["basebandCn0DbHz"],
          carrierFrequencyHz: satelite["carrierFrequencyHz"],
          codeType: satelite["codeType"],
          fullInterSignalBiasNanos: satelite["fullInterSignalBiasNanos"],
          fullInterSignalBiasUncertaintyNanos: satelite["fullInterSignalBiasUncertaintyNanos"],
          multipathIndicator: satelite["multipathIndicator"],
          pseudorangeRateUncertaintyMetersPerSecond: satelite["pseudorangeRateUncertaintyMetersPerSecond"],
          receivedSvTimeNanos: satelite["receivedSvTimeNanos"],
          receivedSvTimeUncertaintyNanos: satelite["receivedSvTimeUncertaintyNanos"],
          satelliteInterSignalBiasNanos: satelite["satelliteInterSignalBiasNanos"],
          satelliteInterSignalBiasUncertaintyNanos: satelite["satelliteInterSignalBiasUncertaintyNanos"],
          snrInDb: satelite["snrInDb"],
          state: satelite["state"],
          timeOffsetNanos: satelite["timeOffsetNanos"],
        );
        satelites.add(gnssSatelite);
      }
      return satelites;
    });
  }
}
