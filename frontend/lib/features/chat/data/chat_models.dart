import '../../../shared/models/alignment_op.dart';

enum NmmHintType { negation, question, pause }

enum ChatStreamStage {
  idle,
  preheating,
  firstPass,
  refined,
  fallback,
  completed,
  error,
}

enum ChatMessageSender { user, assistant, system }

class PreheatData {
  const PreheatData({required this.original});

  final String original;

  factory PreheatData.fromJson(Map<String, dynamic> json) {
    return PreheatData(original: (json['original'] as String?) ?? '');
  }
}

class FirstPassData {
  const FirstPassData({required this.text, required this.oovStatus});

  final String text;
  final bool oovStatus;

  List<String> get tokens =>
      text.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();

  factory FirstPassData.fromJson(Map<String, dynamic> json) {
    return FirstPassData(
      text: (json['text'] as String?) ?? '',
      oovStatus: (json['oov_status'] as bool?) ?? false,
    );
  }
}

class RefinedPassData {
  const RefinedPassData({
    required this.text,
    required this.oovMap,
    required this.nmmHints,
    required this.alignmentOps,
  });

  final String text;
  final Map<String, String> oovMap;
  final Map<String, NmmHintType> nmmHints;
  final List<AlignmentOp> alignmentOps;

  List<String> get tokens =>
      text.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();

  factory RefinedPassData.fromJson(Map<String, dynamic> json) {
    final rawOovMap = (json['oov_map'] as Map?)?.cast<Object?, Object?>() ?? {};
    final rawHints =
        (json['nmm_hints'] as Map?)?.cast<Object?, Object?>() ?? {};
    final rawOps = (json['alignment_ops'] as List?) ?? const [];

    return RefinedPassData(
      text: (json['text'] as String?) ?? '',
      oovMap: {
        for (final entry in rawOovMap.entries)
          '${entry.key ?? ''}': '${entry.value ?? ''}',
      },
      nmmHints: {
        for (final entry in rawHints.entries)
          '${entry.key ?? ''}': _hintFromJson('${entry.value ?? ''}'),
      },
      alignmentOps: rawOps
          .whereType<Map>()
          .map((e) => AlignmentOp.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  static NmmHintType _hintFromJson(String value) {
    switch (value.toUpperCase()) {
      case 'NEGATION':
        return NmmHintType.negation;
      case 'QUESTION':
        return NmmHintType.question;
      case 'PAUSE':
        return NmmHintType.pause;
      default:
        return NmmHintType.pause;
    }
  }
}

class FallbackData {
  const FallbackData({required this.fallbackText});

  final String fallbackText;

  factory FallbackData.fromJson(Map<String, dynamic> json) {
    return FallbackData(
      fallbackText: (json['fallback_text'] as String?) ?? '',
    );
  }
}

class SuggestionItem {
  const SuggestionItem({required this.text, this.reason});

  final String text;
  final String? reason;

  factory SuggestionItem.fromJson(Map<String, dynamic> json) {
    return SuggestionItem(
      text: (json['text'] as String?) ?? '',
      reason: json['reason'] as String?,
    );
  }
}

class TtsResponse {
  const TtsResponse({required this.audioUrl});

  final String audioUrl;

  factory TtsResponse.fromJson(Map<String, dynamic> json) {
    return TtsResponse(audioUrl: (json['audio_url'] as String?) ?? '');
  }
}

class NormalizeOptionsResponse {
  const NormalizeOptionsResponse({required this.options});

  final List<String> options;

  factory NormalizeOptionsResponse.fromJson(Map<String, dynamic> json) {
    return NormalizeOptionsResponse(
      options: ((json['options'] as List?) ?? const [])
          .map((e) => '$e')
          .toList(),
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.createdAt,
    this.stage,
    this.preheat,
    this.firstPass,
    this.refinedPass,
    this.fallback,
    this.isStreaming = false,
    this.isError = false,
    this.errorText,
    this.retryText,
    this.fromVoice = false,
  });

  final String id;
  final ChatMessageSender sender;
  final String text;
  final DateTime createdAt;
  final ChatStreamStage? stage;
  final PreheatData? preheat;
  final FirstPassData? firstPass;
  final RefinedPassData? refinedPass;
  final FallbackData? fallback;
  final bool isStreaming;
  final bool isError;
  final String? errorText;
  final String? retryText;
  final bool fromVoice;

  ChatMessage copyWith({
    String? text,
    ChatStreamStage? stage,
    PreheatData? preheat,
    FirstPassData? firstPass,
    RefinedPassData? refinedPass,
    FallbackData? fallback,
    bool? isStreaming,
    bool? isError,
    String? errorText,
    String? retryText,
  }) {
    return ChatMessage(
      id: id,
      sender: sender,
      text: text ?? this.text,
      createdAt: createdAt,
      stage: stage ?? this.stage,
      preheat: preheat ?? this.preheat,
      firstPass: firstPass ?? this.firstPass,
      refinedPass: refinedPass ?? this.refinedPass,
      fallback: fallback ?? this.fallback,
      isStreaming: isStreaming ?? this.isStreaming,
      isError: isError ?? this.isError,
      errorText: errorText ?? this.errorText,
      retryText: retryText ?? this.retryText,
      fromVoice: fromVoice,
    );
  }
}

class ChatConfig {
  const ChatConfig({
    this.enableStreamMasking = true,
    this.showOovMap = true,
    this.showNmmHints = true,
    this.sseTimeoutMs = 10000,
  });

  final bool enableStreamMasking;
  final bool showOovMap;
  final bool showNmmHints;
  final int sseTimeoutMs;
}

String nmmHintToEmoji(NmmHintType hint) {
  switch (hint) {
    case NmmHintType.negation:
      return '🚫';
    case NmmHintType.question:
      return '❓';
    case NmmHintType.pause:
      return '⏸️';
  }
}
