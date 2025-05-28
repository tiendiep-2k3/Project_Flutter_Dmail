import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test3/screens/email/label_tab.dart'; // Đảm bảo import file LabelTab

class LabelManagementScreen extends StatefulWidget {
  const LabelManagementScreen({super.key});

  @override
  State<LabelManagementScreen> createState() => _LabelManagementScreenState();
}

class _LabelManagementScreenState extends State<LabelManagementScreen> {
  final TextEditingController _labelController = TextEditingController();
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  Future<bool> _checkLabelExists(String labelName, List<dynamic> labels) async {
    return labels.any((label) => label['name'].toLowerCase() == labelName.toLowerCase());
  }

  Future<void> _addLabel() async {
    final labelName = _labelController.text.trim();
    if (labelName.isEmpty) return;

    final labelDoc = FirebaseFirestore.instance.collection('labels').doc(currentUid);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(labelDoc);
        final List<dynamic> labels = snapshot.data() != null ? snapshot.data()!['labels'] ?? [] : [];

        if (await _checkLabelExists(labelName, labels)) {
          throw Exception('Nhãn "$labelName" đã tồn tại.');
        }

        final newLabelId = 'label_${DateTime.now().millisecondsSinceEpoch}';
        labels.add({
          'name': labelName,
          'id': newLabelId,
          'color': Colors.blue.value,
        });

        transaction.set(
          labelDoc,
          {'uid': currentUid, 'labels': labels},
          SetOptions(merge: true),
        );
      });

      _labelController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm nhãn thành công')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi thêm nhãn: $e')),
      );
    }
  }

  Future<void> _deleteLabelFromEmails(String labelId) async {
    final emailsSnapshot = await FirebaseFirestore.instance
        .collection('emails')
        .where('labels', arrayContains: labelId)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (var doc in emailsSnapshot.docs) {
      final List<dynamic> labels = List.from(doc.data()['labels'] ?? []);
      labels.remove(labelId);
      batch.update(doc.reference, {'labels': labels});
    }
    await batch.commit();
  }

  Future<void> _deleteLabel(String labelId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa nhãn'),
        content: const Text('Bạn có chắc chắn muốn xóa nhãn này? Nhãn sẽ bị xóa khỏi tất cả email.'),
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

    if (confirm != true) return;

    final labelDoc = FirebaseFirestore.instance.collection('labels').doc(currentUid);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(labelDoc);
        if (!snapshot.exists) return;

        final List<dynamic> labels = snapshot.data()!['labels'] ?? [];
        labels.removeWhere((label) => label['id'] == labelId);

        transaction.set(
          labelDoc,
          {'uid': currentUid, 'labels': labels},
          SetOptions(merge: true),
        );
      });

      await _deleteLabelFromEmails(labelId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa nhãn thành công')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa nhãn: $e')),
      );
    }
  }

  Future<void> _renameLabel(String labelId, String? newName) async {
    final trimmedName = newName?.trim() ?? '';
    if (trimmedName.isEmpty) return;

    final labelDoc = FirebaseFirestore.instance.collection('labels').doc(currentUid);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(labelDoc);
        if (!snapshot.exists) return;

        final List<dynamic> labels = snapshot.data()!['labels'] ?? [];
        if (await _checkLabelExists(trimmedName, labels)) {
          throw Exception('Nhãn "$trimmedName" đã tồn tại.');
        }

        final index = labels.indexWhere((label) => label['id'] == labelId);
        if (index != -1) {
          final currentLabel = labels[index];
          labels[index] = {
            'name': trimmedName,
            'id': labelId,
            'color': currentLabel['color'] ?? Colors.blue.value,
          };
          transaction.set(
            labelDoc,
            {'uid': currentUid, 'labels': labels},
            SetOptions(merge: true),
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi tên nhãn thành công')),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi đổi tên nhãn: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Quản lý nhãn', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: 'Thêm nhãn mới',
                labelStyle: const TextStyle(color: Colors.deepPurple),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add, color: Colors.deepPurple),
                  onPressed: _addLabel,
                ),
              ),
              onSubmitted: (_) => _addLabel(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('labels')
                    .doc(currentUid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text('Đã xảy ra lỗi khi tải nhãn.'));
                  }

                  if (!snapshot.hasData || snapshot.data?.data() == null) {
                    return const Center(child: Text('Chưa có nhãn nào.'));
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final labels = List<Map<String, dynamic>>.from(data['labels'] ?? []);

                  if (labels.isEmpty) {
                    return const Center(child: Text('Chưa có nhãn nào.'));
                  }

                  return ListView.separated(
                    itemCount: labels.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final label = labels[index];
                      final labelColor = Color(label['color'] ?? Colors.blue.value);
                      return Material(
                        color: Colors.deepPurple[50],
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LabelTab(labelId: label['id'], labelName: label['name']),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: labelColor.withOpacity(0.15),
                                  child: Icon(Icons.label, color: labelColor),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    label['name'] ?? 'Nhãn không xác định',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.deepPurple),
                                  onPressed: () async {
                                    final newName = await showDialog<String>(
                                      context: context,
                                      builder: (context) {
                                        final controller = TextEditingController(text: label['name']);
                                        return AlertDialog(
                                          title: const Text('Đổi tên nhãn'),
                                          content: TextField(
                                            controller: controller,
                                            decoration: const InputDecoration(hintText: 'Nhập tên mới'),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Hủy'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, controller.text),
                                              child: const Text('Lưu'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    if (newName != null && newName.trim().isNotEmpty) {
                                      _renameLabel(label['id'], newName);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteLabel(label['id']),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}