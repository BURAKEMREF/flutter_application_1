import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  String username = '';
  String profileImageUrl = '';
  String university = '';

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  Future<void> _getUserInfo() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (!mounted) return;
    setState(() {
      username        = doc['username']        ?? 'Unknown';
      profileImageUrl = doc['profileImageUrl'] ?? '';
      university      = doc['university']      ?? '';
    });
  }

  Future<void> _deletePost(String postId, String mediaUrl) async {
    try { await FirebaseStorage.instance.refFromURL(mediaUrl).delete(); } catch (_) {}
    await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
  }

  ImageProvider<Object>? _safeImage(String? url) =>
      (url != null && url.startsWith('http')) ? NetworkImage(url) : null;

  Widget _buildPostsList() {
    final stream = FirebaseFirestore.instance
        .collection('posts')                       // ✅ kök koleksiyon
        .where('userId', isEqualTo: user!.uid)     // filtre
        .orderBy('timestamp', descending: true)    // sıralama
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Hata: ${snap.error}'));
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('Henüz paylaşımınız yok.'));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data();
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: _safeImage(d['profileImageUrl']),
                  child: _safeImage(d['profileImageUrl']) == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(d['username'] ?? ''),
                subtitle: Text(d['description'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deletePost(docs[i].id, d['mediaUrl']),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _edit() => Navigator.push(
        context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: _safeImage(profileImageUrl) ??
                  const AssetImage('assets/default_avatar.png'),
            ),
            const SizedBox(height: 20),
            Text(username,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('University: $university'),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _edit, child: const Text('Edit Profile')),
            const SizedBox(height: 20),
            Expanded(child: _buildPostsList()),
          ],
        ),
      ),
    );
  }
}
