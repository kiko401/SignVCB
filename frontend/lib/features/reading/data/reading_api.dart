import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'reading_models.dart';

class ReadingApi {
  const ReadingApi(this._dio);

  final Dio _dio;

  Future<List<ReadingBook>> getBooks({String? ageGroup}) async {
    final response = await _dio.get(
      '/api/v1/reading/books',
      queryParameters: {
        if (ageGroup != null && ageGroup.isNotEmpty) 'age_group': ageGroup,
      },
    );

    final data = response.data;
    if (data is! List) {
      throw const FormatException('书库接口返回格式错误');
    }

    return data
        .map((item) => ReadingBook.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}

final readingApiProvider = Provider<ReadingApi>((ref) {
  return ReadingApi(ref.read(dioProvider));
});
