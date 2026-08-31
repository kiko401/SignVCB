import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/logger.dart';
import '../data/chat_api.dart';
import '../data/chat_models.dart';
import '../data/sse_event.dart';

class ChatState {
  const ChatState({
    this.config = const ChatConfig(),
    this.messages = const [],
    this.suggestions = const [],
    this.inputText = '',
    this.isLoading = false,
    this.stage = ChatStreamStage.idle,
    this.errorText,
    this.streamingText = '',
    this.showConfigLoaded = false,
  });

  final ChatConfig config;
  final List<ChatMessage> messages;
  final List<SuggestionItem> suggestions;
  final String inputText;
  final bool isLoading;
  final ChatStreamStage stage;
  final String? errorText;
  final String streamingText;
  final bool showConfigLoaded;

  ChatState copyWith({
    ChatConfig? config,
    List<ChatMessage>? messages,
    List<SuggestionItem>? suggestions,
    String? inputText,
    bool? isLoading,
    ChatStreamStage? stage,
    String? errorText,
    String? streamingText,
    bool? showConfigLoaded,
  }) {
    return ChatState(
      config: config ?? this.config,
      messages: messages ?? this.messages,
      suggestions: suggestions ?? this.suggestions,
      inputText: inputText ?? this.inputText,
      isLoading: isLoading ?? this.isLoading,
      stage: stage ?? this.stage,
      errorText: errorText ?? this.errorText,
      streamingText: streamingText ?? this.streamingText,
      showConfigLoaded: showConfigLoaded ?? this.showConfigLoaded,
    );
  }
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref.watch(chatApiProvider));
});

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._api) : super(const ChatState()) {
    unawaited(_bootstrap());
  }

  final ChatApi _api;
  int _seed = 0;

  Future<void> _bootstrap() async {
    try {
      final config = await _api.fetchConfig();
      state = state.copyWith(config: config, showConfigLoaded: true);
    } catch (e, st) {
      AppLogger.w('chat config load fallback: $e');
      AppLogger.d(st);
      state = state.copyWith(showConfigLoaded: true);
    }
    await loadSuggestions();
  }

  void updateInput(String value) {
    state = state.copyWith(inputText: value);
  }

  Future<void> loadSuggestions() async {
    if (state.inputText.trim().isEmpty) {
      state = state.copyWith(suggestions: const []);
      return;
    }
    try {
      final items = await _api.suggestReply(text: state.inputText.trim());
      state = state.copyWith(suggestions: items.take(3).toList());
    } catch (_) {
      state = state.copyWith(suggestions: const []);
    }
  }

  Future<TtsResponse> tts(String text) => _api.tts(text: text);

  Future<void> sendAudio(String path) async {
    if (state.isLoading) return;
    final userMessage = ChatMessage(
      id: _nextId(),
      sender: ChatMessageSender.user,
      text: '语音消息',
      createdAt: DateTime.now(),
      fromVoice: true,
    );
    final streamingMessage = ChatMessage(
      id: _nextId(),
      sender: ChatMessageSender.assistant,
      text: '正在听…',
      createdAt: DateTime.now(),
      isStreaming: true,
      stage: ChatStreamStage.preheating,
    );
    state = state.copyWith(
      messages: [...state.messages, userMessage, streamingMessage],
      suggestions: const [],
      isLoading: true,
      stage: ChatStreamStage.preheating,
      errorText: null,
      streamingText: '正在听…',
    );
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(path, filename: 'voice.wav'),
      });
      await _consumeRewrite(
        _api.asrAndRewrite(formData: formData),
        streamingMessageId: streamingMessage.id,
      );
    } catch (e, st) {
      AppLogger.e('audio stream failed', e, st);
      _failStreaming(streamingMessage.id);
      state = state.copyWith(isLoading: false, stage: ChatStreamStage.error);
    }
  }

  Future<void> sendText() async {
    final text = state.inputText.trim();
    if (text.isEmpty || state.isLoading) return;

    final userMessage = ChatMessage(
      id: _nextId(),
      sender: ChatMessageSender.user,
      text: text,
      createdAt: DateTime.now(),
    );
    final streamingMessage = ChatMessage(
      id: _nextId(),
      sender: ChatMessageSender.assistant,
      text: '正在识别…',
      createdAt: DateTime.now(),
      isStreaming: true,
      stage: ChatStreamStage.preheating,
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage, streamingMessage],
      inputText: '',
      suggestions: const [],
      isLoading: true,
      stage: ChatStreamStage.preheating,
      errorText: null,
      streamingText: '',
    );

    await _consumeRewrite(
      _api.rewrite(text: text),
      streamingMessageId: streamingMessage.id,
    );
  }

  Future<void> sendQuickReply(String text) async {
    state = state.copyWith(inputText: text);
    await sendText();
  }

  Future<void> retryMessage(String text) async {
    if (text.trim().isEmpty || state.isLoading) return;
    state = state.copyWith(inputText: text);
    await sendText();
  }

  Future<void> _consumeRewrite(
    Stream<SseEvent> stream, {
    required String streamingMessageId,
  }) async {
    try {
      await for (final event in stream) {
        switch (event.type) {
          case SseEventType.preheat:
            final data = PreheatData.fromJson(_json(event.rawData));
            _patchStreaming(
              streamingMessageId,
              text: data.original.isEmpty ? '正在预热…' : data.original,
              stage: ChatStreamStage.preheating,
            );
            break;
          case SseEventType.firstPass:
            final data = FirstPassData.fromJson(_json(event.rawData));
            _patchStreaming(
              streamingMessageId,
              text: data.text,
              stage: ChatStreamStage.firstPass,
            );
            break;
          case SseEventType.refinedPass:
            final data = RefinedPassData.fromJson(_json(event.rawData));
            _patchStreaming(
              streamingMessageId,
              text: data.text,
              stage: ChatStreamStage.refined,
              refinedPass: data,
            );
            break;
          case SseEventType.fallback:
            final data = FallbackData.fromJson(_json(event.rawData));
            _patchStreaming(
              streamingMessageId,
              text: data.fallbackText,
              stage: ChatStreamStage.fallback,
              fallback: data,
            );
            break;
          case SseEventType.error:
            final data = _json(event.rawData);
            throw Exception((data['message'] as String?) ?? '处理失败');
          case SseEventType.done:
            break;
          case SseEventType.unknown:
            break;
        }
      }
      _completeStreaming(streamingMessageId);
    } catch (e, st) {
      AppLogger.e('chat stream failed', e, st);
      _failStreaming(streamingMessageId);
    } finally {
      state = state.copyWith(isLoading: false, stage: ChatStreamStage.idle);
    }
  }

  void _patchStreaming(
    String messageId, {
    required String text,
    required ChatStreamStage stage,
    RefinedPassData? refinedPass,
    FallbackData? fallback,
  }) {
    final updated = state.messages.map((message) {
      if (message.id != messageId) return message;
      return message.copyWith(
        text: text,
        stage: stage,
        refinedPass: refinedPass,
        fallback: fallback,
        isStreaming: true,
      );
    }).toList();

    state = state.copyWith(
      messages: updated,
      stage: stage,
      streamingText: text,
    );
  }

  void _completeStreaming(String messageId) {
    final updated = state.messages.map((message) {
      if (message.id != messageId) return message;
      return message.copyWith(isStreaming: false, stage: ChatStreamStage.completed);
    }).toList();
    state = state.copyWith(messages: updated, stage: ChatStreamStage.completed);
  }

  void _failStreaming(String messageId) {
    final updated = state.messages.map((message) {
      if (message.id != messageId) return message;
      return message.copyWith(
        isStreaming: false,
        isError: true,
        errorText: '出了点小问题，再试一次吧。',
        retryText: _findRetryText(messageId),
        text: '出了点小问题，再试一次吧。',
        stage: ChatStreamStage.error,
      );
    }).toList();
    state = state.copyWith(
      messages: updated,
      errorText: '出了点小问题，再试一次吧。',
      stage: ChatStreamStage.error,
    );
  }

  String? _findRetryText(String messageId) {
    final index = state.messages.indexWhere((message) => message.id == messageId);
    if (index <= 0) return null;
    final previous = state.messages[index - 1];
    if (previous.sender != ChatMessageSender.user) return null;
    if (previous.fromVoice) return null;
    final text = previous.text.trim();
    return text.isEmpty ? null : text;
  }

  void clearConversation() {
    state = state.copyWith(messages: const [], suggestions: const []);
  }

  Map<String, dynamic> _json(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return const {};
  }

  String _nextId() => '${DateTime.now().microsecondsSinceEpoch}_${_seed++}';
}
