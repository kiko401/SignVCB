enum AlignmentOpType { postpone, advance, delete, insert }

class AlignmentOp {
  const AlignmentOp({
    required this.type,
    required this.word,
    this.target,
    this.position,
    this.source,
  });

  final AlignmentOpType type;
  final String word;
  final String? target;
  final int? position;
  final int? source;

  factory AlignmentOp.fromJson(Map<String, dynamic> json) {
    return AlignmentOp(
      type: _typeFromJson(json['type'] as String?),
      word: (json['word'] as String?) ?? '',
      target: json['target'] as String?,
      position: (json['position'] as num?)?.toInt(),
      source: (json['source'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'word': word,
        'target': target,
        'position': position,
        'source': source,
      };

  static AlignmentOpType _typeFromJson(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'postpone':
        return AlignmentOpType.postpone;
      case 'advance':
        return AlignmentOpType.advance;
      case 'delete':
        return AlignmentOpType.delete;
      case 'insert':
        return AlignmentOpType.insert;
      default:
        return AlignmentOpType.postpone;
    }
  }
}
