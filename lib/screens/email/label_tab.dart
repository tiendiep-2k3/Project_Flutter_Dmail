import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test3/screens/email/email_detail_screen.dart';

class LabelTab extends StatefulWidget {
  final String labelId;
  final String labelName;
  const LabelTab({super.key, required this.labelId, required this.labelName});

  @override
  State<LabelTab> createState() => _LabelTabState();
}

class _LabelTabState extends State<LabelTab> {
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nhãn: ${widget.labelName}')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('emails')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allEmails = snapshot.data!.docs;
          final labeledEmails = allEmails.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final labels = List<String>.from(data['labels'] ?? []);
            final toUid = data['toUid'];
            final ccUids = List<String>.from(data['ccUids'] ?? []);
            final bccUids = List<String>.from(data['bccUids'] ?? []);

            return labels.contains(widget.labelId) &&
                (toUid == currentUid || ccUids.contains(currentUid) || bccUids.contains(currentUid)) &&
                data['folder'] != 'trash';
          }).toList();

          if (labeledEmails.isEmpty) {
            return const Center(child: Text('Không có email với nhãn này.'));
          }

          return ListView.builder(
            itemCount: labeledEmails.length,
            itemBuilder: (context, index) {
              final email = labeledEmails[index].data() as Map<String, dynamic>;
              final subject = email['subject'] ?? '(Không tiêu đề)';
              final body = email['body'] ?? '';
              final docId = labeledEmails[index].id;
              final fromUid = email['fromUid'];
              final timestamp = (email['timestamp'] as Timestamp?)?.toDate();

              return ListTile(
                title: Text(subject),
                subtitle: Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmailDetailScreen(
                        subject: subject,
                        body: body,
                        fromUid: fromUid,
                        toUid: email['toUid'],
                        ccUids: List<String>.from(email['ccUids'] ?? []),
                        bccUids: List<String>.from(email['bccUids'] ?? []),
                        timestamp: timestamp,
                        docId: docId,
                        labelName: widget.labelName,
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