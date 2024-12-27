import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .doc(currentUserId)
            .collection('userNotifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications yet!'));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index].data() as Map<String, dynamic>;
              final type = notification['type'];
              final senderId = notification['senderId'];

              String message;
              if (type == 'like') {
                message = 'User $senderId liked your post.';
              } else if (type == 'comment') {
                message = 'User $senderId commented on your post.';
              } else if (type == 'match') {
                message = 'You matched with user $senderId.';
              } else {
                message = 'Unknown notification.';
              }

              return ListTile(
                leading: const Icon(Icons.notifications),
                title: Text(message),
                subtitle: Text(notification['timestamp'].toDate().toString()),
              );
            },
          );
        },
      ),
    );
  }
}
