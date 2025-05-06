class GnssSatelite {
  final int svid;
  final double cn0DbHz;
  final int constellationType;
  final double pseudorangeRateMetersPerSecond;
  final double accumulatedDeltaRangeMeters;
  final int accumulatedDeltaRangeState;
  final double accumulatedDeltaRangeUncertaintyMeters;
  final double basebandCn0DbHz;
  final double carrierFrequencyHz;
  final String codeType;
  final double fullInterSignalBiasNanos;
  final double fullInterSignalBiasUncertaintyNanos;
  final int multipathIndicator;
  final double pseudorangeRateUncertaintyMetersPerSecond;
  final int receivedSvTimeNanos;
  final int receivedSvTimeUncertaintyNanos;
  final double satelliteInterSignalBiasNanos;
  final double satelliteInterSignalBiasUncertaintyNanos;
  final double snrInDb;
  final int state;
  final double timeOffsetNanos;

  GnssSatelite({
    required this.svid,
    required this.cn0DbHz,
    required this.constellationType,
    required this.pseudorangeRateMetersPerSecond,
    required this.accumulatedDeltaRangeMeters,
    required this.accumulatedDeltaRangeState,
    required this.accumulatedDeltaRangeUncertaintyMeters,
    required this.basebandCn0DbHz,
    required this.carrierFrequencyHz,
    required this.codeType,
    required this.fullInterSignalBiasNanos,
    required this.fullInterSignalBiasUncertaintyNanos,
    required this.multipathIndicator,
    required this.pseudorangeRateUncertaintyMetersPerSecond,
    required this.receivedSvTimeNanos,
    required this.receivedSvTimeUncertaintyNanos,
    required this.satelliteInterSignalBiasNanos,
    required this.satelliteInterSignalBiasUncertaintyNanos,
    required this.snrInDb,
    required this.state,
    required this.timeOffsetNanos,
  });

  @override
  String toString() {
    return "Satelite #$svid, Signal: ${cn0DbHz}DbHz";
  }
}
