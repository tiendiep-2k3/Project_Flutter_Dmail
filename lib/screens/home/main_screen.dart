import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test3/screens/email/compose_email_screen.dart';
import 'package:test3/screens/profile/profile_screen.dart';
import 'package:test3/screens/home/inbox_tab.dart';
import 'package:test3/screens/home/home_screen.dart'; 
import 'package:test3/screens/home/draft_tab.dart';


class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Text('Dmail Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.inbox),
              title: const Text('Hộp thư đến'),
              onTap: () => Navigator.pop(context),
            ),
             ListTile(
              leading: const Icon(Icons.drafts),
              title: const Text('Bản nháp'),
              onTap: () {
                Navigator.pop(context); // đóng drawer trước
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DraftTab()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Cài đặt'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Đăng xuất'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
            

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const TextField(
          decoration: InputDecoration(
            hintText: 'Search in mail',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white54),
          ),
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 18,
                backgroundImage:
                    AssetImage('assets/images/avatar1.webp'),
              ),
            ),
          )
        ],
      ),
      body: const InboxTab(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ComposeEmailScreen()),
          );
        },
        icon: const Icon(Icons.edit),
        label: const Text('Compose'),
      ),
    );
  }
}
