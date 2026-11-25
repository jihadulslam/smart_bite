
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'meal_plan_page.dart';

Future<void> main() async {
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
      debugShowCheckedModeBanner: false,
      title: 'Smart Bite',
      theme: ThemeData(
        primaryColor: const Color(0xFF7A232E),
        scaffoldBackgroundColor: const Color(0xFFFAF9F9),
        useMaterial3: true,
      ),
      home: const MealPlanPage(),
    );
  }
}
