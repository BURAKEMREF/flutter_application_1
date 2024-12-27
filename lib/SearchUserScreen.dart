import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({Key? key}) : super(key: key);

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];

  Future<void> _searchUsers(String query) async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    setState(() {
      searchResults = result.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Users'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search by username',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _searchUsers(value);
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final user = searchResults[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user['profileImageUrl'] != null
                          ? NetworkImage(user['profileImageUrl'])
                          : null,
                      child: user['profileImageUrl'] == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(user['username']),
                    trailing: ElevatedButton(
                      onPressed: () {
                        // Takip etme fonksiyonu burada çağrılacak
                      },
                      child: const Text('Follow'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
