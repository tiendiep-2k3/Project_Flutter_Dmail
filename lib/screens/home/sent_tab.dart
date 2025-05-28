import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test3/screens/email/email_detail_screen.dart';
import 'package:test3/screens/search/search_filter.dart';

class SentTab extends StatelessWidget {
  final SearchFilter filter;

  const SentTab({Key? key, required this.filter}) : super(key: key);

  Future<void> deleteEmail(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('emails').doc(docId).update({
        'folder': 'trash',
      });
    } catch (err) {
      throw Exception('Lỗi khi chuyển email vào thùng rác: ${err.toString()}');
    }
  }

  Future<String> getEmailFromUid(String email) async {
    if (email == '') return 'Không rõ';
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(email).get();
      return snap.data()!['email'] ?? 'Không rõ email';
    } catch (err) {
      return 'Lỗi: Không thể lấy email';
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách email đã gửi')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('emails')
            .where('email', isEqualTo: email)
            .where('isDraft', isEqualTo: false)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi truy xuất dữ liệu: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Không có email nào được gửi.'));
          }

          final sentEmails = snapshot.data!.docs.filter((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['folder'] == 'trash') return false;

            final subject = (data['subject'] ?? '').toString().toLowerCase();
            final body = (data['body'] ?? '').toString().toLowerCase();
            final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
            final attachments = List<dynamic>.from(data['attachments'] ?? []);
            final labels = List<String>.from(data['labels'] ?? []);

            bool matchesFilter = true;

            if (filter.keyword.isNotEmpty) {
              final query = filter.keyword.toLowerCase();
              matchesFilter &= subject.contains(query) || body.contains(query);
            }

            if (filter.startDate != null && timestamp != null) {
              matchesFilter &= timestamp.isAfter(filter.startDate!);
            }

            if (filter.endDate != null && timestamp != null) {
              matchesFilter &= timestamp.isBefore(filter.endDate!.add(Duration(days: 1)));
            }

            if (filter.hasAttachments != null) {
              matchesFilter &= filter.hasAttachments! ? attachments.isNotEmpty : attachments.isEmpty;
            }

            if (filter.labelIds.isNotEmpty) {
              matchesFilter &= filter.labelIds.every((labelId) => labels.contains(labelId));
            }

            return matchesFilter;
          }).toList();

          if (sentEmails.isEmpty) {
            return const Center(child: Text('Không tìm thấy email nào phù hợp.'));
          }

          return ListView.builder(
            itemCount: sentEmails.length,
            itemBuilder: (context, index) {
              final email = sentEmails[index];
              final data = email.data() as Map<String, dynamic>;

              final subject = data['subject'] ?? '(Không có tiêu đề)';
              final body = data['body'] ?? '';
              final docId = email.id;
              final toUid = data['toUid'] as String?;
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
              final isStarred = data['isStarred'] ?? false;

              return Dismissible(
                key: Key(docId),
                direction: DismissDirection.startToEnd,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Xóa email'),
                      content: const Text('Bạn có chắc chắn muốn xóa email này không?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Ok'),
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
                  } catch (err) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: ${err.toString()}')),
                    );
                  }
                },
                child: ListTile(
                  title: Text(
                    subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Colors.blue,
                    ),
                  ),
                  subtitle: FutureBuilder<String>(
                    future: getEmailFromUid(toUid ?? ''),
                    builder: (context, snapshot) {
                      final recipient = snapshot.connectionState == ConnectionState.done
                          ? snapshot.data ?? 'Không rõ ràng'
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
                    color: isStarred ? Colors.yellow : null,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmailDetailScreen(
                          subject: subject,
                          body: body,
                          fromUid: email,
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