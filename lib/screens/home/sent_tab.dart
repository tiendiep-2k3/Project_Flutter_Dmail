import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test3/screens/email/email_detail_screen.dart';

class SentTab extends StatelessWidget {
  final String searchQuery;

  const SentTab({Key? key, this.searchQuery = ''}) : super(key: key);

  Future<void> deleteEmail(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('emails').doc(docId).update({
        'folder': 'trash',
      });
    } catch (e) {
      throw Exception('Lỗi khi chuyển email vào thùng rác: $e');
    }
  }

  Future<String> getEmailFromUid(String? uid) async {
    if (uid == null) return 'Không rõ';
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return snap.data()?['email'] ?? 'Không rõ';
    } catch (e) {
      return 'Lỗi: Không thể lấy email';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Đã gửi')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('emails')
            .where('fromUid', isEqualTo: currentUid)
            .where('isDraft', isEqualTo: false)
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
            return const Center(child: Text('Không có email đã gửi.'));
          }

          final sentEmails = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['folder'] == 'trash') return false;

            if (searchQuery.isEmpty) return true;

            final subject = (data['subject'] ?? '').toString().toLowerCase();
            final body = (data['body'] ?? '').toString().toLowerCase();
            final query = searchQuery.toLowerCase();

            return subject.contains(query) || body.contains(query);
          }).toList();

          if (sentEmails.isEmpty) {
            return const Center(child: Text('Không tìm thấy email phù hợp.'));
          }

          return ListView.builder(
            itemCount: sentEmails.length,
            itemBuilder: (context, index) {
              final email = sentEmails[index];
              final data = email.data() as Map<String, dynamic>;

              final subject = data['subject'] ?? '(Không tiêu đề)';
              final body = data['body'] ?? '';
              final docId = email.id;
              final toUid = data['toUid'] as String?;
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
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
                  return await showDialog<bool>(
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
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: FutureBuilder<String>(
                    future: getEmailFromUid(toUid),
                    builder: (context, emailSnapshot) {
                      final recipient = emailSnapshot.connectionState == ConnectionState.done
                          ? emailSnapshot.data ?? 'Không rõ'
                          : 'Đang tải...';
                      final displayText = body.isNotEmpty ? '$recipient: $body' : recipient;
                      return Text(
                        displayText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.black54,
                        ),
                      );
                    },
                  ),
                  leading: Icon(
                    isStarred ? Icons.star : Icons.send,
                    color: isStarred ? Colors.amber : null,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmailDetailScreen(
                          subject: subject,
                          body: body,
                          fromUid: currentUid,
                          toUid: toUid,
                          ccUids: List<String>.from(data['ccUids'] ?? []),
                          bccUids: List<String>.from(data['bccUids'] ?? []),
                          timestamp: timestamp,
                          docId: docId,
                          labelName: 'Đã gửi',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}