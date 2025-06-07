import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../email/email_detail_screen.dart';

class StarredTab extends StatelessWidget {
  const StarredTab({super.key});

  @override
  Widget build(BuildContext context) {
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login'); 
      });
      return const Scaffold(
        body: Center(child: Text('Vui lòng đăng nhập để xem email được gắn sao.')),
      );
    }

    final currentUid = user.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Được gắn sao', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('emails')
            .where('isStarred', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi truy vấn dữ liệu: ${snapshot.error}\nVui lòng kiểm tra quyền Firestore hoặc kết nối mạng.',
                textAlign: TextAlign.center,
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Không có email được gắn sao.'));
          }

          final allEmails = snapshot.data!.docs;
          final starredEmails = <QueryDocumentSnapshot>[];
          
          // Lọc email với xử lý lỗi nghiêm ngặt
          for (var doc in allEmails) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              // Kiểm tra các trường cần thiết
              final toUid = data['toUid'] as String?;
              final ccUids = data.containsKey('ccUids') && data['ccUids'] != null
                  ? List<String>.from(data['ccUids'])
                  : [];
              final bccUids = data.containsKey('bccUids') && data['bccUids'] != null
                  ? List<String>.from(data['bccUids'])
                  : [];
              final folder = data['folder'] as String?;

              if ((toUid == currentUid ||
                      ccUids.contains(currentUid) ||
                      bccUids.contains(currentUid)) &&
                  folder != 'trash') {
                starredEmails.add(doc);
              }
            } catch (e) {
              // Bỏ qua tài liệu không hợp lệ và ghi log lỗi
              debugPrint('Lỗi khi xử lý tài liệu email ${doc.id}: $e');
              continue;
            }
          }

          if (starredEmails.isEmpty) {
            return const Center(child: Text('Không có email được gắn sao.'));
          }

          return ListView.builder(
            itemCount: starredEmails.length,
            itemBuilder: (context, index) {
              final email = starredEmails[index].data() as Map<String, dynamic>;
              final subject = email['subject'] as String? ?? '(Không tiêu đề)';
              final body = email['body'] as String? ?? '';
              final docId = starredEmails[index].id;
              final fromUid = email['fromUid'] as String?;
              final timestamp = (email['timestamp'] as Timestamp?)?.toDate();
              final isRead = email['isRead'] ?? false;

              String formattedTime = '';
              if (timestamp != null) {
                final now = DateTime.now();
                if (now.difference(timestamp).inDays == 0) {
                  formattedTime = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
                } else {
                  formattedTime = '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}';
                }
              }

              if (fromUid == null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Card(
                    color: Colors.deepPurple[50],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: const Icon(Icons.star, color: Colors.amber),
                      title: Text(subject),
                      subtitle: const Text('Lỗi: Không xác định người gửi'),
                    ),
                  ),
                );
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
                      try {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EmailDetailScreen(
                              subject: subject,
                              body: body,
                              fromUid: fromUid,
                              toUid: email['toUid'] as String?,
                              ccUids: List<String>.from(email['ccUids'] ?? []),
                              bccUids: List<String>.from(email['bccUids'] ?? []),
                              timestamp: timestamp,
                              docId: docId,
                              labelName: 'Được gắn sao',
                            ),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi điều hướng đến chi tiết email: ${e.toString()}')),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFFFFF8E1),
                            child: Icon(Icons.star, color: Colors.amber),
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