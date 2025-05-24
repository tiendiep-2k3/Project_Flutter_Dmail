import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ComposeEmailScreen extends StatefulWidget {
  final String? toEmail;
  final String? subject;
  final String? body;

  const ComposeEmailScreen({
    Key? key,
    this.toEmail,
    this.subject,
    this.body,
  }) : super(key: key);

  @override
  State<ComposeEmailScreen> createState() => _ComposeEmailScreenState();
}

class _ComposeEmailScreenState extends State<ComposeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _toController = TextEditingController();
  final _ccController = TextEditingController();
  final _bccController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  bool _isSending = false;
  bool showCc = false;
  bool showBcc = false;
  String? _draftDocId;
  Timer? _draftTimer;

  @override
  void initState() {
    super.initState();
    _toController.text = widget.toEmail ?? '';
    _subjectController.text = widget.subject ?? '';
    _bodyController.text = widget.body ?? '';

    _toController.addListener(_scheduleDraftSave);
    _ccController.addListener(_scheduleDraftSave);
    _bccController.addListener(_scheduleDraftSave);
    _subjectController.addListener(_scheduleDraftSave);
    _bodyController.addListener(_scheduleDraftSave);
  }

  void _scheduleDraftSave() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(seconds: 1), _saveDraft);
  }

  Future<String?> _getUidFromEmail(String email) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first['uid'];
  }

  Future<List<String>> _getUidsFromEmails(List<String> emails) async {
    if (emails.isEmpty) return [];
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('email', whereIn: emails)
        .get();
    return snap.docs.map((e) => e['uid'] as String).toList();
  }

  Future<void> _saveDraft() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final data = {
      'fromUid': user.uid,
      'toEmail': _toController.text.trim(),
      'ccEmails': _ccController.text.trim(),
      'bccEmails': _bccController.text.trim(),
      'subject': _subjectController.text.trim(),
      'body': _bodyController.text.trim(),
      'isDraft': true,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (_draftDocId == null) {
      final doc = await FirebaseFirestore.instance.collection('emails').add(data);
      _draftDocId = doc.id;
    } else {
      await FirebaseFirestore.instance.collection('emails').doc(_draftDocId!).update(data);
    }
  }

  Future<void> _sendEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    final fromUid = FirebaseAuth.instance.currentUser!.uid;
    final toEmail = _toController.text.trim();
    final ccEmails = _ccController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final bccEmails = _bccController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final subject = _subjectController.text.trim();
    final body = _bodyController.text.trim();

    final toUid = await _getUidFromEmail(toEmail);
    final ccUids = await _getUidsFromEmails(ccEmails);
    final bccUids = await _getUidsFromEmails(bccEmails);

    if (toUid == null && ccUids.isEmpty && bccUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có người nhận hợp lệ')),
      );
      setState(() => _isSending = false);
      return;
    }

    final data = {
      'fromUid': fromUid,
      'toUid': toUid,
      'ccUids': ccUids,
      'bccUids': bccUids,
      'subject': subject,
      'body': body,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'isDraft': false,
    };

    try {
      if (_draftDocId != null) {
        await FirebaseFirestore.instance.collection('emails').doc(_draftDocId!).update(data);
      } else {
        await FirebaseFirestore.instance.collection('emails').add(data);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email đã được gửi')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gửi email thất bại: $e')),
      );
    }

    setState(() => _isSending = false);
  }

  @override
  void dispose() {
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    _draftTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Soạn Email')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // To + Cc Bcc buttons
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _toController,
                      decoration: const InputDecoration(labelText: 'Đến'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Bắt buộc nhập email' : null,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => showCc = !showCc),
                    child: const Text('Cc'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => showBcc = !showBcc),
                    child: const Text('Bcc'),
                  ),
                ],
              ),
              if (showCc)
                TextFormField(
                  controller: _ccController,
                  decoration: const InputDecoration(labelText: 'Cc (phân cách bằng dấu phẩy)'),
                ),
              if (showBcc)
                TextFormField(
                  controller: _bccController,
                  decoration: const InputDecoration(labelText: 'Bcc (phân cách bằng dấu phẩy)'),
                ),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(labelText: 'Tiêu đề'),
              ),
              Expanded(
                child: TextFormField(
                  controller: _bodyController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(labelText: 'Nội dung'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Nội dung không được để trống' : null,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSending ? null : _sendEmail,
                child: Text(_isSending ? 'Đang gửi...' : 'Gửi email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
