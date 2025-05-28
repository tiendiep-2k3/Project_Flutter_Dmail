import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test3/screens/email/email_detail_screen.dart';

class InboxTab extends StatelessWidget {
  final String searchQuery;

  const InboxTab({Key? key, this.searchQuery = ''}) : super(key: key);

  Future<void> deleteEmail(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('emails').doc(docId).update({
        'folder': 'trash',
      });
    } catch (e) {
      throw Exception('Lỗi khi chuyển email vào thùng rác: $e');
    }
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

        if (snapshot.hasError) {
          return Center(child: Text('Lỗi truy vấn dữ liệu: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Không có email nào.'));
        }

        final allEmails = snapshot.data!.docs;

        final inbox = allEmails.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          if (data['isDraft'] == true) return false;
          if (data['folder'] == 'trash') return false;

          final toUid = data['toUid'];
          final ccUids = List<String>.from(data['ccUids'] ?? []);
          final bccUids = List<String>.from(data['bccUids'] ?? []);

          final matchesUser = toUid == currentUid ||
              ccUids.contains(currentUid) ||
              bccUids.contains(currentUid);

          if (searchQuery.isEmpty) return matchesUser;

          final subject = (data['subject'] ?? '').toString().toLowerCase();
          final body = (data['body'] ?? '').toString().toLowerCase();
          final query = searchQuery.toLowerCase();

          return matchesUser && (subject.contains(query) || body.contains(query));
        }).toList();

        if (inbox.isEmpty) {
          return const Center(child: Text('Không tìm thấy email phù hợp.'));
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
            final isRead = data['isRead'] ?? false;
            final isStarred = data['isStarred'] ?? false;

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
                    title: const Text('Xóa email'),
                    content: const Text('Bạn có chắc muốn xóa email này?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Xóa'),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (_) async {
                try {
                  await deleteEmail(docId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email đã được chuyển vào thùng rác')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e')),
                  );
                }
              },
              child: ListTile(
                title: Text(
                  subject,
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    color: isRead ? Colors.black54 : Colors.black,
                  ),
                ),
                subtitle: Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    color: isRead ? Colors.black54 : Colors.black,
                  ),
                ),
                leading: Icon(
                  isStarred ? Icons.star : Icons.email,
                  color: isStarred ? Colors.amber : null,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmailDetailScreen(
                        subject: subject,
                        body: body,
                        fromUid: fromUid,
                        toUid: data['toUid'],
                        ccUids: List<String>.from(data['ccUids'] ?? []),
                        bccUids: List<String>.from(data['bccUids'] ?? []),
                        timestamp: timestamp,
                        docId: docId,
                        labelName: 'Hộp thư đến',
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