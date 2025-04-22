class MatchModel {
  final String userId1;
  final String userId2;
  final DateTime createdAt;
  final bool isMatched;
  final DateTime? expiresAt;

  MatchModel({
    required this.userId1,
    required this.userId2,
    required this.createdAt,
    required this.isMatched,
    this.expiresAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId1': userId1,
      'userId2': userId2,
      'createdAt': createdAt.toIso8601String(),
      'isMatched': isMatched,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory MatchModel.fromMap(Map<String, dynamic> map) {
    return MatchModel(
      userId1: map['userId1'],
      userId2: map['userId2'],
      createdAt: DateTime.parse(map['createdAt']),
      isMatched: map['isMatched'],
      expiresAt: map['expiresAt'] != null ? DateTime.parse(map['expiresAt']) : null,
    );
  }
}
