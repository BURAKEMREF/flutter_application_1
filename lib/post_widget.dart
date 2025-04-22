import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'other_profile_screen.dart';

class PostWidget extends StatefulWidget {
  final Map<String, dynamic> postData;
  final String postId;

  const PostWidget({Key? key, required this.postData, required this.postId}) : super(key: key);

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  final TextEditingController _commentController = TextEditingController();

  Future<void> likePost(String postOwnerId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    await FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
      'likes': FieldValue.arrayUnion([currentUserId])
    });

    if (postOwnerId != currentUserId) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(postOwnerId)
          .collection('userNotifications')
          .add({
        'type': 'like',
        'senderId': currentUserId,
        'postId': widget.postId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> addComment(String postOwnerId, String comment) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'userId': currentUserId,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (postOwnerId != currentUserId) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(postOwnerId)
          .collection('userNotifications')
          .add({
        'type': 'comment',
        'senderId': currentUserId,
        'postId': widget.postId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    _commentController.clear();
  }

  Widget buildCommentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final comments = snapshot.data!.docs;

        return ListView.builder(
          itemCount: comments.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final data = comments[index].data() as Map<String, dynamic>;
            final comment = data['comment'] ?? '';
            final userId = data['userId'] ?? '';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.comment, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text('$userId: $comment')),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String userId = widget.postData['userId'] ?? 'Unknown';
    final String username = widget.postData['username'] ?? 'Unknown';
    final String description = widget.postData['description'] ?? '';
    final String mediaUrl = widget.postData['mediaUrl'] ?? '';
    final String profileImageUrl = widget.postData['profileImageUrl'] ?? '';
    final int likeCount = (widget.postData['likes'] as List?)?.length ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profil alanı
          ListTile(
            leading: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OtherProfileScreen(userId: userId)),
                );
              },
              child: CircleAvatar(
                backgroundImage:
                    profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
                child: profileImageUrl.isEmpty ? const Icon(Icons.person) : null,
              ),
            ),
            title: Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.more_vert),
          ),

          // Medya
          mediaUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    mediaUrl,
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image, size: 100),
                  ),
                )
              : const Icon(Icons.image_not_supported, size: 100),

          // Beğeni ve yorum ikonları
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12, right: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () => likePost(userId),
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

          // Beğeni sayısı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$likeCount likes',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // Açıklama
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(description),
          ),

          // Yorum yazma kutusu
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_commentController.text.trim().isNotEmpty) {
                      addComment(userId, _commentController.text.trim());
                    }
                  },
                  child: const Text('Post'),
                ),
              ],
            ),
          ),

          buildCommentList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
