import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:test3/screens/splash/splash_screen.dart';
import 'package:test3/config/firebase_options.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Dmail',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.indigo,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Color(0xFF2C1E4A), // tím đậm
            primaryColor: Colors.deepPurple,
            cardColor: Color(0xFF3B2C5E), // màu thẻ thư
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF512DA8),
              foregroundColor: Colors.white,
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color(0xFF7C4DFF),
              foregroundColor: Colors.white,
            ),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFB388FF),
              onPrimary: Colors.white,
              surface: Color(0xFF2C1E4A),
              onSurface: Colors.white70,
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Color(0xFF3B2C5E),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              labelStyle: TextStyle(color: Colors.white70),
            ),
          ),
          themeMode: mode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
