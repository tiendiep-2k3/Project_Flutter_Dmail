import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:test3/screens/auth/otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isObscure = true;
  bool _isObscureConfirm = true;

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    String input = _phoneController.text.trim();
    if (input.startsWith('0')) {
      input = input.substring(1);
    }
    final phone = '+84$input';

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (_) {},
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xác minh: ${e.message}')),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() => _isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPVerificationScreen(
              verificationId: verificationId,
              phoneNumber: phone,
              isRegister: true,
              displayName: _displayNameController.text.trim(),
              password: _passwordController.text.trim(),
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Đăng ký'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Logo hình ảnh
                Image.asset(
                  'assets/images/Dmail_logo.png',
                  height: 140,
                  width: 140,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                // Số điện thoại
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone, color: Colors.deepPurple),
                    prefixText: '+84 ',
                    labelText: 'Số điện thoại',
                    labelStyle: const TextStyle(color: Colors.deepPurple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.deepPurple),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.deepPurple),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    hintText: "Nhập số điện thoại của bạn",
                    hintStyle: TextStyle(color: Colors.deepPurple.withOpacity(0.6))
                  ),
                  style: const TextStyle(color: Colors.deepPurple),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    } else if (!RegExp(r'^[1-9][0-9]{8,9}$').hasMatch(value)) {
                      return 'Số điện thoại không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Tên hiển thị
                TextFormField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person, color: Colors.deepPurple),
                    labelText: 'Tên hiển thị (tuỳ chọn)',
                    labelStyle: const TextStyle(color: Colors.deepPurple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.deepPurple),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.deepPurple),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'VD: Phạm Thị Thu H', 
                    hintStyle: TextStyle(color: Colors.deepPurple),
                  ),
                  style: const TextStyle(color: Colors.deepPurple),
                ),
                const SizedBox(height: 16),
                // Mật khẩu
                TextFormField(
                  controller: _passwordController,
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock, color: Colors.deepPurple),
                    labelText: 'Mật khẩu',
                    labelStyle: const TextStyle(color: Colors.deepPurple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.deepPurple),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.deepPurple),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Ít nhất 6 kí tự',
                    hintStyle: TextStyle(color: Colors.deepPurple),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscure ? Icons.visibility_off : Icons.visibility,
                        color: Colors.deepPurple,
                      ),
                      onPressed: () => setState(() => _isObscure = !_isObscure),
                    ),
                  ),
                  style: const TextStyle(color: Colors.deepPurple),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Mật khẩu phải có ít nhất 6 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Xác nhận mật khẩu
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _isObscureConfirm,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.deepPurple),
                    labelText: 'Xác nhận mật khẩu',
                    labelStyle: const TextStyle(color: Colors.deepPurple),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.deepPurple),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.deepPurple),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Nhập lại mật khẩu của bạn',
                    hintStyle: TextStyle(color: Colors.deepPurple),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscureConfirm ? Icons.visibility_off : Icons.visibility,
                        color: Colors.deepPurple,
                      ),
                      onPressed: () => setState(() => _isObscureConfirm = !_isObscureConfirm),
                    ),
                  ),
                  style: const TextStyle(color: Colors.deepPurple),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Mật khẩu không khớp';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                // Nút gửi mã OTP
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.send, color: Colors.deepPurple),
                    label: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurple),
                          )
                        : const Text(
                            'Gửi mã OTP',
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.deepPurple, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepPurple,
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _sendOTP,
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
