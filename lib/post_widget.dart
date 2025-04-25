// post_widget.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'other_profile_screen.dart';

class PostWidget extends StatefulWidget {
  final String postId;                     // 🔑 yalnızca id veriyoruz
  const PostWidget({Key? key, required this.postId}) : super(key: key);

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  final _commentCtrl = TextEditingController();
  final _auth = FirebaseAuth.instance;

  Future<void> _toggleLike(
      {required String postOwnerId, required bool isLiked}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final ref =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    try {
      await ref.update({
        'likes': isLiked
            ? FieldValue.arrayRemove([uid])
            : FieldValue.arrayUnion([uid])
      });

      // like bildirimi (sadece beğenildiğinde)
      if (!isLiked && postOwnerId != uid) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(postOwnerId)
            .collection('userNotifications')
            .add({
          'type': 'like',
          'senderId': uid,
          'postId': widget.postId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('like error → $e');
    }
  }

  Future<void> _addComment(
      {required String postOwnerId, required String text}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'userId': uid,
        'comment': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (postOwnerId != uid) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(postOwnerId)
            .collection('userNotifications')
            .add({
          'type': 'comment',
          'senderId': uid,
          'postId': widget.postId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('comment error → $e');
    } finally {
      _commentCtrl.clear();
    }
  }

  /// Yorum listesi
  Widget _commentStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final docs = snap.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final comment = data['comment'] ?? '';
            final userId = data['userId'] ?? '';

            // Kullanıcı bilgisi
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
              builder: (ctx, uSnap) {
                if (!uSnap.hasData) return const SizedBox.shrink();
                final uData = uSnap.data!;
                final uname = uData['username'] ?? 'Unknown';
                final pUrl = uData['profileImageUrl'] ?? '';

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage:
                            pUrl.isNotEmpty ? NetworkImage(pUrl) : null,
                        child:
                            pUrl.isEmpty ? const Icon(Icons.person, size: 26) : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text('$uname: $comment')),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    // 🔴 Gönderiyi dinle (like, açıklama vs. gerçek-zamanlı yenilensin)
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snap.data!.data();
        if (data == null) return const SizedBox.shrink();

        final postOwner = data['userId'] as String? ?? '';
        final username = data['username'] as String? ?? 'Unknown';
        final desc = data['description'] as String? ?? '';
        final mediaUrl = data['mediaUrl'] as String? ?? '';
        final pImg = data['profileImageUrl'] as String? ?? '';
        final likes = (data['likes'] as List?) ?? [];
        final isLiked = uid != null && likes.contains(uid);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// ÜST – profil
              ListTile(
                leading: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => OtherProfileScreen(userId: postOwner)),
                    );
                  },
                  child: CircleAvatar(
                    backgroundImage:
                        pImg.isNotEmpty ? NetworkImage(pImg) : null,
                    child: pImg.isEmpty ? const Icon(Icons.person) : null,
                  ),
                ),
                title: Text(username,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.more_vert),
              ),

              /// GÖRSEL
              if (mediaUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    mediaUrl,
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, prog) =>
                        prog == null ? child : const LinearProgressIndicator(),
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image, size: 100),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Icon(Icons.image_not_supported, size: 80)),
                ),

              /// BEĞENİ & YORUM İKONLARI
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12, right: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : null,
                      ),
                      onPressed: () =>
                          _toggleLike(postOwnerId: postOwner, isLiked: isLiked),
                    ),
                    IconButton(
                      icon: const Icon(Icons.comment_outlined),
                      onPressed: () {},
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.bookmark_border),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              /// BEĞENİ SAYISI
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${likes.length} beğeni',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              /// AÇIKLAMA
              if (desc.isNotEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(desc),
                ),

              /// YORUM EKLE
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Yorum yaz...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final txt = _commentCtrl.text.trim();
                        if (txt.isNotEmpty) {
                          _addComment(postOwnerId: postOwner, text: txt);
                        }
                      },
                      child: const Text('Gönder'),
                    ),
                  ],
                ),
              ),

              /// YORUM LİSTESİ
              _commentStream(),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
