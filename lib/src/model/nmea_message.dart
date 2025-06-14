class NmeaMessage {
  final String message;
  final int timestamp;

  NmeaMessage({required this.message, required this.timestamp});

  @override
  String toString() {
    return 'NmeaMessage{message: $message, timestamp: $timestamp}';
  }
}
