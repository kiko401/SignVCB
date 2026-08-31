import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/sse_client.dart';
import 'sse_event.dart';
import 'chat_models.dart';

class ChatApi {
  ChatApi(this._dio, this._sseClient);

  final Dio _dio;
  final SseClient _sseClient;

  Stream<SseEvent> rewrite({required String text, String? context}) {
    return _sseClient.stream(
      '/api/v1/chat/rewrite',
      data: {
        'text': text,
        if (context != null) 'context': context,
      },
    );
  }

  Stream<SseEvent> asrAndRewrite({
    required FormData formData,
  }) {
    return _sseClient.stream(
      '/api/v1/chat/asr_and_rewrite',
      data: formData,
    );
  }

  Future<List<SuggestionItem>> suggestReply({
    required String text,
    String? context,
  }) async {
    final response = await _dio.post('/api/v1/chat/suggest_reply', data: {
      'text': text,
      if (context != null) 'context': context,
    });
    final items = (response.data['suggestions'] as List? ?? const []);
    return items
        .whereType<Map>()
        .map((e) => SuggestionItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<NormalizeOptionsResponse> normalizeOptions({
    required String text,
    int numOptions = 3,
  }) async {
    final response = await _dio.post('/api/v1/chat/normalize_options', data: {
      'text': text,
      'num_options': numOptions,
    });
    return NormalizeOptionsResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<TtsResponse> tts({required String text, double speed = 1.0}) async {
    final response = await _dio.post('/api/v1/chat/tts', data: {
      'text': text,
      'speed': speed,
    });
    return TtsResponse.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> logMismatch({
    required String originalText,
    required List<String> failedOptions,
    String? context,
  }) async {
    await _dio.post('/api/v1/chat/log_mismatch', data: {
      'original_text': originalText,
      'failed_options': failedOptions,
      if (context != null) 'context': context,
    });
  }

  Future<ChatConfig> fetchConfig() async {
    final response = await _dio.get('/api/v1/app_config');
    final data = Map<String, dynamic>.from(response.data as Map);
    return ChatConfig(
      enableStreamMasking: (data['enable_stream_masking'] as bool?) ?? true,
      showOovMap: (data['show_oov_map'] as bool?) ?? true,
      showNmmHints: (data['show_nmm_hints'] as bool?) ?? true,
      sseTimeoutMs: (data['sse_timeout_ms'] as num?)?.toInt() ?? 10000,
    );
  }

}

final chatApiProvider = Provider<ChatApi>((ref) {
  return ChatApi(ref.read(dioProvider), ref.read(sseClientProvider));
});
