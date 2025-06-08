import 'package:calh2o/pages/startup_page/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:camera/camera.dart';
import 'firebase_options.dart';
import 'pages/main_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calh2o/pages/startup_page/login_page.dart';
import 'package:provider/provider.dart';

import 'pages/record_page/image_record.dart';
import 'pages/history_page.dart';

import 'package:calh2o/pages/logo_page.dart';

import 'model/nutrition_draft.dart';
import 'pages/record_page/text_record_page.dart';

late List<CameraDescription> cameras;
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

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

  // Check login status
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(
    ChangeNotifierProvider(
      create: (_) => NutritionDraft(),
      child: MyApp(startFromMainPage: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool startFromMainPage;

  const MyApp({super.key, required this.startFromMainPage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      title: 'CalH2O',
      theme: ThemeData(
        fontFamily: 'Mononoki',
      ),
      initialRoute: startFromMainPage? '/main': '/logo',
      routes: {
        '/logo': (_) => const LogoPage(),
        '/welcome': (_) => const WelcomePage(),
        '/login': (_) => const LoginPage(),
        '/main': (_) => const MainPage(),
        '/image': (_) => const ImageRecordPage(),
        '/text': (_) => const TextRecordPage(),
        '/history': (_) => const HistoryPage(),
      },
    );
  }
}
