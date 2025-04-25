import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoryBar extends StatelessWidget {
  const StoryBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: StreamBuilder<QuerySnapshot>(
        // “latest” alanına göre sırala – kendiniz de dâhil
        stream: FirebaseFirestore.instance
            .collection('stories')
            .orderBy('latest', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No stories yet'));
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final userId = docs[i].id;

              // *** Her kullanıcı için profil & nick çek ***
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(userId)
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircleAvatar(radius: 28),
                    );
                  }

                  final uData  = userSnap.data!.data() as Map<String, dynamic>;
                  final avatar = uData['profileImageUrl'] ?? '';
                  final nick   = uData['username']        ?? userId.substring(0, 5);

                  return GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/storyViewer',
                          arguments: userId); // mevcut StoryViewer yolunuz
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.blue,
                            backgroundImage:
                                avatar.isNotEmpty ? NetworkImage(avatar) : null,
                            child: avatar.isEmpty
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 68,
                            child: Text(
                              nick,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
