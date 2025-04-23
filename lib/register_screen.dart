import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'HomeScreen.dart'; // HomeScreen dosyanızın yolunu ekleyin

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  String selectedUniversity = '';  // Üniversiteyi tutmak için bir değişken

  // Türkiye'deki üniversiteler listesi (örnek olarak)
  List<String> universities = [
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
    "İstanbul Medeniyet Üniversitesi",
  ];

  Future<void> register() async {
    try {
      // Kullanıcıyı Firebase Auth ile oluşturuyoruz
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Kullanıcı Firestore'a kaydediliyor
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'userId': userCredential.user!.uid, // Kullanıcının UID'si kaydediliyor
        'email': userCredential.user!.email,
        'username': usernameController.text.trim(),
        'profileImageUrl': '', // Varsayılan profil resmi URL'si boş
        'university': selectedUniversity, // Üniversiteyi Firestore'a ekliyoruz
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration Successful!')),
      );

      // HomeScreen'e yönlendirme (isterseniz Login ekranına da dönebilirsiniz)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(userEmail: userCredential.user?.email),
        ),
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
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Username TextField
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
                // Üniversite seçmek için DropdownButton
                DropdownButton<String>(
                  value: selectedUniversity.isEmpty ? null : selectedUniversity,
                  hint: const Text('Select University'),
                  onChanged: (newValue) {
                    setState(() {
                      selectedUniversity = newValue!;
                    });
                  },
                  items: universities.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: register,
                  child: const Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
