import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchScreen extends StatefulWidget {
  final String? currentUserId;

  const MatchScreen({Key? key, this.currentUserId}) : super(key: key);

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  int swipeLimit = 50;
  List<Map<String, dynamic>> allUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _checkSwipeLimit();
  }

  Future<void> _checkSwipeLimit() async {
    final doc = await FirebaseFirestore.instance.collection('swipes').doc(widget.currentUserId).get();
    final now = DateTime.now();

    if (doc.exists) {
      final data = doc.data()!;
      final lastReset = (data['lastSwipeReset'] as Timestamp).toDate();
      final today = DateTime(now.year, now.month, now.day);

      if (lastReset.isBefore(today)) {
        // Yeni güne geçilmiş, hak sıfırlanmalı
        await FirebaseFirestore.instance.collection('swipes').doc(widget.currentUserId).set({
          'swipeCount': 0,
          'lastSwipeReset': Timestamp.fromDate(now),
        });
      } else if ((data['swipeCount'] as int) >= 50) {
        setState(() {
          swipeLimit = 0;
        });
      }
    } else {
      // Yeni kullanıcı
      await FirebaseFirestore.instance.collection('swipes').doc(widget.currentUserId).set({
        'swipeCount': 0,
        'lastSwipeReset': Timestamp.fromDate(now),
      });
    }
  }

  Future<void> _loadUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final others = snapshot.docs
        .where((doc) => doc.id != widget.currentUserId)
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();

    setState(() {
      allUsers = others;
    });
  }

  Future<void> _handleLike(String likedUserId) async {
    if (swipeLimit <= 0) return;

    final currentUserId = widget.currentUserId!;
    final likesRef = FirebaseFirestore.instance.collection('likes');
    final matchesRef = FirebaseFirestore.instance.collection('matches');

    await likesRef.doc('$currentUserId\_$likedUserId').set({
      'from': currentUserId,
      'to': likedUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Karşı taraftan da like varsa eşleşme
    final reverseLike = await likesRef.doc('$likedUserId\_$currentUserId').get();
    if (reverseLike.exists) {
      final matchId = '${currentUserId}_$likedUserId';

      await matchesRef.doc(matchId).set({
        'users': [currentUserId, likedUserId],
        'matchedAt': FieldValue.serverTimestamp(),
      });

      // Bildirim gönder
      for (final uid in [currentUserId, likedUserId]) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(uid)
            .collection('userNotifications')
            .add({
          'type': 'match',
          'senderId': uid == currentUserId ? likedUserId : currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Chat başlatılabilir
      await FirebaseFirestore.instance.collection('chats').doc(matchId).set({
        'users': [currentUserId, likedUserId],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Swipe hakkını azalt
    await FirebaseFirestore.instance.collection('swipes').doc(currentUserId).update({
      'swipeCount': FieldValue.increment(1),
    });

    setState(() {
      swipeLimit--;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (swipeLimit == 0) {
      return const Scaffold(
        body: Center(child: Text('Günlük swipe limitin doldu. Yarın tekrar dene.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Discover People')),
      body: allUsers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Swiper(
              itemCount: allUsers.length,
              itemBuilder: (context, index) {
                final user = allUsers[index];
                return Card(
                  margin: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: user['profileImageUrl'] != null
                            ? NetworkImage(user['profileImageUrl'])
                            : null,
                        child: user['profileImageUrl'] == null
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user['username'] ?? 'Unknown',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => _handleLike(user['id']),
                        child: const Text('Like'),
                      ),
                    ],
                  ),
                );
              },
              onIndexChanged: (index) {},
            ),
    );
  }
}
