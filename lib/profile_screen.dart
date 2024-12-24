import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  String? username;
  String? profileImageUrl;
  int postCount = 0;
  int followersCount = 0;
  int followingCount = 0;
  bool isFollowing = false;
  bool isEmailVerified = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFollowData();
  }

  Future<void> _loadUserData() async {
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    isEmailVerified = user!.emailVerified;

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        username = doc.get('username');
        profileImageUrl = doc.get('profileImageUrl');
        postCount = doc.get('postCount') ?? 0;
      }
    } catch (e) {
      // Hata durumunda
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _loadFollowData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('followers')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        followersCount = doc.get('count') ?? 0;
        isFollowing = doc.get('isFollowing') ?? false;
      }

      DocumentSnapshot followingDoc = await FirebaseFirestore.instance
          .collection('following')
          .doc(user!.uid)
          .get();

      if (followingDoc.exists) {
        followingCount = followingDoc.get('count') ?? 0;
      }
    } catch (e) {
      // Hata durumunda
    }

    setState(() {});
  }

  Future<void> _toggleFollow() async {
    setState(() {
      isFollowing = !isFollowing;
    });

    try {
      final docRef = FirebaseFirestore.instance
          .collection('followers')
          .doc(user!.uid);

      if (isFollowing) {
        followersCount++;
        await docRef.set({'count': followersCount, 'isFollowing': true});
      } else {
        followersCount--;
        await docRef.set({'count': followersCount, 'isFollowing': false});
      }
    } catch (e) {
      // Hata durumunda
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final email = user?.email ?? 'No Email Found';

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
                  // Profil Bilgileri
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: profileImageUrl != null
                              ? NetworkImage(profileImageUrl!)
                              : null,
                          child: profileImageUrl == null
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatColumn(postCount.toString(), 'Posts'),
                                  _buildStatColumn(followersCount.toString(), 'Followers'),
                                  _buildStatColumn(followingCount.toString(), 'Following'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const EditProfileScreen(),
                                    ),
                                  ).then((_) {
                                    _loadUserData();
                                  });
                                },
                                child: const Text('Edit Profile'),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _toggleFollow,
                                child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Gönderiler
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .where('userId', isEqualTo: user?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      final posts = snapshot.data!.docs;

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
                          return Image.network(
                            post['mediaUrl'] ?? '',
                            fit: BoxFit.cover,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
