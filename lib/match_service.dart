import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchService {
  final firestore = FirebaseFirestore.instance;

  // Kullanıcıların üniversite bilgilerini kontrol eden metod
  Future<String?> checkAndCreateMatch(String userA, String userB) async {
    // Kullanıcıların üniversite bilgilerini alalım
    final userADoc = await firestore.collection('users').doc(userA).get();
    final userBDoc = await firestore.collection('users').doc(userB).get();

    final userAUniversity = userADoc.data()?['university'];
    final userBUniversity = userBDoc.data()?['university'];

    // Eğer kullanıcılar farklı üniversitelerdense, eşleşme yapılmasın
    if (userAUniversity != userBUniversity) {
      return null; // Aynı üniversite değillerse eşleşme yapılmaz
    }

    final matchId = generateMatchId(userA, userB);
    final matchDoc = firestore.collection('matches').doc(matchId);

    final matchSnapshot = await matchDoc.get();

    if (matchSnapshot.exists) {
      return matchId; // Zaten eşleşmişler
    }

    // Swipe kayıt et
    await matchDoc.set({
      'users': [userA, userB],
      'timestamp': FieldValue.serverTimestamp(),
      'lastMessageTime': null,
    });

    // Bildirim gönder (Sadece aynı üniversiteden olanlar için)
    await _sendNotification(userA, userB);
    await _sendNotification(userB, userA);

    // Swipe count güncelle
    await _incrementSwipeCount(userA);

    return matchId;
  }

  // Kullanıcılara bildirim gönderen metod
  Future<void> _sendNotification(String toUser, String fromUser) async {
    final userADoc = await firestore.collection('users').doc(fromUser).get();
    final userBDoc = await firestore.collection('users').doc(toUser).get();

    final userAUniversity = userADoc.data()?['university'];
    final userBUniversity = userBDoc.data()?['university'];

    // Eğer kullanıcılar farklı üniversitelerdense bildirim gönderme
    if (userAUniversity != userBUniversity) return;

    await firestore
        .collection('notifications')
        .doc(toUser)
        .collection('userNotifications')
        .add({
      'type': 'match',
      'senderId': fromUser,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Kullanıcıların swipe sayısını güncelleyen metod
  Future<void> _incrementSwipeCount(String userId) async {
    final doc = firestore.collection('swipes').doc(userId);
    final snapshot = await doc.get();

    if (snapshot.exists) {
      await doc.update({'count': FieldValue.increment(1)});
    } else {
      await doc.set({
        'count': 1,
        'date': Timestamp.now(),
      });
    }
  }

  // Kullanıcıların günlük swipe limitini kontrol eden metod
  Future<bool> canSwipe(String userId) async {
    final doc = await firestore.collection('swipes').doc(userId).get();
    if (!doc.exists) return true;

    final data = doc.data()!;
    final count = data['count'] ?? 0;
    final date = (data['date'] as Timestamp).toDate();
    final today = DateTime.now();

    // Yeni güne geçtiyse resetle
    if (date.day != today.day || date.month != today.month || date.year != today.year) {
      await firestore.collection('swipes').doc(userId).set({'count': 1, 'date': Timestamp.now()});
      return true;
    }

    return count < 50; // Kullanıcı günde sadece 50 swipe yapabilir
  }

  // 24 saatten fazla mesajlaşma yapılmayan eşleşmeleri temizleyen metod
  Future<void> cleanupExpiredMatches() async {
    final cutoff = Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 24)));
    final expiredMatches = await firestore
        .collection('matches')
        .where('lastMessageTime', isNull: true)
        .where('timestamp', isLessThan: cutoff)
        .get();

    for (var doc in expiredMatches.docs) {
      await firestore.collection('matches').doc(doc.id).delete();
      await firestore.collection('chats').doc(doc.id).delete(); // Chat mesajlarını da sil
    }
  }

  // Match ID oluşturuluyor
  String generateMatchId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}
