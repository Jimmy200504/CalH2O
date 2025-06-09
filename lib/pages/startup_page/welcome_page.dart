import 'package:flutter/material.dart';
import 'package:calh2o/pages/startup_page/login_page.dart';
import 'package:calh2o/widgets/button_or_other_modifications/next_button.dart';


class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    // 頁面一開始就開始淡入
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _handleNextPressed() async {
    // 開始淡出
    await _fadeController.reverse();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),
                const Text(
                  'Welcome to \nCalH2O',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.local_cafe_outlined, size: 32),
                    SizedBox(width: 16),
                    Icon(Icons.edit_outlined, size: 32),
                    SizedBox(width: 16),
                    Icon(Icons.flag_outlined, size: 32),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'It is a simple and emotionally\nengaging app that makes it\neasy to log meals and water\nintake.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                SizedBox(
                  width: 200,
                  child: NextButton(
                    text: 'Start',
                    onPressed: _handleNextPressed,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
