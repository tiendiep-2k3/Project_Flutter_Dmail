import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:test3/screens/splash/splash_screen.dart';
import 'package:test3/config/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dmail',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const SplashScreen(), // 👈 Splash là màn hình đầu tiên
    );
  }
}
