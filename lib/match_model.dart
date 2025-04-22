class MatchModel {
  final String userA;
  final String userB;
  final DateTime createdAt;
  final bool isActive;

  MatchModel({
    required this.userA,
    required this.userB,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'userA': userA,
      'userB': userB,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory MatchModel.fromMap(Map<String, dynamic> map) {
    return MatchModel(
      userA: map['userA'],
      userB: map['userB'],
      createdAt: DateTime.parse(map['createdAt']),
      isActive: map['isActive'] ?? true,
    );
  }
}
