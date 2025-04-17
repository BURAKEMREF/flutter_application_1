import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController usernameController = TextEditingController();
  String? profileImageUrl;
  File? localImageFile;
  bool isLoading = true;
  bool isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _initializeUserDocument();
  }

  Future<void> _initializeUserDocument() async {
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user!.uid);

      final docSnapshot = await userDoc.get();
      if (!docSnapshot.exists) {
        await userDoc.set({
          'username': user!.email!.split('@')[0],
          'profileImageUrl': '',
          'email': user!.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await _loadCurrentData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing user data: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadCurrentData() async {
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        usernameController.text = data['username'] ?? '';
        profileImageUrl = data['profileImageUrl'];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _pickAndUpdateProfileImage() async {
    if (isPickingImage) return;

    setState(() => isPickingImage = true);

    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected.')),
        );
        return;
      }

      final file = File(pickedFile.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images/${user!.uid}.jpg');

      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      setState(() {
        localImageFile = file;
        profileImageUrl = downloadUrl;
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'profileImageUrl': downloadUrl});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile image: $e')),
      );
    } finally {
      setState(() => isPickingImage = false);
    }
  }

  Future<void> _saveChanges() async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
        'username': usernameController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving changes: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: localImageFile != null
                          ? FileImage(localImageFile!)
                          : (profileImageUrl != null && profileImageUrl!.isNotEmpty
                              ? NetworkImage(profileImageUrl!) as ImageProvider
                              : null),
                      child: localImageFile == null &&
                              (profileImageUrl == null || profileImageUrl!.isEmpty)
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _pickAndUpdateProfileImage,
                      child: const Text('Change Profile Image'),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveChanges,
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
