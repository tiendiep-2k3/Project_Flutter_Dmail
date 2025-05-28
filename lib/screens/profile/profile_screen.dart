import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  String? _phone;
  String? _photoUrl;
  bool _isLoading = true;

  final List<String> _localAvatars = [
    'assets/images/avt2.png',
    'assets/images/avt3.png',
    'assets/images/avt4.png',
    'assets/images/avt5.png',
    'assets/images/avt6.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();

    setState(() {
      _displayNameController.text = data?['displayName'] ?? '';
      _emailController.text = data?['email'] ?? '';
      _bioController.text = data?['bio'] ?? '';
      _notificationsEnabled = data?['notificationsEnabled'] ?? true;
      _darkMode = data?['themePreference'] == 'dark';
      _phone = data?['phone'] ?? user.phoneNumber;
      _photoUrl = data?['photoUrl'];
      _isLoading = false;
    });
  }

  void _showAvatarSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return GridView.count(
          crossAxisCount: 3,
          padding: const EdgeInsets.all(16),
          children: _localAvatars.map((path) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _photoUrl = path;
                });
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(path),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'displayName': _displayNameController.text.trim(),
      'email': _emailController.text.trim(),
      'bio': _bioController.text.trim(),
      'photoUrl': _photoUrl ?? '',
      'notificationsEnabled': _notificationsEnabled,
      'themePreference': _darkMode ? 'dark' : 'light',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cập nhật thành công!')),
    );

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Hồ sơ cá nhân', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: Colors.deepPurple[100],
                          backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty
                              ? AssetImage(_photoUrl!)
                              : const AssetImage('assets/images/avatar1.webp') as ImageProvider,
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Material(
                            color: Colors.deepPurple,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _showAvatarSelection,
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.edit, color: Colors.white, size: 22),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(_phone ?? '', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _displayNameController,
                      decoration: InputDecoration(
                        labelText: 'Tên hiển thị',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _bioController,
                      decoration: InputDecoration(
                        labelText: 'Bio',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      title: const Text('Thông báo'),
                      value: _notificationsEnabled,
                      onChanged: (val) => setState(() => _notificationsEnabled = val),
                      activeColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: Colors.deepPurple[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    const SizedBox(height: 6),
                    SwitchListTile(
                      title: const Text('Chế độ tối'),
                      value: _darkMode,
                      onChanged: (val) => setState(() => _darkMode = val),
                      activeColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: Colors.deepPurple[50],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        child: const Text('Lưu thay đổi'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
