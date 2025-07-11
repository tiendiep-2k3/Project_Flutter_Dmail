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
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Thùng rác', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
              final subject = email['subject'] ?? '(Không tiêu đề)';
              final body = email['body'] ?? '';
              final timestamp = (email['timestamp'] as Timestamp?)?.toDate();

              String formattedTime = '';
              if (timestamp != null) {
                final now = DateTime.now();
                if (now.difference(timestamp).inDays == 0) {
                  formattedTime = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
                } else {
                  formattedTime = '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}';
                }
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Card(
                  elevation: 2,
                  color: Colors.deepPurple[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFFFCDD2),
                            child: Icon(Icons.delete, color: Colors.red),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        subject,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (formattedTime.isNotEmpty)
                                      Text(
                                        formattedTime,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  body,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
