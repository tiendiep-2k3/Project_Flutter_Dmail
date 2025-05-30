import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test3/main.dart'; 

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
      themeNotifier.value = (data?['themePreference'] ?? 'light') == 'dark'
          ? ThemeMode.dark
          : ThemeMode.light;
      _phone = data?['phone'] ?? user.phoneNumber;
      _photoUrl = data?['photoUrl'];
      _isLoading = false;
    });
  }

  void _showAvatarSelection() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: GridView.count(
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
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(path, fit: BoxFit.cover),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
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
      'themePreference': themeNotifier.value == ThemeMode.dark ? 'dark' : 'light',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cập nhật thành công!'),
        backgroundColor: Colors.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.white70 : Colors.grey;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Hồ sơ cá nhân', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
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
                    Text(
                      _phone ?? '',
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Tên hiển thị
                    TextFormField(
                      controller: _displayNameController,
                      style: TextStyle(color: textColor, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Tên hiển thị',
                        labelStyle: TextStyle(color: subtitleColor),
                        filled: true,
                        fillColor: isDarkMode ? const Color(0xFF3B2C5E) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Email
                    TextFormField(
                      controller: _emailController,
                      style: TextStyle(color: textColor, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: subtitleColor),
                        filled: true,
                        fillColor: isDarkMode ? const Color(0xFF3B2C5E) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    
                    // Bio
                    TextFormField(
                      controller: _bioController,
                      style: TextStyle(color: textColor, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Bio',
                        labelStyle: TextStyle(color: subtitleColor),
                        filled: true,
                        fillColor: isDarkMode ? const Color(0xFF3B2C5E) : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    
                    // Thông báo switch
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF3B2C5E) : Colors.deepPurple[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDarkMode ? Colors.white24 : Colors.deepPurple.shade100,
                          width: 1,
                        ),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          'Thông báo',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        value: _notificationsEnabled,
                        onChanged: (val) => setState(() => _notificationsEnabled = val),
                        activeColor: Colors.deepPurple,
                        inactiveThumbColor: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                        inactiveTrackColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Chế độ tối switch
                    Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF3B2C5E) : Colors.deepPurple[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDarkMode ? Colors.white24 : Colors.deepPurple.shade100,
                          width: 1,
                        ),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          'Chế độ tối',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        value: isDarkMode,
                        onChanged: (val) {
                          setState(() {
                            themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                          });
                        },
                        activeColor: Colors.deepPurple,
                        inactiveThumbColor: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                        inactiveTrackColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Nút lưu
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shadowColor: Colors.deepPurple.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        child: const Text('Lưu thay đổi'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}