import 'package:calh2o/pages/startup_page/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/main_page.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final prefs = await SharedPreferences.getInstance();
  final hasProfile = prefs.containsKey('name');

//   FirebaseFunctions.instanceFor(
//     region: 'us-central1',
//   ).useFunctionsEmulator('127.0.0.1', 5001);
//   debugPrint('🔧 Connected to Firebase Functions Emulator');

  runApp(MyApp(startFromMainPage: hasProfile));
}

class MyApp extends StatelessWidget {
  final bool startFromMainPage;

  const MyApp({super.key, required this.startFromMainPage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CalH2O',
      home: startFromMainPage ? const MainPage() : const WelcomePage(),
    );
  }
}
