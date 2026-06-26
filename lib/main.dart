import 'package:flutter/material.dart';
import 'src/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InEarDetectApp());
}

class InEarDetectApp extends StatelessWidget {
  const InEarDetectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'in ear detect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
      ),
      home: const HomeScreen(),
    );
  }
}
