enum GnssConstellationType { unknown, gps, sbas, glonass, qzss, beidou, galileo, irnss }

extension GnssConstellationTypeExtension on GnssConstellationType {
  String get name {
    switch (this) {
      case GnssConstellationType.gps:
        return 'GPS';
      case GnssConstellationType.sbas:
        return 'SBAS';
      case GnssConstellationType.glonass:
        return 'GLONASS';
      case GnssConstellationType.qzss:
        return 'QZSS';
      case GnssConstellationType.beidou:
        return 'BeiDou';
      case GnssConstellationType.galileo:
        return 'Galileo';
      case GnssConstellationType.irnss:
        return 'IRNSS';
      default:
        return 'Unbekannt';
    }
  }

  static GnssConstellationType fromInt(int value) {
    switch (value) {
      case 1:
        return GnssConstellationType.gps;
      case 2:
        return GnssConstellationType.sbas;
      case 3:
        return GnssConstellationType.glonass;
      case 4:
        return GnssConstellationType.qzss;
      case 5:
        return GnssConstellationType.beidou;
      case 6:
        return GnssConstellationType.galileo;
      case 7:
        return GnssConstellationType.irnss;
      default:
        return GnssConstellationType.unknown;
    }
  }
}
