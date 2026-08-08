class PreheatData {
  const PreheatData({required this.text});

  final String text;

  List<String> get tokens => text.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
}

class FirstPassData {
  const FirstPassData({required this.text, this.oovStatus = const {}});

  final String text;
  final Map<String, dynamic> oovStatus;

  List<String> get tokens => text.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
}

class RefinedPassData {
  const RefinedPassData({
    required this.text,
    this.oovMap = const {},
    this.nmmHints = const [],
    this.alignmentOps = const [],
    this.fallbackWords = const [],
  });

  final String text;
  final Map<String, String> oovMap;
  final List<String> nmmHints;
  final List<String> alignmentOps;
  final List<String> fallbackWords;

  bool isFallbackWord(String word) => fallbackWords.contains(word);
}

class FallbackData {
  const FallbackData({required this.text});

  final String text;
}

String nmmHintToEmoji(String hint) {
  switch (hint) {
    case 'NEGATION':
      return '🚫';
    case 'QUESTION':
      return '❓';
    case 'PAUSE':
      return '⏸️';
    default:
      return '•';
  }
}
