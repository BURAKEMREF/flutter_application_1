import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'homescreen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController    = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  String selectedUniversity = '';

  final List<String> universities = [
    'Hacettepe Üniversitesi',
    'Boğaziçi Üniversitesi',
    'İstanbul Teknik Üniversitesi',
    'Orta Doğu Teknik Üniversitesi',
    'Ankara Üniversitesi',
    'İstanbul Üniversitesi',
    'Ege Üniversitesi',
    'Sabancı Üniversitesi',
    'Yıldız Teknik Üniversitesi',
    'Gazi Üniversitesi',
    'Koç Üniversitesi',
    'Marmara Üniversitesi',
    'İzmir Katip Çelebi Üniversitesi',
    'Atatürk Üniversitesi',
    'İstanbul Medeniyet Üniversitesi',
  ];

  Future<void> register() async {
    try {
      final uname = usernameController.text.trim();
      final mail  = emailController.text.trim();
      final pass  = passwordController.text.trim();

      if (uname.isEmpty || mail.isEmpty || pass.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All fields are required')),);
        return;
      }

      // 1️⃣  Kullanıcı adı benzersiz mi?
      final exists = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: uname)
          .limit(1)
          .get();

      if (exists.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username already taken')),
        );
        return;
      }

      // 2️⃣  Firebase Auth
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: mail,
        password: pass,
      );

      // 3️⃣  Firestore profil kaydı
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'userId'         : cred.user!.uid,
        'email'          : cred.user!.email,
        'username'       : uname,
        'profileImageUrl': '',
        'university'     : selectedUniversity,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButton<String>(
                  value: selectedUniversity.isEmpty ? null : selectedUniversity,
                  hint: const Text('Select University'),
                  onChanged: (val) => setState(() => selectedUniversity = val ?? ''),
                  items: universities.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: register, child: const Text('Register')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
