import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:medcave/main/Starting_screen/splash_screen/splash_screen.dart';
import 'package:medcave/config/theme/theme.dart';
import 'package:medcave/firebase_options.dart';

Future<void> main() async {
  // This must be called before anything that might use platform channels
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only
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
      title: 'MedCave',
      theme: AppTheme.theme,
      home: const AdminSplashScreen(),
    );
  }
}