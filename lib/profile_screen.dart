import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';

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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          username = data['username'];
          profileImageUrl = data['profileImageUrl'];
          postCount = data['postCount'] ?? 0;
          followersCount = data['followersCount'] ?? 0;
          followingCount = data['followingCount'] ?? 0;
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile data: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
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
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
                              ? (Uri.tryParse(profileImageUrl!)?.isAbsolute == true
                                  ? NetworkImage(profileImageUrl!)
                                  : FileImage(File(profileImageUrl!))) as ImageProvider
                              : const AssetImage('assets/default_profile.png'),
                          child: profileImageUrl == null || profileImageUrl!.isEmpty
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
                                  ).then((_) => _loadUserData());
                                },
                                child: const Text('Edit Profile'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .where('userId', isEqualTo: user?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final posts = snapshot.data!.docs;

                      if (posts.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No posts yet!', style: TextStyle(fontSize: 16)),
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
                          final mediaPath = post['mediaPath'] ?? '';
                          try {
                            if (Uri.tryParse(mediaPath)?.isAbsolute == true) {
                              return Image.network(
                                mediaPath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint('Error loading network image: $error');
                                  return const Icon(Icons.error);
                                },
                              );
                            } else if (File(mediaPath).existsSync()) {
                              return Image.file(
                                File(mediaPath),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint('Error loading file image: $error');
                                  return const Icon(Icons.error);
                                },
                              );
                            } else {
                              return const Icon(Icons.error);
                            }
                          } catch (e) {
                            debugPrint('Error loading image: $e');
                            return const Icon(Icons.error);
                          }
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
