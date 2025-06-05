import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class ComposeEmailScreen extends StatefulWidget {
  final String? toEmail;
  final String? subject;
  final String? body;

  const ComposeEmailScreen({
    Key? key,
    this.toEmail,
    this.subject,
    this.body,
  }) : super(key: key);//abàds

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
  List<PlatformFile> attachedFiles = [];

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
      'isStarred': false, // Thêm trường isStarred
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (_draftDocId == null) {
      final doc = await FirebaseFirestore.instance.collection('emails').add(data);
      _draftDocId = doc.id;
    } else {
      await FirebaseFirestore.instance.collection('emails').doc(_draftDocId!).update(data);
    }
  }

  Future<String> uploadFileToStorage(PlatformFile file) async {
    if (file.bytes == null) {
      throw Exception('Không đọc được nội dung file: ${file.name}');
    }

    String contentType = 'application/octet-stream';
    final ext = file.extension?.toLowerCase();
    if (ext == 'jpg' || ext == 'jpeg') contentType = 'image/jpeg';
    else if (ext == 'png') contentType = 'image/png';
    else if (ext == 'webp') contentType = 'image/webp';
    else if (ext == 'pdf') contentType = 'application/pdf';
    else if (ext == 'docx') contentType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

    final ref = FirebaseStorage.instance.ref().child('attachments/${file.name}');
    final metadata = SettableMetadata(contentType: contentType);
    final upload = await ref.putData(file.bytes!, metadata);
    return await upload.ref.getDownloadURL();
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

    final attachments = <Map<String, String>>[];
    for (final file in attachedFiles) {
      try {
        final url = await uploadFileToStorage(file);
        attachments.add({'fileName': file.name, 'fileUrl': url});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi upload tệp: ${file.name}')),
        );
        setState(() => _isSending = false);
        return;
      }
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
      'isStarred': false, // Thêm trường isStarred
      'attachments': attachments,
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
      setState(() => _isSending = false);
      return;
    }

    setState(() => _isSending = false);
  }

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: true);
    if (result != null) {
      setState(() {
        attachedFiles = result.files;
      });
    }
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Soạn Email',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: _isSending ? null : _sendEmail,
          ),
        ],
      ),
      body: Container(
        color: Colors.deepPurple[50],
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    _buildInputRow('Đến:', _toController, 'Nhập email người nhận', validator: (value) => value == null || value.isEmpty ? 'Bắt buộc nhập email' : null),
                    if (showCc)
                      _buildInputRow('Cc:', _ccController, 'Nhập email CC'),
                    if (showBcc)
                      _buildInputRow('Bcc:', _bccController, 'Nhập email BCC'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputRow('Tiêu đề:', _subjectController, 'Nhập tiêu đề email'),
                        ),
                        TextButton(
                          onPressed: () => setState(() => showCc = !showCc),
                          child: Text('Cc', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w600)),
                        ),
                        TextButton(
                          onPressed: () => setState(() => showBcc = !showBcc),
                          child: Text('Bcc', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  child: TextFormField(
                    controller: _bodyController,
                    maxLines: null,
                    expands: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Nhập nội dung email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(18),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Nội dung không được để trống' : null,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
              if (attachedFiles.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: attachedFiles.map((file) => Chip(
                      backgroundColor: Colors.deepPurple[100],
                      label: Text(file.name, style: const TextStyle(color: Colors.deepPurple)),
                      deleteIcon: const Icon(Icons.close, size: 18, color: Colors.deepPurple),
                      onDeleted: () {
                        setState(() {
                          attachedFiles.remove(file);
                        });
                      },
                      avatar: const Icon(Icons.insert_drive_file, color: Colors.deepPurple),
                    )).toList(),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: pickFiles,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Đính kèm tệp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.deepPurple,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSending ? null : _sendEmail,
                        icon: Icon(_isSending ? Icons.hourglass_empty : Icons.send),
                        label: Text(_isSending ? 'Đang gửi...' : 'Gửi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputRow(String label, TextEditingController controller, String hint, {String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              ),
              validator: validator,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}