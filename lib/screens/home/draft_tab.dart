import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test3/screens/email/email_detail_screen.dart';

class DraftTab extends StatelessWidget {
  const DraftTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Bản nháp")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('emails')
            .where('fromUid', isEqualTo: currentUid)
            .where('isDraft', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Không có bản nháp nào."));
          }

          final drafts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              final subject = draft['subject'] ?? '(Không tiêu đề)';
              final body = draft['body'] ?? '';
              final fromUid = draft['fromUid'] ?? 'Không rõ';
              final timestamp = (draft['timestamp'] as Timestamp?)?.toDate();

              return ListTile(
                title: Text(subject),
                subtitle: Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.drafts),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmailDetailScreen(
                        subject: subject,
                        body: body,
                        fromUid: fromUid,
                        timestamp: timestamp,
                        labelName: 'Bản nháp',
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
