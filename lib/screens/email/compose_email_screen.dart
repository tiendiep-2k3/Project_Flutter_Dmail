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
        backgroundColor: isDarkMode ? theme.scaffoldBackgroundColor : Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Soạn Email',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              // TODO: Implement delete draft
              Navigator.pop(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isSending ? null : _sendEmail,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? theme.scaffoldBackgroundColor : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            'Đến:',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _toController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Nhập email người nhận',
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Bắt buộc nhập email' : null,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => setState(() => showCc = !showCc),
                              child: Text(
                                'Cc',
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => setState(() => showBcc = !showBcc),
                              child: Text(
                                'Bcc',
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (showCc)
                      Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              'Cc:',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _ccController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Nhập email CC',
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (showBcc)
                      Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              'Bcc:',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _bccController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Nhập email BCC',
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            'Tiêu đề:',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _subjectController,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Nhập tiêu đề email',
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: _bodyController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Nhập nội dung email',
                    contentPadding: EdgeInsets.all(16),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Nội dung không được để trống' : null,
                ),
              ),
              if (attachedFiles.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          'Tệp đính kèm:',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: attachedFiles.length,
                          itemBuilder: (context, index) {
                            final file = attachedFiles[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.insert_drive_file,
                                    size: 20,
                                    color: theme.primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    file.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () {
                                      setState(() {
                                        attachedFiles.removeAt(index);
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: pickFiles,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Đính kèm tệp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                        foregroundColor: theme.primaryColor,
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _isSending ? null : _sendEmail,
                      icon: Icon(_isSending ? Icons.hourglass_empty : Icons.send),
                      label: Text(_isSending ? 'Đang gửi...' : 'Gửi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
}
