class ReadingBook {
  const ReadingBook({
    required this.id,
    required this.title,
    required this.ageGroup,
    required this.coverUrl,
    required this.difficulty,
  });

  final int id;
  final String title;
  final String ageGroup;
  final String? coverUrl;
  final int difficulty;

  static const mockBooks = [
    ReadingBook(
      id: 9001,
      title: '小猫钓鱼',
      ageGroup: 'L1',
      coverUrl: 'assets/svg/covers/cover_mock_cat_fishing.svg',
      difficulty: 1,
    ),
    ReadingBook(
      id: 9002,
      title: '小马过河',
      ageGroup: 'L1',
      coverUrl: 'assets/svg/covers/cover_mock_horse_river.svg',
      difficulty: 1,
    ),
    ReadingBook(
      id: 9003,
      title: '曹冲称象',
      ageGroup: 'L1',
      coverUrl: 'assets/svg/covers/cover_mock_elephant.svg',
      difficulty: 1,
    ),
  ];

  factory ReadingBook.fromJson(Map<String, dynamic> json) {
    return ReadingBook(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      ageGroup: json['age_group'] as String,
      coverUrl: json['cover_url'] as String?,
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
    );
  }
}
