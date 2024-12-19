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
  bool isEmailVerified = false;
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

    isEmailVerified = user!.emailVerified;

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        username = doc.get('username');
        if (doc.data() is Map && (doc.data() as Map).containsKey('profileImageUrl')) {
          profileImageUrl = doc.get('profileImageUrl');
        }
      }
    } catch (e) {
      // hata durumunda burada yönetebilirsiniz
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _sendEmailVerification() async {
    if (user != null && !user!.emailVerified) {
      await user!.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent!')),
      );
    }
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
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: profileImageUrl != null
                          ? NetworkImage(profileImageUrl!)
                          : null,
                      child: profileImageUrl == null ? const Icon(Icons.person, size: 50) : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome${username != null ? ', $username' : ''}!',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    email,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),

                  if (!isEmailVerified) ...[
                    const Text(
                      'Your email is not verified.',
                      style: TextStyle(color: Colors.red),
                    ),
                    ElevatedButton(
                      onPressed: _sendEmailVerification,
                      child: const Text('Send Verification Email'),
                    ),
                  ],

                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      ).then((_) {
                        // geri dönünce profili yenile
                        _loadUserData();
                      });
                    },
                    child: const Text('Edit Profile'),
                  ),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                    child: const Text('Change Password'),
                  ),
                ],
              ),
            ),
    );
  }
}
