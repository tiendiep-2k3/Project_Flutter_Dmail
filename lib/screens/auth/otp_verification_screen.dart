import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test3/screens/home/main_screen.dart';
import 'package:test3/screens/profile/profile_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final bool isRegister;
  final String? displayName;
  final String? password;

  const OTPVerificationScreen({
    Key? key,
    required this.verificationId,
    required this.phoneNumber,
    this.isRegister = true,
    this.displayName,
    this.password,
  }) : super(key: key);

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;

  Future<void> _verifyOTP() async {
    final smsCode = _otpController.text.trim();
    if (smsCode.isEmpty || smsCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã OTP hợp lệ')),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: smsCode,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) throw FirebaseAuthException(code: 'null-user');

      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final snapshot = await userDoc.get();

      if (widget.isRegister) {
        if (!snapshot.exists) {
          await userDoc.set({
            'uid': user.uid,
            'phone': user.phoneNumber,
            'displayName': widget.displayName ?? '',
            'password': widget.password ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tài khoản đã tồn tại. Hãy đăng nhập.')),
          );
          await FirebaseAuth.instance.signOut();
          Navigator.pop(context);
          return;
        }
      } else {
        if (!snapshot.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tài khoản chưa đăng ký. Vui lòng tạo tài khoản.')),
          );
          await FirebaseAuth.instance.signOut();
          Navigator.pop(context);
          return;
        }
      }

      // Chuyển đến trang cá nhân sau khi xác minh thành công
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xác minh: ${e.message}')),
      );
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xác minh OTP')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('Nhập mã OTP đã gửi đến ${widget.phoneNumber}'),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Mã OTP',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isVerifying ? null : _verifyOTP,
              child: _isVerifying
                  ? const CircularProgressIndicator()
                  : const Text('Xác minh'),
            ),
          ],
        ),
      ),
    );
  }
}
