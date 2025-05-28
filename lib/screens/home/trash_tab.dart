import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../email/email_detail_screen.dart';

class TrashTab extends StatelessWidget {
  const TrashTab({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text('Thùng rác')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('emails')
            .where('folder', isEqualTo: 'trash')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: \\${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Không có dữ liệu.'));
          }

          // Lọc lại các email mà user là toUid, ccUids hoặc bccUids
          final allEmails = snapshot.data!.docs;
          final emails = allEmails.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final toUid = data['toUid'];
            final ccUids = List<String>.from(data['ccUids'] ?? []);
            final bccUids = List<String>.from(data['bccUids'] ?? []);
            return toUid == uid || ccUids.contains(uid) || bccUids.contains(uid);
          }).toList();

          if (emails.isEmpty) return const Center(child: Text('Không có email trong thùng rác'));

          return ListView.builder(
            itemCount: emails.length,
            itemBuilder: (context, index) {
              final email = emails[index].data() as Map<String, dynamic>;

              return ListTile(
                title: Text(email['subject'] ?? ''),
                subtitle: Text(email['body'] ?? ''),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmailDetailScreen(
                        subject: email['subject'],
                        body: email['body'],
                        fromUid: email['fromUid'],
                        toUid: email['toUid'],
                        ccUids: List<String>.from(email['ccUids'] ?? []),
                        bccUids: List<String>.from(email['bccUids'] ?? []),
                        timestamp: (email['timestamp'] as Timestamp?)?.toDate(),
                        attachments: email['attachments'],
                        docId: emails[index].id,
                        labelName: 'Thùng rác',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
