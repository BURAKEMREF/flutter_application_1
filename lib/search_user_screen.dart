import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'other_profile_screen.dart'; // OtherProfileScreen'i ekliyoruz

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({Key? key}) : super(key: key);

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Future<void> _searchUsers(String query) async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    setState(() {
      searchResults = result.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['userId'] = doc.id; // Belge kimliği userId olarak ayarlanıyor
        return data;
      }).toList();
    });
  }

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
        const SnackBar(content: Text('You are now following this user!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error following user: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Users'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search by username',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _searchUsers(value);
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final user = searchResults[index];
                  final String? profileImageUrl = user['profileImageUrl'];
                  final String userId = user['userId'] ?? '';

                  if (userId.isEmpty) {
                    return ListTile(
                      title: const Text('Error: User ID is missing'),
                    );
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                          ? (Uri.tryParse(profileImageUrl)?.isAbsolute == true
                              ? NetworkImage(profileImageUrl)
                              : FileImage(File(profileImageUrl))) as ImageProvider
                          : const AssetImage('assets/default_profile.png'),
                      child: profileImageUrl == null || profileImageUrl.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(user['username'] ?? 'Unknown User'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OtherProfileScreen(userId: userId),
                        ),
                      );
                    },
                    trailing: ElevatedButton(
                      onPressed: () {
                        _followUser(userId);
                      },
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
