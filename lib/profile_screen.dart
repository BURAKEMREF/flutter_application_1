//profile_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'edit_profile_screen.dart';
import 'post_widget.dart';       // grid tıklanınca tam ekran göstermek isterseniz (opsiyonel)

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;

  // --------- kullanıcı alanı ----------
  String _username   = '';
  String _avatarUrl  = '';
  String _university = '';
  int    _follower   = 0;
  int    _following  = 0;

  // Firestore referansları
  final _fire = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    if (_user == null) return;

    try {
      final snap = await _fire.collection('users').doc(_user!.uid).get();
      if (!mounted) return;

      setState(() {
        _username   = snap['username']       ?? 'Unknown';
        _avatarUrl  = snap['profileImageUrl']?? '';
        _university = snap['university']     ?? '';
        _follower   = (snap['followerCount'] ?? 0) as int;
        _following  = (snap['followingCount']?? 0) as int;
      });
    } catch (e) {
      debugPrint('User info error → $e');
    }
  }

  Future<void> _deletePost(String postId, String mediaUrl) async {
    // Storage > ardından Firestore
    try {
      await FirebaseStorage.instance.refFromURL(mediaUrl).delete();
      await _fire.collection('posts').doc(postId).delete();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Post silindi')));
    } catch (e) {
      debugPrint('Delete error → $e');
    }
  }

  // ---------- UI Bileşenleri ----------
  Widget _buildStat(String label, int count) => Column(
        children: [
          Text(count.toString(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 40,
              backgroundImage: _avatarUrl.isNotEmpty
                  ? NetworkImage(_avatarUrl)
                  : const AssetImage('assets/default_avatar.png') as ImageProvider,
            ),
            const SizedBox(width: 24),
            // Sayaçlar
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: _fire
                        .collection('posts')
                        .where('userId', isEqualTo: _user?.uid)
                        .snapshots(),
                    builder: (_, snap) =>
                        _buildStat('Posts', snap.data?.size ?? 0),
                  ),
                  _buildStat('Takipçi', _follower),
                  _buildStat('Takip',   _following),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildUserInfo() => Column(
        children: [
          Text(_username,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          if (_university.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('University: $_university',
                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () =>
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()))
                    .then((_) => _loadUserInfo()), // geri dönünce güncelle
            child: const Text('Edit Profile'),
          ),
        ],
      );

  Widget _buildPostGrid() {
    final stream = _fire
        .collection('posts')
        .where('userId', isEqualTo: _user?.uid)
        // sırala + composite index varsa çalışır; yoksa try/catch ile listeler
        .orderBy('timestamp', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          // indeks hatası dâhil her şey burada yakalanır
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Gönderiler alınamadı:\n${snap.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent)),
            ),
          );
        }

        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('Henüz paylaşım yok.'));
        }

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(), // NestedScroll
          shrinkWrap: true,
          itemCount: docs.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 1,
          ),
          itemBuilder: (_, i) {
            final data = docs[i].data();
            final img  = data['mediaUrl'] as String? ?? '';

            return GestureDetector(
              onLongPress: () {
                // uzun basınca sil
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Postu sil?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Vazgeç')),
                      TextButton(
                          onPressed: () {
                            _deletePost(docs[i].id, img);
                            Navigator.pop(context);
                          },
                          child: const Text('Sil')),
                    ],
                  ),
                );
              },
              onTap: () {
                // detaya gitmek isterseniz
                // Navigator.push(context, MaterialPageRoute(builder: (_) =>
                //      PostDetailScreen(postId: docs[i].id)));
              },
              child: img.isNotEmpty
                  ? Image.network(img, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image))
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported)),
            );
          },
        );
      },
    );
  }

  // ------------- BUILD -------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: _loadUserInfo,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              _buildUserInfo(),
              const SizedBox(height: 12),
              _buildPostGrid(),
            ],
          ),
        ),
      ),
    );
  }
}
