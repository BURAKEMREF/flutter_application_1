import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';

class StoryViewer extends StatefulWidget {
  final String userId;
  const StoryViewer({Key? key, required this.userId}) : super(key: key);

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> {
  int currentIndex = 0;
  List<Map<String, dynamic>> stories = [];
  VideoPlayerController? _videoController;
  Timer? _autoNextTimer;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _autoNextTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStories() async {
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(hours: 24)),
    );

    final snapshot = await FirebaseFirestore.instance
        .collection('stories')
        .doc(widget.userId)
        .collection('storyList')
        .orderBy('timestamp')
        .get();

    final validStories = snapshot.docs
        .where((doc) {
          final data = doc.data();
          final timestamp = data['timestamp'] as Timestamp?;
          return timestamp != null && timestamp.compareTo(cutoff) > 0;
        })
        .map((doc) => {...doc.data(), 'id': doc.id})
        .toList();

    if (validStories.isNotEmpty) {
      setState(() {
        stories = validStories;
      });
      _initializeStory();
    }
  }

  void _initializeStory() {
    _autoNextTimer?.cancel();
    _videoController?.dispose();

    final story = stories[currentIndex];
    final url = story['mediaUrl'] as String;
    final isVideo = url.endsWith('.mp4');

    if (isVideo) {
      _videoController = VideoPlayerController.network(url)
        ..initialize().then((_) {
          setState(() {});
          _videoController?.play();
          _autoNextTimer = Timer(_videoController!.value.duration, _nextStory);
        });
    } else {
      _autoNextTimer = Timer(const Duration(seconds: 5), _nextStory);
    }
  }

  void _nextStory() {
    if (currentIndex < stories.length - 1) {
      setState(() {
        currentIndex++;
      });
      _initializeStory();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _deleteCurrentStory() async {
    final storyId = stories[currentIndex]['id'];
    await FirebaseFirestore.instance
        .collection('stories')
        .doc(widget.userId)
        .collection('storyList')
        .doc(storyId)
        .delete();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentStory = stories[currentIndex];
    final url = currentStory['mediaUrl'] as String;
    final isVideo = url.endsWith('.mp4');

    return GestureDetector(
      onTap: _nextStory,
      onLongPress: () async {
        final confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete this story?'),
            content: const Text('Are you sure you want to delete this story?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
        );
        if (confirm == true) {
          await _deleteCurrentStory();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: isVideo
                  ? (_videoController != null && _videoController!.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        )
                      : const CircularProgressIndicator())
                  : Image.network(
                      url,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 100, color: Colors.white),
                    ),
            ),
            Positioned(
              top: 50,
              left: 20,
              child: Text(
                '${currentIndex + 1}/${stories.length}',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            if (currentStory['text'] != null && currentStory['text'].toString().isNotEmpty)
              Positioned(
                bottom: 60,
                left: 20,
                right: 20,
                child: Text(
                  currentStory['text'],
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
