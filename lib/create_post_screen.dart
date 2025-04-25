import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

/// CreatePostScreen – kullanıcının seçtiği görseli yükler ve Firestore'da
/// "username" alanını **nickname** olarak kaydeder.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController descriptionController = TextEditingController();
  File? selectedMedia;
  bool isLoading = false;

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => selectedMedia = File(picked.path));
  }

  Future<String> _uploadToStorage(File file, String uid, String postId) async {
    final ref = FirebaseStorage.instance.ref('posts/$uid/$postId.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<void> _uploadPost() async {
    if (selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),);
      return;
    }
    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Kullanıcının kayıtlı NICKNAME'ini al
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      final nickname = userDoc['username'] ?? user.email;

      final postId   = const Uuid().v4();
      final mediaUrl = await _uploadToStorage(selectedMedia!, user.uid, postId);

      await FirebaseFirestore.instance.collection('posts').doc(postId).set({
        'postId'     : postId,
        'userId'     : user.uid,
        'username'   : nickname,                          // <-- nickname
        'description': descriptionController.text.trim(),
        'mediaUrl'   : mediaUrl,
        'timestamp'  : FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post shared successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing post: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (selectedMedia != null)
                    Image.file(selectedMedia!, height: 200, fit: BoxFit.cover),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: _pickMedia, child: const Text('Select Image')),
                  const SizedBox(height: 20),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Add a description (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: _uploadPost, child: const Text('Share Post')),
                ],
              ),
            ),
    );
  }
}
