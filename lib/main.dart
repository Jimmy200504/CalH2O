import 'package:calh2o/pages/startup_page/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:camera/camera.dart';
import 'firebase_options.dart';
import 'pages/main_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calh2o/pages/startup_page/login_page.dart';
import 'pages/record_page/image_record.dart';
import 'pages/history_page.dart';
import 'pages/record_page/text_record_2.dart';

late List<CameraDescription> cameras;

Future<void> initializeCameras() async {
  try {
    cameras = await availableCameras();
    if (cameras.isEmpty) {
      debugPrint('No cameras available on this device');
    } else {
      debugPrint('Found ${cameras.length} cameras:');
      for (var camera in cameras) {
        debugPrint(
          'Camera: ${camera.name}, lensDirection: ${camera.lensDirection}',
        );
      }
    }
  } on CameraException catch (e) {
    switch (e.code) {
      case 'CameraAccessDenied':
        debugPrint('Camera access was denied');
        break;
      case 'CameraAccessDeniedWithoutPrompt':
        debugPrint('Camera access was denied without prompt');
        break;
      case 'CameraAccessRestricted':
        debugPrint('Camera access is restricted');
        break;
      default:
        debugPrint('Error getting cameras: ${e.description}');
    }
    cameras = [];
  } catch (e) {
    debugPrint('Error getting cameras: $e');
    cameras = [];
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize cameras
  await initializeCameras();

  // Check user profile
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
    );
  }
}
