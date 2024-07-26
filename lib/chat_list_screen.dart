import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_apis_test/chat_screen.dart';
import 'package:google_apis_test/chat_view/chatview.dart';
import 'package:google_apis_test/data.dart';
import 'package:google_apis_test/profile_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  String getChatId(String id1, String id2) {
    final userIds = [id1, id2];
    userIds.sort();
    return userIds.join('_');
  }

  @override
  Widget build(BuildContext context) {
    QueryDocumentSnapshot<Object?>? currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat List Screen'),
        toolbarHeight: 80,
        actions: [
          InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()));
            },
            child: Column(
              children: [
                const CircleAvatar(
                  backgroundImage: NetworkImage(
                    Data.profileImage,
                  ),
                ),
                FutureBuilder(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .get(),
                  builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    final user = snapshot.data!.data() as Map<String, dynamic>;
                    return Column(
                      children: [
                        Text(user['name']),
                        Text(user['email']),
                      ],
                    );
                  },
                )
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          final users = snapshot.data!.docs;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              if (user['uid'] == FirebaseAuth.instance.currentUser!.uid) {
                currentUser = user;
                return const SizedBox();
              }
              return ListTile(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ChatScreen(
                              chatId: getChatId(
                                FirebaseAuth.instance.currentUser!.uid,
                                user['uid'],
                              ),
                              currentUser: ChatUser(
                                id: FirebaseAuth.instance.currentUser!.uid,
                                name: currentUser!['name'],
                                profilePhoto: Data.profileImage,
                              ),
                              otherUser: ChatUser(
                                id: user['uid'],
                                name: user['name'],
                                profilePhoto: Data.profileImage,
                              ))));
                },
                title: Text(user['name']),
                subtitle: Text(user['email']),
              );
            },
          );
        },
      ),
    );
  }
}
