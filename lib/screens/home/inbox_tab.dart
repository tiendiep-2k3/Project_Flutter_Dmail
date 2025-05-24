import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test3/screens/email/email_detail_screen.dart';

class InboxTab extends StatelessWidget {
  const InboxTab({Key? key}) : super(key: key);

  Future<void> deleteEmail(String docId) async {
    await FirebaseFirestore.instance.collection('emails').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('emails')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Không có email nào."));
        }

        final allEmails = snapshot.data!.docs;

        // Lọc các email mà người dùng hiện tại là người nhận, CC hoặc BCC
        final inbox = allEmails.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          // Bỏ qua bản nháp
          if (data['isDraft'] == true) return false;

          final toUid = data['toUid'];
          final ccUids = List<String>.from(data['ccUids'] ?? []);
          final bccUids = List<String>.from(data['bccUids'] ?? []);

          return toUid == currentUid ||
              ccUids.contains(currentUid) ||
              bccUids.contains(currentUid);
        }).toList();

        if (inbox.isEmpty) {
          return const Center(child: Text("Không có email nào."));
        }

        return ListView.builder(
          itemCount: inbox.length,
          itemBuilder: (context, index) {
            final email = inbox[index];
            final data = email.data() as Map<String, dynamic>;

            final subject = data['subject'] ?? '(Không tiêu đề)';
            final body = data['body'] ?? '';
            final docId = email.id;
            final fromUid = data['fromUid'];
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

            return Dismissible(
              key: Key(docId),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (_) async {
                return await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Xóa email"),
                    content: const Text("Bạn có chắc muốn xóa email này?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Xóa")),
                    ],
                  ),
                );
              },
              onDismissed: (_) => deleteEmail(docId),
              child: ListTile(
                title: Text(subject),
                subtitle: Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
                leading: const Icon(Icons.email),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmailDetailScreen(
                        subject: subject,
                        body: body,
                        fromUid: fromUid,
                        timestamp: timestamp,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
