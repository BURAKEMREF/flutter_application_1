import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> _searchRes = [];

  // ---------------- helpers ----------------
  String _chatId(String a, String b) => ([a, b]..sort()).join('_');

  Future<List<Map<String, dynamic>>> _searchFollowing(String q) async {
    final follow = await FirebaseFirestore.instance
        .collection('following').doc(_uid).collection('followingList').get();
    final ids = follow.docs.map((d) => d.id).toList();
    if (ids.isEmpty) return [];
    final users = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: ids)
        .get();
    return users.docs
        .map((d) => d.data()..['userId'] = d.id)
        .where((u) => (u['username'] as String?)?.toLowerCase().contains(q.toLowerCase()) ?? false)
        .toList();
  }

  Future<void> _startChat(Map<String, dynamic> other) async {
    final otherId = other['userId'] as String;
    final cid     = _chatId(_uid, otherId);
    final cref    = FirebaseFirestore.instance.collection('chats').doc(cid);
    if (!(await cref.get()).exists) {
      await cref.set({
        'participants'   : [_uid, otherId],
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }
    final odoc = await FirebaseFirestore.instance.collection('users').doc(otherId).get();
    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
      chatId: cid,
      otherUserId: otherId,
      otherUsername: odoc['username'] ?? 'Unknown',
      otherUserProfileUrl: odoc['profileImageUrl'] ?? '',
    )));
  }

  void _showSearchSheet() {
    _searchFollowing('').then((r) => setState(() => _searchRes = r));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SearchSheet(
        fetch: _searchFollowing,
        onSelect: _startChat,
        initial: _searchRes,
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      floatingActionButton: FloatingActionButton(onPressed: _showSearchSheet, child: const Icon(Icons.chat)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: _uid)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Hata: ${snap.error}'));
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Sohbet başlatılmadı. + butonuna dokun.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (c, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final otherId = (data['participants'] as List).firstWhere((id) => id != _uid);
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherId).get(),
                builder: (c, usnap) {
                  if (!usnap.hasData) return const ListTile(title: Text('…'));
                  final u = usnap.data!.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (u['profileImageUrl'] ?? '').isNotEmpty ? NetworkImage(u['profileImageUrl']) : null,
                      child: (u['profileImageUrl'] ?? '').isEmpty ? const Icon(Icons.person) : null,
                    ),
                    title: Text(u['username'] ?? 'Unknown'),
                    onTap: () => _startChat({ ...u, 'userId': otherId }),
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

// ---------------- Search Sheet widget ----------------
class _SearchSheet extends StatefulWidget {
  const _SearchSheet({required this.fetch, required this.onSelect, required this.initial});
  final Future<List<Map<String, dynamic>>> Function(String) fetch;
  final void Function(Map<String, dynamic>) onSelect;
  final List<Map<String, dynamic>> initial;
  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  late List<Map<String, dynamic>> _res = widget.initial;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16, left: 16, right: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(hintText: 'Search followed users', prefixIcon: Icon(Icons.search)),
            onChanged: (v) {
              widget.fetch(v).then((r) => setState(() => _res = r));
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: _res.isEmpty
                ? const Center(child: Text('No users'))
                : ListView.builder(
                    itemCount: _res.length,
                    itemBuilder: (_, i) {
                      final u = _res[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: (u['profileImageUrl'] ?? '').isNotEmpty ? NetworkImage(u['profileImageUrl']) : null,
                          child: (u['profileImageUrl'] ?? '').isEmpty ? const Icon(Icons.person) : null,
                        ),
                        title: Text(u['username'] ?? 'Unknown'),
                        onTap: () => widget.onSelect(u),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
