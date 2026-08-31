enum SseEventType { preheat, firstPass, refinedPass, fallback, error, done, unknown }

class SseEvent {
  const SseEvent({required this.type, required this.rawData});

  final SseEventType type;
  final String rawData;

  factory SseEvent.fromRaw(String? eventLine, String? dataLine) {
    final eventName = (eventLine ?? '').replaceFirst('event:', '').trim();
    final rawData = (dataLine ?? '').replaceFirst('data:', '').trim();
    return SseEvent(type: _mapType(eventName), rawData: rawData);
  }

  static SseEventType _mapType(String value) {
    switch (value) {
      case 'preheat':
        return SseEventType.preheat;
      case 'first_pass':
        return SseEventType.firstPass;
      case 'refined_pass':
        return SseEventType.refinedPass;
      case 'fallback':
        return SseEventType.fallback;
      case 'error':
        return SseEventType.error;
      case 'done':
        return SseEventType.done;
      default:
        return SseEventType.unknown;
    }
  }
}
