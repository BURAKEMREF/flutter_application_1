import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'other_profile_screen.dart'; // Profil detayı
import 'match_screen.dart';         // 💘 Eşleşme ekranı

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({Key? key}) : super(key: key);

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];

  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // -------------------- FIRESTORE SORGUSU --------------------
  Future<void> _searchUsers(String query) async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    setState(() {
      searchResults = result.docs.map((doc) {
        final data = doc.data();
        data['userId'] = doc.id; // doc.id → userId
        return data;
      }).toList();
    });
  }

  // -------------------- TAKİP ET --------------------
  Future<void> _followUser(String targetUserId) async {
    if (currentUserId == null || currentUserId == targetUserId) return;

    try {
      final followersRef = FirebaseFirestore.instance
          .collection('followers')
          .doc(targetUserId)
          .collection('followersList');

      final followingRef = FirebaseFirestore.instance
          .collection('following')
          .doc(currentUserId)
          .collection('followingList');

      await followersRef.doc(currentUserId).set({});
      await followingRef.doc(targetUserId).set({});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Now following!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Follow error: $e')),
      );
    }
  }

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Users'),
        actions: [
          IconButton(
            tooltip: 'Matches',
            icon: const Icon(Icons.people_alt_outlined), // 🤝  Eşleşme ikonu
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MatchScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔍  Arama kutusu
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search by username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchUsers,
            ),
            const SizedBox(height: 20),

            // 🔽  Sonuç listesi
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final user = searchResults[index];
                  final imgUrl = user['profileImageUrl'] ?? '';
                  final userId = user['userId'] ?? '';

                  if (userId.isEmpty) {
                    return const ListTile(
                      title: Text('Error: User ID missing'),
                    );
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: imgUrl.isNotEmpty && Uri.tryParse(imgUrl)?.isAbsolute == true
                          ? NetworkImage(imgUrl)
                          : null,
                      child: imgUrl.isEmpty ? const Icon(Icons.person) : null,
                    ),
                    title: Text(user['username'] ?? 'Unknown User'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OtherProfileScreen(userId: userId),
                        ),
                      );
                    },
                    trailing: ElevatedButton(
                      onPressed: () => _followUser(userId),
                      child: const Text('Follow'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
