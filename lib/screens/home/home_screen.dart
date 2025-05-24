import 'package:flutter/material.dart';
import 'package:test3/screens/auth/register_screen.dart';
import 'package:test3/screens/auth/login_screen.dart'; // bạn có thể thêm sau

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Dmail
                Image.asset(
                  'assets/images/Dmail.png',
                  width: 120,
                ),
                const SizedBox(height: 20),

                // Lời giới thiệu
                const Text(
                  'Chào mừng bạn đến với Dmail',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Nút đăng nhập
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    child: const Text('Đăng nhập'),
                  ),
                ),
                const SizedBox(height: 12),

                // Nút đăng ký
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()));
                    },
                    child: const Text('Tạo tài khoản mới'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
