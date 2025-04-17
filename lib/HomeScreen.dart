import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';
import 'search_user_screen.dart';
import 'other_profile_screen.dart';
import 'match_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatelessWidget {
  final String? userEmail;

  const HomeScreen({Key? key, this.userEmail}) : super(key: key);

  Future<void> likePost(String postOwnerId, String postId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
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
        'postId': postId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> addComment(String postOwnerId, String postId, String comment) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
      'userId': currentUserId,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    });

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
        title: const Text(
          'Instagram',
          style: TextStyle(
            fontFamily: 'Billabong',
            fontSize: 32,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreatePostScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchUserScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.black),
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

                    final String userId = post['userId'] ?? 'Unknown User';
                    final String postId = posts[index].id;
                    final String profileImageUrl = post['profileImageUrl'] ?? '';
                    final String username = post['username'] ?? 'Unknown User';
                    final String description = post['description'] ?? '';
                    final String mediaUrl = post['mediaUrl'] ?? '';

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
                        mediaUrl.isNotEmpty
                            ? Image.network(
                                mediaUrl,
                                height: 300,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.broken_image, size: 100);
                                },
                              )
                            : const Icon(Icons.image_not_supported, size: 100),
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
                                addComment(userId, postId, 'Great photo!');
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
            icon: Icon(Icons.local_fire_department),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '',
          ),
        ],
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchUserScreen()),
            );
          }
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MatchScreen(currentUserId: user?.uid)),
            );
          }
          if (index == 3) {
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
