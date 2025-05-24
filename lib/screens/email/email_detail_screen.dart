import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test3/screens/email/compose_email_screen.dart';

class EmailDetailScreen extends StatefulWidget {
  final String subject;
  final String body;
  final String fromUid;
  final String? toUid;
  final List<String>? ccUids;
  final List<String>? bccUids;
  final DateTime? timestamp;

  const EmailDetailScreen({
    Key? key,
    required this.subject,
    required this.body,
    required this.fromUid,
    this.toUid,
    this.ccUids,
    this.bccUids,
    this.timestamp,
  }) : super(key: key);

  @override
  State<EmailDetailScreen> createState() => _EmailDetailScreenState();
}

class _EmailDetailScreenState extends State<EmailDetailScreen> {
  String? fromEmail;
  String? toEmail;
  List<String> ccEmails = [];
  late final String currentUid;

  @override
  void initState() {
    super.initState();
    currentUid = FirebaseAuth.instance.currentUser!.uid;
    _loadEmails();
  }

  Future<void> _loadEmails() async {
    final usersRef = FirebaseFirestore.instance.collection('users');

    // From
    final fromSnap = await usersRef.doc(widget.fromUid).get();
    fromEmail = fromSnap.data()?['email'] ?? '(Không rõ)';

    // To
    if (widget.toUid != null) {
      final toSnap = await usersRef.doc(widget.toUid!).get();
      toEmail = toSnap.data()?['email'];
    }

    // CC
    if (widget.ccUids != null) {
      for (final ccUid in widget.ccUids!) {
        final ccSnap = await usersRef.doc(ccUid).get();
        final email = ccSnap.data()?['email'];
        if (email != null) ccEmails.add(email);
      }
    }

    setState(() {});
  }

  bool get isBccUser =>
      widget.bccUids != null && widget.bccUids!.contains(currentUid);

  @override
  Widget build(BuildContext context) {
    final timeStr = widget.timestamp != null
        ? '${widget.timestamp!.day}/${widget.timestamp!.month}/${widget.timestamp!.year}, '
          '${widget.timestamp!.hour}:${widget.timestamp!.minute.toString().padLeft(2, '0')}'
        : 'Không rõ thời gian';

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết Email')),
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
            )
          ],
        ),
      ),
    );
  }
}
