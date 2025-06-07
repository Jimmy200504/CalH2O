import 'package:calh2o/pages/startup_page/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/main_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calh2o/pages/startup_page/login_page.dart';
import 'pages/image_record.dart';
import 'pages/text_record.dart';
import 'pages/history_page.dart';
import 'pages/text_record_2.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  final hasProfile = prefs.containsKey('name');

  runApp(MyApp(startFromMainPage: hasProfile));
}

class MyApp extends StatelessWidget {
  final bool startFromMainPage;

  const MyApp({super.key, required this.startFromMainPage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CalH2O',
      initialRoute: '/welcome',
      routes: {
        '/welcome': (_) => const WelcomePage(),
        '/login': (_) => const LoginPage(),
        '/main': (_) => const MainPage(),
        '/image': (_) => const ImageRecordPage(),
        '/text': (_) => const TextRecordPage_2(),
        '/history': (_) => const HistoryPage(),
      },
      home: startFromMainPage ? const MainPage() : const WelcomePage(),
    );
  }
}
