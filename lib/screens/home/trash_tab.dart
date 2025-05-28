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
            .where('toUid', isEqualTo: uid)
            .where('folder', isEqualTo: 'trash')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final emails = snapshot.data!.docs;

          if (emails.isEmpty) return Center(child: Text('Không có email trong thùng rác'));

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
