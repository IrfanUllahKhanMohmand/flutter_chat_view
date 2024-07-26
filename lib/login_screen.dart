import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_apis_test/chat_list_screen.dart';
import 'package:google_apis_test/sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Screen'),
      ),
      body: Column(
        children: [
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
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                email: email,
                password: password,
              );
              if (userCredential.user != null && context.mounted) {
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ChatListScreen()),
                    (route) => false);
              }
            },
            child: const Text('Login'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpScreen()),
                  (route) => false);
            },
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }
}
