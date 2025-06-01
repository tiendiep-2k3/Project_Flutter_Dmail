import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test3/screens/email/email_detail_screen.dart';
import 'package:test3/screens/search/search_filter.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InboxTab extends StatefulWidget {
  final SearchFilter filter; //F

  const InboxTab({Key? key, required this.filter}) : super(key: key);

  @override
  State<InboxTab> createState() => _InboxTabState();
}

class _InboxTabState extends State<InboxTab> {
  int _lastNotifiedCount = 0; // Thay đổi từ bool sang int để track số lượng email đã thông báo

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

  // Thêm function để lưu/lấy timestamp của lần thông báo cuối
  Future<int> _getLastNotificationTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('lastNotificationTime_${FirebaseAuth.instance.currentUser!.uid}') ?? 0;
  }

  Future<void> _setLastNotificationTime(int timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastNotificationTime_${FirebaseAuth.instance.currentUser!.uid}', timestamp);
  }

  // Thêm function để check notification settings
  Future<bool> _getNotificationSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      final data = doc.data();
      // Mặc định là true nếu không có setting
      return data?['notificationsEnabled'] ?? true;
    } catch (e) {
      print('Lỗi khi lấy cài đặt thông báo: $e');
      return true; // Mặc định là true nếu có lỗi
    }
  }

  void _showNewEmailNotification(int newCount, int lastCount) async {
    // Kiểm tra cài đặt thông báo của user
    final notificationsEnabled = await _getNotificationSettings();
    if (!notificationsEnabled) return;
    
    // Lấy thời gian thông báo cuối cùng
    final lastNotificationTime = await _getLastNotificationTime();
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    
    // Chỉ hiển thị thông báo nếu:
    // 1. Có email mới (newCount > lastCount)
    // 2. Chưa thông báo trong vòng 30 giây (tránh spam)
    // 3. Số lượng email mới lớn hơn số đã thông báo trước đó
    if (newCount > lastCount && 
        newCount > 0 && 
        (currentTime - lastNotificationTime) > 30000 && // 30 giây
        newCount > _lastNotifiedCount) {
      
      if (mounted) { // Kiểm tra widget còn mounted không
        final newEmailsCount = newCount - (lastCount > _lastNotifiedCount ? lastCount : _lastNotifiedCount);
        
        Flushbar(
          message: 'Bạn có $newEmailsCount email mới trong hộp thư!',
          duration: const Duration(seconds: 3),
          flushbarPosition: FlushbarPosition.TOP,
          backgroundColor: Colors.blue,
          icon: const Icon(Icons.email, color: Colors.white),
          margin: const EdgeInsets.all(8),
          borderRadius: BorderRadius.circular(8),
        ).show(context);
        
        // Cập nhật thời gian và số lượng đã thông báo
        await _setLastNotificationTime(currentTime);
        _lastNotifiedCount = newCount;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Khởi tạo _lastNotifiedCount từ SharedPreferences
    _initializeNotificationState();
  }

  Future<void> _initializeNotificationState() async {
    _lastNotifiedCount = await _getLastEmailCount();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    // Định nghĩa màu sắc theo theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF3B2C5E) : Colors.white;
    final unreadCardColor = isDarkMode ? const Color(0xFF4A3269) : Colors.deepPurple[50];
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subtitleColor = isDarkMode ? Colors.white70 : Colors.black54;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('emails')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.deepPurple),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Lỗi truy vấn dữ liệu: ${snapshot.error}',
              style: TextStyle(color: textColor),
            ),
          );
        } //

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Không có email nào.',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Không tìm thấy email phù hợp.',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        // Check for new emails với improved logic
        Future.microtask(() async {
          final lastCount = await _getLastEmailCount();
          final newCount = inbox.length;
          
          // Hiển thị thông báo nếu có email mới
          _showNewEmailNotification(newCount, lastCount);
          
          // Cập nhật số lượng email hiện tại
          await _setLastEmailCount(newCount);
        }); //

        return FutureBuilder<String?>(
          future: widget.filter.senderEmail != null ? getUidFromEmail(widget.filter.senderEmail!) : Future.value(null),
          builder: (context, senderSnapshot) {
            if (senderSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.deepPurple),
              );
            }

            final senderUid = senderSnapshot.data; //

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
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

                String formattedTime = '';
                if (timestamp != null) {
                  final now = DateTime.now();
                  final difference = now.difference(timestamp);
                  
                  if (difference.inDays == 0) {
                    formattedTime = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
                  } else if (difference.inDays < 7) {
                    final weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
                    formattedTime = weekdays[timestamp.weekday % 7];
                  } else {
                    formattedTime = '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}';
                  }
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Dismissible(
                    key: Key(docId),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete, color: Colors.white, size: 28),
                          SizedBox(height: 4),
                          Text(
                            'Xóa',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    confirmDismiss: (_) async {
                      return await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: isDarkMode ? const Color(0xFF3B2C5E) : Colors.white,
                          title: Text(
                            'Xóa email',
                            style: TextStyle(color: textColor),
                          ),
                          content: Text(
                            'Bạn có chắc muốn xóa email này?',
                            style: TextStyle(color: subtitleColor),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                'Xóa',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (_) async {
                      try {
                        await deleteEmail(docId);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Email đã được chuyển vào thùng rác'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lỗi: $e'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: Card(
                      elevation: isRead ? 1 : 3,
                      color: isRead ? cardColor : unreadCardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundColor: isDarkMode 
                                    ? Colors.deepPurple.shade300.withOpacity(0.3)
                                    : Colors.deepPurple[100],
                                radius: 22,
                                child: Icon(
                                  isStarred ? Icons.star : Icons.email,
                                  color: isStarred ? Colors.amber : Colors.deepPurple,
                                  size: 20,
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
                                              fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                              fontSize: 16,
                                              color: isRead ? subtitleColor : textColor,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (formattedTime.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDarkMode 
                                                  ? Colors.white10 
                                                  : Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              formattedTime,
                                              style: TextStyle(
                                                color: subtitleColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      body.length > 100 ? '${body.substring(0, 100)}...' : body,
                                      style: TextStyle(
                                        color: subtitleColor,
                                        fontSize: 14,
                                        fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                                        height: 1.3,
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