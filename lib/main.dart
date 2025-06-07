import 'package:calh2o/pages/startup_page/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/main_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/choose_input_page.dart';
import 'pages/image_record.dart';
import 'pages/text_record.dart';
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
        '/main': (_) => const MainPage(),
        '/choose': (_) => const ChooseInputPage(),
        '/choose/image': (_)  => const ImageRecordPage(),
        '/choose/text': (_)   => const TextRecordPage_2(),
      },
      home: startFromMainPage ? const MainPage() : const WelcomePage(),
    );
  }
}
