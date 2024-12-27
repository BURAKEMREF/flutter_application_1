import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchScreen extends StatelessWidget {
  final String? currentUserId;

  const MatchScreen({Key? key, this.currentUserId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Matches'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs
              .where((doc) => doc.id != currentUserId) // Kendi profilimizi göstermiyoruz
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          if (users.isEmpty) {
            return const Center(
              child: Text('No more users to swipe!', style: TextStyle(fontSize: 16)),
            );
          }

          return Swiper(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
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
                    const SizedBox(height: 16),
                    Text(
                      user['username'] ?? 'Unknown User',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
            onIndexChanged: (index) {
              // Eşleşme mantığını burada uygulayabilirsiniz
            },
          );
        },
      ),
    );
  }
}
