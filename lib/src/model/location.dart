class HHNLocation {
  final double latitude;
  final double longitude;
  final bool valid;

  HHNLocation({required this.latitude, required this.longitude, required this.valid});

  @override
  String toString() {
    if (!valid) {
      return "Invalid location";
    }
    return "Latitude: {$latitude}, Longitude: {$longitude}";
  }
}
