import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({Key? key}) : super(key: key);

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  File? selectedMedia;
  bool isLoading = false;

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedMedia = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadStory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || selectedMedia == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final storyId = const Uuid().v4();
      final ref = FirebaseStorage.instance
          .ref()
          .child('stories')
          .child(user.uid)
          .child('$storyId.jpg');

      await ref.putFile(selectedMedia!);
      final mediaUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('stories')
          .doc(user.uid)
          .collection('storyList')
          .doc(storyId)
          .set({
        'mediaUrl': mediaUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story uploaded!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Story')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (selectedMedia != null)
                    Image.file(selectedMedia!, height: 300, fit: BoxFit.cover),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _pickMedia,
                    child: const Text('Select Media'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _uploadStory,
                    child: const Text('Upload Story'),
                  ),
                ],
              ),
            ),
    );
  }
}
