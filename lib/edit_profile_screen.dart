// edit_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _user = FirebaseAuth.instance.currentUser;
  final _nameCtrl = TextEditingController();
  final _univCtrl = TextEditingController();
  String? _photoUrl;
  File?   _newPhoto;
  bool    _saving = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final snap = await FirebaseFirestore.instance
        .collection('users').doc(_user!.uid).get();

    setState(() {
      _nameCtrl.text = snap['username'] ?? '';
      _univCtrl.text = snap['university'] ?? '';
      _photoUrl      = snap['profileImageUrl'] ?? '';
    });
  }

  // ------------------ IMAGE PICK & UPLOAD ------------------
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _newPhoto = File(picked.path));
  }

  Future<String?> _uploadPhoto(File file) async {
    final ref = FirebaseStorage.instance
        .ref('avatars/${_user!.uid}.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  // ------------------ SAVE ------------------
  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      String? url = _photoUrl;

      // Fotoğraf değiştiyse yükle
      if (_newPhoto != null) {
        url = await _uploadPhoto(_newPhoto!);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({
        'username'       : _nameCtrl.text.trim(),
        'university'     : _univCtrl.text.trim(),
        'profileImageUrl': url,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ------------------ UI ------------------
  @override
  Widget build(BuildContext context) {
    final avatar = _newPhoto != null
        ? FileImage(_newPhoto!)
        : (_photoUrl?.isNotEmpty ?? false)
            ? NetworkImage(_photoUrl!)
            : const AssetImage('assets/default_avatar.png') as ImageProvider;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(radius: 50, backgroundImage: avatar),
                    Positioned(
                      child: InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(20),
                        child: const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.edit, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _univCtrl,
                decoration: const InputDecoration(
                  labelText: 'University',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
