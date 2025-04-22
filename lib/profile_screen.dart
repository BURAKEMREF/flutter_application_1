import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';
import 'story_viewer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  String? username;
  String? profileImageUrl;
  List<Map<String, dynamic>> oldStories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadOldStories();
  }

  Future<void> _loadProfile() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        username = data['username'];
        profileImageUrl = data['profileImageUrl'];
      });
    }
  }

  Future<void> _loadOldStories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('stories')
        .doc(user!.uid)
        .collection('storyList')
        .orderBy('timestamp', descending: true)
        .get();

    final cutoff = DateTime.now().subtract(const Duration(hours: 24));

    final expired = snapshot.docs
        .where((doc) {
          final ts = (doc['timestamp'] as Timestamp?)?.toDate();
          return ts != null && ts.isBefore(cutoff);
        })
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    setState(() {
      oldStories = expired;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
                            ? (Uri.tryParse(profileImageUrl!)?.isAbsolute == true
                                ? NetworkImage(profileImageUrl!)
                                : FileImage(File(profileImageUrl!))) as ImageProvider
                            : const AssetImage('assets/default_profile.png'),
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username ?? 'Unknown',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EditProfileScreen(),
                                ),
                              ).then((_) => _loadProfile());
                            },
                            child: const Text('Edit Profile'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),

                  // Geçmiş Story'ler (24h'den eski)
                  if (oldStories.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Your Past Stories (24h+)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: oldStories.length,
                        itemBuilder: (context, index) {
                          final story = oldStories[index];
                          final url = story['mediaUrl'] ?? '';

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                url,
                                width: 80,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.error, color: Colors.red),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                  ],

                  // Kullanıcının gönderileri
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .where('userId', isEqualTo: user!.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final posts = snapshot.data!.docs;

                      if (posts.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('You haven\'t shared any posts yet.'),
                        );
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index].data() as Map<String, dynamic>;
                          final mediaUrl = post['mediaUrl'] ?? '';

                          return mediaUrl.isNotEmpty
                              ? Image.network(
                                  mediaUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.error),
                                )
                              : const Icon(Icons.image_not_supported);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
