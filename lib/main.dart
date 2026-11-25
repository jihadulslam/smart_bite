
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
<<<<<<< HEAD
import 'meal_plan_page.dart';
=======
import 'welcome_page.dart';
import 'notification_service.dart';
import 'app_language.dart';
>>>>>>> 9d9af36bc1b4a4b402bf54cfc145e656589107f1

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.init();
  await AppLang.loadSavedLanguage();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Bite',
      theme: ThemeData(
        primaryColor: const Color(0xFF7A232E),
        scaffoldBackgroundColor: const Color(0xFFFAF9F9),
        useMaterial3: true,
      ),
      home: const MealPlanPage(),
=======
    return ValueListenableBuilder<String>(
      valueListenable: AppLang.current,
      builder: (context, lang, _) {
        return MaterialApp(
          title: 'SmartBite',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const WelcomePage(),
        );
      },
>>>>>>> 9d9af36bc1b4a4b402bf54cfc145e656589107f1
    );
  }
}
