import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';

class MatchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createMatch(String userA, String userB) async {
    final match = MatchModel(
      userA: userA,
      userB: userB,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('matches').add(match.toMap());
  }

  Future<List<MatchModel>> getMatches(String currentUserId) async {
    final query = await _firestore
        .collection('matches')
        .where('isActive', isEqualTo: true)
        .get();

    return query.docs
        .map((doc) => MatchModel.fromMap(doc.data()))
        .where((match) =>
            (match.userA == currentUserId || match.userB == currentUserId))
        .toList();
  }

  Future<void> deactivateOldMatches(Duration timeout) async {
    final cutoff = DateTime.now().subtract(timeout);
    final query = await _firestore
        .collection('matches')
        .where('createdAt', isLessThan: cutoff.toIso8601String())
        .where('isActive', isEqualTo: true)
        .get();

    for (var doc in query.docs) {
      await doc.reference.update({'isActive': false});
    }
  }

  Future<bool> isAlreadyMatched(String userA, String userB) async {
    final query = await _firestore
        .collection('matches')
        .where('isActive', isEqualTo: true)
        .get();

    return query.docs.any((doc) {
      final data = doc.data();
      return (data['userA'] == userA && data['userB'] == userB) ||
             (data['userA'] == userB && data['userB'] == userA);
    });
  }
}
