import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'match_service.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({Key? key}) : super(key: key);

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  List<DocumentSnapshot> users = [];
  final currentUser = FirebaseAuth.instance.currentUser;
  int swipeCount = 0;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    setState(() {
      users = snapshot.docs.where((doc) => doc.id != currentUser!.uid).toList();
    });
  }

  Future<void> onSwipe(DocumentSnapshot userDoc) async {
    if (swipeCount >= 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Swipe limit reached! Try again tomorrow.')),
      );
      return;
    }

    swipeCount++;

    final matchService = MatchService();
    final targetUserId = userDoc.id;
    final data = userDoc.data() as Map<String, dynamic>;

    final matchId = await matchService.checkAndCreateMatch(currentUser!.uid, targetUserId);

    if (matchId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: matchId,
            otherUserId: targetUserId,
            otherUsername: data['username'] ?? 'Unknown',
            otherUserProfileUrl: data['profileImageUrl'] ?? '',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Find Matches')),
      body: Swiper(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index].data() as Map<String, dynamic>;

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            margin: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: user['profileImageUrl'] != null && user['profileImageUrl'].isNotEmpty
                      ? NetworkImage(user['profileImageUrl'])
                      : null,
                  child: user['profileImageUrl'] == null || user['profileImageUrl'].isEmpty
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user['username'] ?? 'Unknown User',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  user['email'] ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        },
        onIndexChanged: (index) {
          // Swipe olduğu anda kullanıcıya işlem uygula
          if (index < users.length) {
            onSwipe(users[index]);
          }
        },
      ),
    );
  }
}
