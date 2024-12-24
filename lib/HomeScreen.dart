import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_post_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  final String? userEmail;

  const HomeScreen({Key? key, this.userEmail}) : super(key: key);

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
              // Bildirimler ekranına yönlendirme
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
          // Hikayeler (Stories) Bölümü
          SizedBox(
            height: 100,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('stories').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final stories = snapshot.data!.docs;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: stories.length,
                  itemBuilder: (context, index) {
                    final story = stories[index].data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundImage: NetworkImage(story['imageUrl']),
                          ),
                          SizedBox(height: 5),
                          Text(
                            story['username'],
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(thickness: 1, color: Colors.grey[300]),
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
                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index].data() as Map<String, dynamic>;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Gönderi Başlığı
                        ListTile(
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(post['profileImage']),
                          ),
                          title: Text(post['username']),
                          trailing: Icon(Icons.more_vert),
                        ),
                        // Gönderi Görseli
                        Image.network(
                          post['mediaUrl'],
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        // Etkileşim Butonları
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.favorite_border),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: Icon(Icons.comment_outlined),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: Icon(Icons.send),
                              onPressed: () {},
                            ),
                            Spacer(),
                            IconButton(
                              icon: Icon(Icons.bookmark_border),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(post['description'] ?? ''),
                        ),
                        SizedBox(height: 10),
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
            icon: Icon(Icons.movie_filter_outlined),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '', // Profil sekmesi
          ),
        ],
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
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
