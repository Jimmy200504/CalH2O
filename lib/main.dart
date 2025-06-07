import 'package:calh2o/pages/startup_page/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:camera/camera.dart';
import 'firebase_options.dart';
import 'pages/main_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/record_page/image_record.dart';
import 'pages/record_page/text_record.dart';
import 'pages/record_page/text_record_2.dart';

late List<CameraDescription> cameras;

Future<void> initializeCameras() async {
  try {
    cameras = await availableCameras();
    if (cameras.isEmpty) {
      debugPrint('No cameras available');
    } else {
      debugPrint('Found ${cameras.length} cameras');
    }
  } on CameraException catch (e) {
    debugPrint('Error getting cameras: $e');
    cameras = [];
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeCameras();

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
      initialRoute: '/main',
      routes: {
        '/welcome': (_) => const WelcomePage(),
        '/main': (_) => const MainPage(),
        '/image': (_) => const ImageRecordPage(),
        '/text': (_) => const TextRecordPage_2(),
      },
      home: startFromMainPage ? const MainPage() : const WelcomePage(),
    );
  }
}
