import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test3/screens/email/email_detail_screen.dart';
import 'package:test3/screens/search/search_filter.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InboxTab extends StatefulWidget {
  final SearchFilter filter;

  const InboxTab({Key? key, required this.filter}) : super(key: key);

  @override
  State<InboxTab> createState() => _InboxTabState();
}

class _InboxTabState extends State<InboxTab> {
  bool _hasShownNotification = false;

  Future<void> deleteEmail(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('emails').doc(docId).update({
        'folder': 'trash',
      });
    } catch (e) {
      throw Exception('Lỗi khi chuyển email vào thùng rác: $e');
    }
  }

  Future<String?> getUidFromEmail(String email) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return snap.docs.isEmpty ? null : snap.docs.first['uid'];
  }

  Future<int> _getLastEmailCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('lastEmailCount_${FirebaseAuth.instance.currentUser!.uid}') ?? 0;
  }

  Future<void> _setLastEmailCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastEmailCount_${FirebaseAuth.instance.currentUser!.uid}', count);
  }

  void _showNewEmailNotification(int newCount, int lastCount) {
    if (_hasShownNotification) return;
    if (newCount > 0) {
      Flushbar(
        message: 'Bạn có $newCount email trong hộp thư!',
        duration: const Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.TOP,
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.email, color: Colors.white),
        margin: const EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8),
      ).show(context);
      _hasShownNotification = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _hasShownNotification = false;
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

          if (!matchesUser) return false;

          final subject = (data['subject'] ?? '').toString().toLowerCase();
          final body = (data['body'] ?? '').toString().toLowerCase();
          final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
          final attachments = List<dynamic>.from(data['attachments'] ?? []);
          final labels = List<String>.from(data['labels'] ?? []);
          final fromUid = data['fromUid'] as String?;

          final filter = widget.filter;
          bool matchesFilter = true;

          if (filter.keyword.isNotEmpty) {
            final query = filter.keyword.toLowerCase();
            matchesFilter &= subject.contains(query) || body.contains(query);
          }

          if (filter.startDate != null && timestamp != null) {
            matchesFilter &= timestamp.isAfter(filter.startDate!);
          }

          if (filter.endDate != null && timestamp != null) {
            matchesFilter &= timestamp.isBefore(filter.endDate!.add(const Duration(days: 1)));
          }

          if (filter.hasAttachments != null) {
            matchesFilter &= filter.hasAttachments! ? attachments.isNotEmpty : attachments.isEmpty;
          }

          if (filter.senderEmail != null && fromUid != null) {
            matchesFilter &= fromUid == filter.senderEmail;
          }

          if (filter.labelIds.isNotEmpty) {
            matchesFilter &= filter.labelIds.every((labelId) => labels.contains(labelId));
          }

          return matchesFilter;
        }).toList();

        if (inbox.isEmpty) {
          return const Center(child: Text('Không tìm thấy email phù hợp.'));
        }

        // Check for new emails on first load
        Future.microtask(() async {
          final lastCount = await _getLastEmailCount();
          final newCount = inbox.length;
          _showNewEmailNotification(newCount, lastCount);
          await _setLastEmailCount(newCount);
        });

        return FutureBuilder<String?>(
          future: widget.filter.senderEmail != null ? getUidFromEmail(widget.filter.senderEmail!) : Future.value(null),
          builder: (context, senderSnapshot) {
            if (senderSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final senderUid = senderSnapshot.data;

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
      },
    );
  }
}