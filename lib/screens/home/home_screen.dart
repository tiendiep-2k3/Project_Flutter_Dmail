import 'package:flutter/material.dart';
import 'package:test3/screens/auth/register_screen.dart';
import 'package:test3/screens/auth/login_screen.dart'; // bạn có thể thêm sau

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo với hiệu ứng shadow và bo tròn
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Image.asset(
                      'assets/images/Dmail.png',
                      width: 72,
                      height: 72,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tiêu đề
                  Text(
                    'Chào mừng bạn đến với Dmail',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dịch vụ Dmail bảo mật, nhanh chóng và hiện đại.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Nút đăng nhập
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.login_rounded),
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()));
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        side: BorderSide(color: theme.primaryColor, width: 2),
                        backgroundColor: Colors.white,
                        foregroundColor: theme.primaryColor,
                      ),
                      label: const Text(
                        'Đăng nhập',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nút tạo tài khoản mới
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()));
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        side: BorderSide(color: theme.primaryColor, width: 2),
                      ),
                      label: Text(
                        'Tạo tài khoản mới',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
