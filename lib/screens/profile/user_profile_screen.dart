import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _userFuture = FirebaseFirestore.instance.collection('users').doc(uid).get();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin người dùng')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Không tìm thấy dữ liệu người dùng.'));
          }

          final data = snapshot.data!.data()!;
          final displayName = data['displayName'] ?? 'Không có tên';
          final phone = data['phone'] ?? 'Không có số điện thoại';
          final photoUrl = data['photoUrl'];

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: photoUrl != null && photoUrl != ''
                        ? NetworkImage(photoUrl)
                        : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                  ),
                ),
                const SizedBox(height: 24),
                Text('👤 Họ tên: $displayName', style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 12),
                Text('📱 Số điện thoại: $phone', style: const TextStyle(fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );
  }
}
