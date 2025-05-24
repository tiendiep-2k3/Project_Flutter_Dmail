import 'package:flutter/material.dart';
import 'package:test3/screens/settings/change_password_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Tài khoản'),
            tileColor: Color(0xFFEDEDED),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Đổi mật khẩu'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            },
          ),
          const Divider(),
          // bạn có thể thêm các mục khác như: thông báo, ngôn ngữ, đăng xuất...
        ],
      ),
    );
  }
}
