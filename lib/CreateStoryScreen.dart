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
  File? _mediaFile;
  final TextEditingController _textController = TextEditingController();
  bool _isUploading = false;

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _mediaFile = File(picked.path));
  }

  // ---------------------------- updated ----------------------------
  Future<void> _uploadStory() async {
    if (_mediaFile == null) return;
    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final storyId = const Uuid().v4();
      final ref = FirebaseStorage.instance
          .ref()
          .child('stories')
          .child(user.uid)
          .child('$storyId.jpg');

      await ref.putFile(_mediaFile!);
      final mediaUrl = await ref.getDownloadURL();

      // alt-belge
      await FirebaseFirestore.instance
          .collection('stories')
          .doc(user.uid)
          .collection('storyList')
          .doc(storyId)
          .set({
        'mediaUrl' : mediaUrl,
        'text'     : _textController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 🔔 parent belgedeki latest alanını güncelle
      await FirebaseFirestore.instance
          .collection('stories')
          .doc(user.uid)
          .set({'latest': FieldValue.serverTimestamp()}, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story uploaded!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }
  // ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Story')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (_mediaFile != null)
                Image.file(_mediaFile!, height: 250, fit: BoxFit.cover),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickMedia,
                child: const Text('Select Media'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Text / Emoji (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadStory,
                child: _isUploading
                    ? const CircularProgressIndicator()
                    : const Text('Share Story'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
