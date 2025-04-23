import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'edit_profile_screen.dart';  // Profil düzenleme ekranı

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
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
    if (user != null) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      setState(() {
        username = snapshot['username'] ?? 'Unknown';
        profileImageUrl = snapshot['profileImageUrl'] ?? '';
        university = snapshot['university'] ?? '';
      });
    }
  }

  Future<void> _deletePost(String postId, String mediaUrl) async {
    // Firebase Storage'dan silme işlemi
    try {
      final storageRef = FirebaseStorage.instance.refFromURL(mediaUrl);
      await storageRef.delete();
    } catch (e) {
      print("Error deleting media from storage: $e");
    }

    // Firestore'dan postu silme
    await FirebaseFirestore.instance.collection('posts').doc(postId).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post deleted successfully!')),
    );
  }

  Widget _buildPostsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: user?.uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!.docs;

        if (posts.isEmpty) {
          return const Center(child: Text('No posts available.'));
        }

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final postId = post.id;
            final postData = post.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: postData['profileImageUrl'] != null
                      ? NetworkImage(postData['profileImageUrl'])
                      : null,
                  child: postData['profileImageUrl'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(postData['username']),
                subtitle: Text(postData['description']),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _deletePost(postId, postData['mediaUrl']);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Profil düzenleme ekranına yönlendirme
  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profil fotoğrafı ve kullanıcı adı
            CircleAvatar(
              radius: 60,
              backgroundImage: profileImageUrl.isNotEmpty
                  ? NetworkImage(profileImageUrl) // Profil URL varsa NetworkImage kullan
                  : const AssetImage('assets/default_avatar.png') as ImageProvider, // Varsayılan avatar kullan
            ),
            const SizedBox(height: 20),
            Text(
              username,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'University: $university',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            // Profil düzenleme butonu
            ElevatedButton(
              onPressed: _navigateToEditProfile,
              child: const Text('Edit Profile'),
            ),
            const SizedBox(height: 20),
            // Paylaşılan postları göster
            Expanded(child: _buildPostsList()),
          ],
        ),
      ),
    );
  }
}
