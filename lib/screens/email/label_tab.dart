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
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text('Nhãn: ${widget.labelName}', style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
              final isRead = email['isRead'] ?? false;
              final isStarred = email['isStarred'] ?? false;

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
                  elevation: isRead ? 1 : 4,
                  color: isRead ? Colors.white : Colors.deepPurple[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.deepPurple[100],
                            child: Icon(
                              isStarred ? Icons.star : Icons.email,
                              color: isStarred ? Colors.amber : Colors.deepPurple,
                            ),
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
                                        style: TextStyle(
                                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                          fontSize: 16,
                                          color: isRead ? Colors.black54 : Colors.black,
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
                                  style: TextStyle(
                                    color: isRead ? Colors.black54 : Colors.black87,
                                    fontSize: 14,
                                    fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
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