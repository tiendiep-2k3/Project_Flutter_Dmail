import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:test3/screens/search/search_filter.dart';

class FilterDialog extends StatefulWidget {
  final SearchFilter initialFilter;
  final Function(SearchFilter) onApply;

  const FilterDialog({Key? key, required this.initialFilter, required this.onApply}) : super(key: key);

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late TextEditingController _keywordController;
  late TextEditingController _senderController;
  DateTime? _startDate;
  DateTime? _endDate;
  bool? _hasAttachments;
  List<String> _selectedLabelIds = [];
  List<Map<String, dynamic>> _labels = [];

  @override
  void initState() {
    super.initState();
    _keywordController = TextEditingController(text: widget.initialFilter.keyword);
    _senderController = TextEditingController(text: widget.initialFilter.senderEmail);
    _startDate = widget.initialFilter.startDate;
    _endDate = widget.initialFilter.endDate;
    _hasAttachments = widget.initialFilter.hasAttachments;
    _selectedLabelIds = List.from(widget.initialFilter.labelIds);
    _loadLabels();
  }

  Future<void> _loadLabels() async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final snapshot = await FirebaseFirestore.instance.collection('labels').doc(currentUid).get();
    if (snapshot.exists) {
      final data = snapshot.data();
      setState(() {
        _labels = List<Map<String, dynamic>>.from(data?['labels'] ?? []);
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _senderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Bộ lọc tìm kiếm', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _keywordController,
              decoration: InputDecoration(
                labelText: 'Từ khóa (tiêu đề hoặc nội dung)',
                labelStyle: const TextStyle(color: Colors.deepPurple),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _senderController,
              decoration: InputDecoration(
                labelText: 'Người gửi (email)',
                labelStyle: const TextStyle(color: Colors.deepPurple),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _startDate == null
                        ? 'Từ ngày'
                        : 'Từ: \\${DateFormat('dd/MM/yyyy').format(_startDate!)}',
                    style: TextStyle(color: _startDate == null ? Colors.grey : Colors.deepPurple, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.deepPurple),
                  onPressed: () => _selectDate(context, true),
                  child: const Text('Chọn'),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _endDate == null
                        ? 'Đến ngày'
                        : 'Đến: \\${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                    style: TextStyle(color: _endDate == null ? Colors.grey : Colors.deepPurple, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.deepPurple),
                  onPressed: () => _selectDate(context, false),
                  child: const Text('Chọn'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Có tệp đính kèm', style: TextStyle(fontWeight: FontWeight.w500)),
              value: _hasAttachments ?? false,
              onChanged: (value) {
                setState(() {
                  _hasAttachments = value;
                });
              },
              tristate: true,
              activeColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),
            const Text('Nhãn:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            if (_labels.isEmpty)
              const Text('Chưa có nhãn nào.')
            else
              Column(
                children: _labels.map((label) {
                  return CheckboxListTile(
                    title: Text(label['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                    value: _selectedLabelIds.contains(label['id']),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedLabelIds.add(label['id']);
                        } else {
                          _selectedLabelIds.remove(label['id']);
                        }
                      });
                    },
                    activeColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () {
            setState(() {
              _keywordController.clear();
              _senderController.clear();
              _startDate = null;
              _endDate = null;
              _hasAttachments = null;
              _selectedLabelIds.clear();
            });
          },
          child: const Text('Xóa bộ lọc'),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            final filter = SearchFilter(
              keyword: _keywordController.text.trim(),
              startDate: _startDate,
              endDate: _endDate,
              hasAttachments: _hasAttachments,
              senderEmail: _senderController.text.trim().isEmpty ? null : _senderController.text.trim(),
              labelIds: _selectedLabelIds,
            );
            widget.onApply(filter);
            Navigator.pop(context);
          },
          child: const Text('Áp dụng'),
        ),
      ],
    );
  }
}