// chat_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUsername;          // ilk açılışta başlık boş kalmasın diye
  final String otherUserProfileUrl;    // (opsiyonel ön-ön-bellek)

  const ChatScreen({
    Key? key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUsername,
    required this.otherUserProfileUrl,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();

  Future<void> _send() async {
    final me = FirebaseAuth.instance.currentUser;
    if (me == null || _msgCtrl.text.trim().isEmpty) return;

    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

    await chatRef.collection('messages').add({
      'senderId' : me.uid,
      'text'     : _msgCtrl.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });

    await chatRef.update({'lastMessageTime': FieldValue.serverTimestamp()});
    _msgCtrl.clear();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ------------------------------------------------------------------
      // ❶ APP BAR : Diğer kullanıcının dokümanını canlı dinliyoruz
      // ------------------------------------------------------------------
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.otherUserId)
              .snapshots(),
          builder: (_, snap) {
            final data  = snap.data?.data() as Map<String, dynamic>? ?? {};
            final photo = data['profileImageUrl'] ?? widget.otherUserProfileUrl;
            final name  = data['username']        ?? widget.otherUsername;

            return Row(
              children: [
                CircleAvatar(
                  backgroundImage: (photo ?? '').isNotEmpty ? NetworkImage(photo) : null,
                  child: (photo ?? '').isEmpty ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 8),
                Text(name, overflow: TextOverflow.ellipsis),
              ],
            );
          },
        ),
      ),

      // ------------------------------------------------------------------
      body: Column(
        children: [
          // 🔴 Mesaj listesi
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (_, snap) {
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final msgs = snap.data!.docs;

                if (msgs.isEmpty) {
                  return const Center(child: Text('Henüz mesaj yok.'));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final m  = msgs[i].data() as Map<String, dynamic>;
                    final me = m['senderId'] == FirebaseAuth.instance.currentUser!.uid;

                    return Align(
                      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: me ? Colors.blueAccent : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          m['text'] ?? '',
                          style: TextStyle(color: me ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 🔵 Mesaj yaz / gönder
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Type a message…',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.send), onPressed: _send),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
