import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_apis_test/login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up Screen'),
      ),
      body: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
            ),
          ),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
            ),
          ),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final String email = _emailController.text;
              final String password = _passwordController.text;
              UserCredential userCredential =
                  await FirebaseAuth.instance.createUserWithEmailAndPassword(
                email: email,
                password: password,
              );
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userCredential.user!.uid)
                  .set({
                'uid': userCredential.user!.uid,
                'email': email,
                'name': _nameController.text,
              });
              if (userCredential.user != null && context.mounted) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false);
              }
            },
            child: const Text('Sign Up'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false);
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}
