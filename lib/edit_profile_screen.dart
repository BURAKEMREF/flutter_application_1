import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController universityController = TextEditingController();
  String? profileImageUrl;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // Kullanıcı profilini Firestore'dan al
  Future<void> _fetchUserProfile() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
    if (userDoc.exists) {
      setState(() {
        usernameController.text = userDoc['username'];
        universityController.text = userDoc['university'];
        profileImageUrl = userDoc['profileImageUrl'];
      });
    }
  }

  // Profili güncelle
  Future<void> _updateProfile() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
        'username': usernameController.text.trim(),
        'university': universityController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      Navigator.pop(context); // Geri dön
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl!)
                  : const AssetImage('assets/default-profile.png') as ImageProvider,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: universityController,
              decoration: const InputDecoration(labelText: 'University'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProfile,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
