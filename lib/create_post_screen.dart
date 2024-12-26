import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    final pickedMedia = await picker.pickImage(source: ImageSource.gallery);

    if (pickedMedia != null) {
      setState(() {
        selectedMedia = File(pickedMedia.path);
      });
    }
  }

  Future<void> _uploadPost() async {
    if (selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image or video')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user?.uid,
        'username': user?.email,
        'description': descriptionController.text.trim(),
        'mediaPath': selectedMedia!.path,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post shared successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing post: $e')),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (selectedMedia != null)
                    Image.file(
                      selectedMedia!,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _pickMedia,
                    child: const Text('Select Image or Video'),
                  ),
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
                  ElevatedButton(
                    onPressed: _uploadPost,
                    child: const Text('Share Post'),
                  ),
                ],
              ),
            ),
    );
  }
}
