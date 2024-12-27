import 'dart:io'; // File sınıfını kullanabilmek için eklendi
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';
import 'search_user_screen.dart'; // Arama ekranı dosyasını ekledik
import 'other_profile_screen.dart'; // Diğer profil ekranını ekledik
import 'match_screen.dart'; // Tinder benzeri eşleşme ekranını ekledik
import 'notifications_screen.dart'; // Bildirim ekranını ekledik

class HomeScreen extends StatelessWidget {
  final String? userEmail;

  const HomeScreen({Key? key, this.userEmail}) : super(key: key);

  Future<void> likePost(String postOwnerId, String postId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Beğenme işlemi
    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'likes': FieldValue.arrayUnion([currentUserId])
    });

    // Bildirim gönderme
    if (postOwnerId != currentUserId) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(postOwnerId)
          .collection('userNotifications')
          .add({
        'type': 'like',
        'senderId': currentUserId,
        'postId': postId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> addComment(String postOwnerId, String postId, String comment) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Yorum ekleme işlemi
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
      'userId': currentUserId,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Bildirim gönderme
    if (postOwnerId != currentUserId) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(postOwnerId)
          .collection('userNotifications')
          .add({
        'type': 'comment',
        'senderId': currentUserId,
        'postId': postId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Instagram',
          style: TextStyle(
            fontFamily: 'Billabong', // Instagram tarzı font kullanabilirsiniz
            fontSize: 32,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_box_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreatePostScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.favorite_border, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.search, color: Colors.black), // Arama butonu
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchUserScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.person, color: Colors.black), // Profil bağlantısı
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Gönderiler Bölümü
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
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
                    final post = posts[index].data() as Map<String, dynamic>;

                    // Null kontrolü ve varsayılan değerler
                    final String userId = post['userId'] ?? '';
                    final String postId = post['postId'] ?? '';
                    final String profileImageUrl = post['profileImageUrl'] ?? '';
                    final String username = post['username'] ?? 'Unknown User';
                    final String description = post['description'] ?? '';
                    final String mediaPath = post['mediaPath'] ?? '';

                    if (userId.isEmpty || postId.isEmpty) {
                      return const SizedBox.shrink(); // Geçersiz veriyi atla
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OtherProfileScreen(userId: userId),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              backgroundImage: profileImageUrl.isNotEmpty
                                  ? NetworkImage(profileImageUrl)
                                  : null,
                              child: profileImageUrl.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                          ),
                          title: Text(username),
                          trailing: const Icon(Icons.more_vert),
                        ),
                        // Gönderi Görseli
                        mediaPath.isNotEmpty
                            ? Image.file(
                                File(mediaPath),
                                height: 300,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : const SizedBox.shrink(),
                        // Etkileşim Butonları
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.favorite_border),
                              onPressed: () {
                                likePost(userId, postId);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.comment_outlined),
                              onPressed: () {
                                addComment(userId, postId, 'Sample Comment');
                              },
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.bookmark_border),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(description),
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department), // Tinder eşleşme ikonu
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined), // Market sekmesi kaldırıldı
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '', // Profil sekmesi
          ),
        ],
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) { // Arama sekmesi
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchUserScreen()),
            );
          }
          if (index == 2) { // Eşleşme sekmesi
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MatchScreen(currentUserId: user?.uid)),
            );
          }
          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          }
        },
      ),
    );
  }
}
