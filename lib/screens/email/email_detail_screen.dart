import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test3/screens/email/compose_email_screen.dart';
import 'package:test3/screens/home/label_management_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class EmailDetailScreen extends StatefulWidget {
  final String subject;
  final String body;
  final String fromUid;
  final String? toUid;
  final List<String>? ccUids;
  final List<String>? bccUids;
  final DateTime? timestamp;
  final List<dynamic>? attachments;
  final String? docId;
  final String labelName;

  const EmailDetailScreen({
    Key? key,
    required this.subject,
    required this.body,
    required this.fromUid,
    this.toUid,
    this.ccUids,
    this.bccUids,
    this.timestamp,
    this.attachments,
    this.docId,
    required this.labelName,
  }) : super(key: key);

  @override
  State<EmailDetailScreen> createState() => _EmailDetailScreenState();
}

class _EmailDetailScreenState extends State<EmailDetailScreen> {
  String? fromEmail;
  String? toEmail;
  List<String> ccEmails = [];
  late final String currentUid;
  bool isRead = false;
  bool isStarred = false;
  List<String> emailLabels = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    currentUid = FirebaseAuth.instance.currentUser!.uid;
    _loadEmails();
    _loadEmailStatus();
  }

  Future<void> _loadEmails() async {
    final usersRef = FirebaseFirestore.instance.collection('users');

    final fromSnap = await usersRef.doc(widget.fromUid).get();
    fromEmail = fromSnap.data()?['email'] ?? '(Không rõ)';

    if (widget.toUid != null) {
      final toSnap = await usersRef.doc(widget.toUid!).get();
      toEmail = toSnap.data()?['email'];
    }

    if (widget.ccUids != null) {
      for (final ccUid in widget.ccUids!) {
        final ccSnap = await usersRef.doc(ccUid).get();
        final email = ccSnap.data()?['email'];
        if (email != null) ccEmails.add(email);
      }
    }

    setState(() {});
  }

  Future<void> _loadEmailStatus() async {
    if (widget.docId != null) {
      final emailDoc = await FirebaseFirestore.instance
          .collection('emails')
          .doc(widget.docId)
          .get();

      if (emailDoc.exists) {
        final data = emailDoc.data() as Map<String, dynamic>;
        setState(() {
          isRead = data['isRead'] ?? false;
          isStarred = data['isStarred'] ?? false;
          emailLabels = List<String>.from(data['labels'] ?? []);
          isLoading = false;
        });

        if (!isRead) {
          try {
            await FirebaseFirestore.instance
                .collection('emails')
                .doc(widget.docId)
                .update({'isRead': true});
            setState(() {
              isRead = true;
            });
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi khi đánh dấu đã đọc: ${e.toString()}')),
            );
          }
        }
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleReadStatus() async {
    if (widget.docId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể cập nhật trạng thái email')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('emails')
          .doc(widget.docId)
          .update({'isRead': !isRead});

      setState(() {
        isRead = !isRead;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isRead ? 'Đã đánh dấu là đã đọc' : 'Đã đánh dấu là chưa đọc')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleStarStatus() async {
    if (widget.docId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể cập nhật trạng thái gắn sao')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('emails')
          .doc(widget.docId)
          .update({'isStarred': !isStarred});

      setState(() {
        isStarred = !isStarred;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isStarred ? 'Đã gắn dấu sao' : 'Đã bỏ dấu sao')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
      setState(() => isLoading = false);
    }
  }

  Future<void> _moveToTrash() async {
    if (widget.docId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tìm thấy email để xóa')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('emails')
          .doc(widget.docId)
          .update({'folder': 'trash'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email đã được chuyển vào thùng rác')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    }
  }

  Future<void> _updateLabels(List<String> selectedLabels) async {
    if (widget.docId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể cập nhật nhãn: Email không tồn tại')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('emails')
          .doc(widget.docId)
          .update({'labels': selectedLabels});

      setState(() {
        emailLabels = selectedLabels;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật nhãn thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật nhãn: ${e.toString()}')),
      );
      setState(() => isLoading = false);
    }
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _getUserLabelsStream() {
    return FirebaseFirestore.instance
        .collection('labels')
        .doc(currentUid)
        .snapshots();
  }

  Future<void> _showLabelDialog() async {
    if (!mounted) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('labels')
        .doc(currentUid)
        .get();
    final data = snapshot.data();
    final labels = List<Map<String, dynamic>>.from(data?['labels'] ?? []);

    final Map<String, bool> selectedLabels = {};
    for (var label in labels) {
      selectedLabels[label['id']] = emailLabels.contains(label['id']);
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Chọn nhãn'),
              content: SingleChildScrollView(
                child: labels.isEmpty
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Chưa có nhãn nào.'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LabelManagementScreen(),
                                ),
                              );
                            },
                            child: const Text('Tạo nhãn mới'),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: labels.map((label) {
                          return CheckboxListTile(
                            title: Text(label['name']?.toString() ?? ''),
                            value: selectedLabels[label['id']],
                            onChanged: (bool? value) {
                              setDialogState(() {
                                selectedLabels[label['id']] = value ?? false;
                              });
                            },
                          );
                        }).toList(),
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                if (labels.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      final updatedLabels = selectedLabels.entries
                          .where((entry) => entry.value)
                          .map((entry) => entry.key)
                          .toList();
                      _updateLabels(updatedLabels);
                      Navigator.pop(context);
                    },
                    child: const Text('OK'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  bool get isBccUser => widget.bccUids != null && widget.bccUids!.contains(currentUid);

  @override
  Widget build(BuildContext context) {
    final timeStr = widget.timestamp != null
        ? '${widget.timestamp!.day}/${widget.timestamp!.month}/${widget.timestamp!.year}, '
            '${widget.timestamp!.hour}:${widget.timestamp!.minute.toString().padLeft(2, '0')}'
        : 'Không rõ thời gian';

    return Scaffold(
      appBar: AppBar(
        title: Text('Nhãn: ${widget.labelName}'),
        actions: [
          IconButton(
            icon: Icon(
              isRead ? Icons.mark_email_read : Icons.mark_email_unread,
              color: isRead ? Colors.black54 : Colors.black,
            ),
            onPressed: isLoading ? null : _toggleReadStatus,
            tooltip: isRead ? 'Đánh dấu là chưa đọc' : 'Đánh dấu là đã đọc',
          ),
          IconButton(
            icon: Icon(
              isStarred ? Icons.star : Icons.star_border,
              color: isStarred ? Colors.amber : Colors.black,
            ),
            onPressed: isLoading ? null : _toggleStarStatus,
            tooltip: isStarred ? 'Bỏ gắn sao' : 'Gắn sao',
          ),
          IconButton(
            icon: const Icon(Icons.label),
            onPressed: _showLabelDialog,
            tooltip: 'Gán nhãn',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _moveToTrash,
            tooltip: 'Chuyển vào thùng rác',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (fromEmail != null)
              Text.rich(TextSpan(
                children: [
                  const TextSpan(text: "From: ", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: fromEmail!),
                ],
              )),
            if (toEmail != null)
              Text.rich(TextSpan(
                children: [
                  const TextSpan(text: "To: ", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: toEmail!),
                ],
              )),
            if (ccEmails.isNotEmpty && !isBccUser)
              Text.rich(TextSpan(
                children: [
                  const TextSpan(text: "Cc: ", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: ccEmails.join(', ')),
                ],
              )),
            const SizedBox(height: 4),
            Text("Date: $timeStr"),
            const Divider(height: 24),
            Text(widget.subject,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(widget.body, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            if (emailLabels.isNotEmpty) ...[
              const Text("Nhãn:", style: TextStyle(fontWeight: FontWeight.bold)),
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('labels').doc(currentUid).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.hasError) return const SizedBox.shrink();
                  final data = snapshot.data!.data();
                  final labels = List<Map<String, dynamic>>.from(data?['labels'] ?? []);
                  return Wrap(
                    children: emailLabels.map((labelId) {
                      final label = labels.firstWhere(
                        (l) => l['id'] == labelId,
                        orElse: () => {'name': 'Không xác định', 'id': ''},
                      );
                      return Chip(
                        label: Text(label['name']?.toString() ?? ''),
                        onDeleted: () {
                          final updatedLabels = List<String>.from(emailLabels);
                          updatedLabels.remove(labelId);
                          _updateLabels(updatedLabels);
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            if (widget.attachments != null && widget.attachments!.isNotEmpty) ...[
              const Text("Tệp đính kèm:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Column(
                children: widget.attachments!.map((attachment) {
                  final fileName = attachment['fileName'] ?? 'Tệp';
                  final fileUrl = attachment['fileUrl'];
                  return ListTile(
                    title: Text(fileName),
                    trailing: const Icon(Icons.download),
                    onTap: () async {
                      final uri = Uri.parse(fileUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.reply),
                  label: const Text('Trả lời'),
                  onPressed: fromEmail == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ComposeEmailScreen(
                                toEmail: fromEmail,
                                subject: 'Re: ${widget.subject}',
                              ),
                            ),
                          );
                        },
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.forward),
                  label: const Text('Chuyển tiếp'),
                  onPressed: () {
                    final quotedBody = '''
                    ---------- Forwarded message ----------
                    From: ${fromEmail ?? 'Không rõ'}
                    Date: $timeStr
                    Subject: ${widget.subject}
                    ${widget.body}
                    ''';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ComposeEmailScreen(
                          subject: 'Fwd: ${widget.subject}',
                          body: quotedBody,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}