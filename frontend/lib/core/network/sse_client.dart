import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/data/sse_event.dart';
import 'dio_client.dart';

class SseClient {
  SseClient(this._dio);

  final Dio _dio;

  Stream<SseEvent> stream(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async* {
    final response = await _dio.post<ResponseBody>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(
        responseType: ResponseType.stream,
        headers: const {'Accept': 'text/event-stream'},
        receiveTimeout: Duration.zero,
      ),
    );

    final responseBody = response.data;
    if (responseBody == null) return;

    String? currentEvent;
    String? currentData;

    const splitter = LineSplitter();
    await for (final chunk in responseBody.stream) {
      final text = utf8.decode(chunk);
      for (final line in splitter.convert(text)) {
        if (line.startsWith('event:')) {
          currentEvent = line;
        } else if (line.startsWith('data:')) {
          currentData = line;
        } else if (line.isEmpty && (currentEvent != null || currentData != null)) {
          yield SseEvent.fromRaw(currentEvent, currentData);
          currentEvent = null;
          currentData = null;
        }
      }
    }

    if (currentEvent != null || currentData != null) {
      yield SseEvent.fromRaw(currentEvent, currentData);
    }
  }
}

final sseClientProvider = Provider<SseClient>((ref) {
  return SseClient(ref.watch(dioProvider));
});
