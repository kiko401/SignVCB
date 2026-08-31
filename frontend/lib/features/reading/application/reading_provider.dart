import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reading_api.dart';
import '../data/reading_models.dart';

enum ReadingBooksStatus { initial, loading, data, empty, error }

class ReadingBooksState {
  const ReadingBooksState({
    this.selectedAgeGroup = 'L1',
    this.books = const [],
    this.status = ReadingBooksStatus.initial,
    this.errorMessage,
  });

  final String selectedAgeGroup;
  final List<ReadingBook> books;
  final ReadingBooksStatus status;
  final String? errorMessage;

  ReadingBooksState copyWith({
    String? selectedAgeGroup,
    List<ReadingBook>? books,
    ReadingBooksStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReadingBooksState(
      selectedAgeGroup: selectedAgeGroup ?? this.selectedAgeGroup,
      books: books ?? this.books,
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class ReadingBooksNotifier extends StateNotifier<ReadingBooksState> {
  ReadingBooksNotifier(this._api) : super(const ReadingBooksState()) {
    loadBooks();
  }

  final ReadingApi _api;
  int _requestSerial = 0;

  Future<void> selectAgeGroup(String ageGroup) async {
    if (ageGroup == state.selectedAgeGroup &&
        state.status == ReadingBooksStatus.loading) {
      return;
    }
    state = state.copyWith(
      selectedAgeGroup: ageGroup,
      books: const [],
      status: ReadingBooksStatus.initial,
      clearError: true,
    );
    await loadBooks();
  }

  Future<void> loadBooks() async {
    final requestSerial = ++_requestSerial;
    final ageGroup = state.selectedAgeGroup;
    state = state.copyWith(
      status: ReadingBooksStatus.loading,
      books: const [],
      clearError: true,
    );

    try {
      final books = await _api.getBooks(ageGroup: ageGroup);
      if (requestSerial != _requestSerial) return;
      state = state.copyWith(
        books: books,
        status:
            books.isEmpty ? ReadingBooksStatus.empty : ReadingBooksStatus.data,
        clearError: true,
      );
    } catch (error) {
      if (requestSerial != _requestSerial) return;
      // 后端尚未启动时保留可操作的本地示例；后端恢复后会自动优先显示真实数据。
      final mockBooks = ReadingBook.mockBooks
          .where((book) => book.ageGroup == ageGroup)
          .toList(growable: false);
      state = state.copyWith(
        books: mockBooks,
        status: mockBooks.isEmpty
            ? ReadingBooksStatus.error
            : ReadingBooksStatus.data,
        errorMessage: error is FormatException ? error.message : '当前显示示例书籍',
      );
    }
  }
}

final readingBooksProvider =
    StateNotifierProvider<ReadingBooksNotifier, ReadingBooksState>(
  (ref) => ReadingBooksNotifier(ref.read(readingApiProvider)),
);
