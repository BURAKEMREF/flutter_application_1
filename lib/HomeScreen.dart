// --------------------------------------------------------------
//  HomeScreen.dart  –  Tek dosyada Instagram benzeri UI
// --------------------------------------------------------------
//  Bu sürüm, "Size" hatası ve const/non‑const uyuşmazlıklarını giderir.
//  - İmport'lar sade, dart:ui (Size) manuel eklendi.
//  - IgAppBar artık const değil → const anahtarını Scaffold'ta kaldırdık.
//  - _pages listesi const değil; her eleman uygun şekilde işaretlendi.
// --------------------------------------------------------------

import 'dart:ui';                       // Size sınıfı için
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'story_bar.dart';               // Projendeki mevcut dosyalar
import 'search_user_screen.dart';
import 'create_post_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'createstoryscreen.dart';   // Hikâye oluşturma
import 'chat_list_screen.dart';      // DM listesi

// ================= IG APP BAR =================
class IgAppBar extends StatelessWidget implements PreferredSizeWidget {
  IgAppBar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFFEEEEEE),
      centerTitle: true,
      title: const Text('Instagram',
          style: TextStyle(color: Colors.black, fontFamily: 'Billabong', fontSize: 32)),
      leading: IconButton(
        icon: const Icon(Icons.photo_camera_outlined, color: Colors.black),
        onPressed: () {
          // Kamera ikonuna basıldığında Story oluşturma ekranına git
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.live_tv_outlined, color: Colors.black),
          onPressed: () {
            // IGTV benzeri özellik henüz yok → basit uyarı göster
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Live feature coming soon!')),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.send_outlined, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatListScreen()),
            );
          },
        ),
      ],
    );
  }
}

// ================= IG BOTTOM NAV =================
class IgBottomNav extends StatelessWidget {
  const IgBottomNav({Key? key, required this.currentIndex, required this.onTap}) : super(key: key);

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      selectedItemColor: Colors.black,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined),     label: 'Feed'),
        BottomNavigationBarItem(icon: Icon(Icons.search),            label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Upload'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite_border),  label: 'Likes'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline),    label: 'Account'),
      ],
    );
  }
}

// ================= FEED VIEW =================
class FeedView extends StatelessWidget {
  const FeedView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const StoryBar(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final posts = snapshot.data!.docs;
              if (posts.isEmpty) {
                return const Center(child: Text('No posts yet.'));
              }

              return ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final data = posts[index].data() as Map<String, dynamic>;
                  return _PostCard(data: data, postId: posts[index].id);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({Key? key, required this.data, required this.postId}) : super(key: key);

  final Map<String, dynamic> data;
  final String postId;

  @override
  Widget build(BuildContext context) {
    final username  = data['username']         ?? 'Anon';
    final userImage = data['profileImageUrl']  ?? '';
    final postImage = data['mediaUrl']         ?? '';
    final caption   = data['description']      ?? '';

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: userImage.isNotEmpty ? NetworkImage(userImage) : null,
                  child: userImage.isEmpty ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 10),
                Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 1,
            child: postImage.isNotEmpty ? Image.network(postImage, fit: BoxFit.cover)
                                        : Container(color: Colors.grey[300]),
          ),
          Row(children: [
            IconButton(icon: const Icon(Icons.favorite_border),        onPressed: () {}),
            IconButton(icon: const Icon(Icons.mode_comment_outlined),  onPressed: () {}),
            IconButton(icon: const Icon(Icons.send_outlined),          onPressed: () {}),
            const Spacer(),
            IconButton(icon: const Icon(Icons.bookmark_border),        onPressed: () {}),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: RichText(
              text: TextSpan(style: const TextStyle(color: Colors.black), children: [
                TextSpan(text: username, style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: '  $caption'),
              ]),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ================= HOME SCREEN =================
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ValueNotifier<int> _navIndex = ValueNotifier<int>(0);

  /// Sayfa listesi – const anahtarları yalnızca mümkün olan yerlerde kullanıldı
  final List<Widget> _pages = [
    FeedView(),
    SearchUserScreen(),
    CreatePostScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  void _onNavTapped(int idx) {
    if (idx == 2) {
      _navIndex.value = idx; // Upload sekmesine ışınla
    } else {
      _navIndex.value = idx;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _navIndex,
      builder: (context, index, _) => Scaffold(
        backgroundColor: const Color(0xFFEEEEEE),
        appBar: IgAppBar(),                // const kaldırıldı (non‑const constructor)
        body: _pages[index],
        bottomNavigationBar: IgBottomNav(currentIndex: index, onTap: _onNavTapped),
      ),
    );
  }
}
