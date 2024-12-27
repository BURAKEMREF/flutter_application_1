import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtherProfileScreen extends StatefulWidget {
  final String userId;

  const OtherProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<OtherProfileScreen> createState() => _OtherProfileScreenState();
}

class _OtherProfileScreenState extends State<OtherProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String? username;
  String? profileImageUrl;
  int postCount = 0;
  int followersCount = 0;
  int followingCount = 0;
  bool isFollowing = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkIfFollowing();
  }

  Future<void> _loadUserProfile() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
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
        SnackBar(content: Text('Error loading user profile: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _checkIfFollowing() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('followers')
          .doc(widget.userId)
          .collection('followersList')
          .doc(currentUser?.uid)
          .get();

      setState(() {
        isFollowing = doc.exists;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking following status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(username ?? 'Profile'),
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
                                  if (isFollowing) {
                                    // Unfollow logic
                                  } else {
                                    // Follow logic
                                  }
                                },
                                child: Text(isFollowing ? 'Unfollow' : 'Follow'),
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
                        .where('userId', isEqualTo: widget.userId)
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
