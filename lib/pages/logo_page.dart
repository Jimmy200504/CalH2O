import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:calh2o/pages/startup_page/welcome_page.dart';

class LogoPage extends StatefulWidget {
  const LogoPage({super.key});

  @override
  State<LogoPage> createState() => _LogoPageState();
}

class _LogoPageState extends State<LogoPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _textAnimationFinished = false;

  @override
  void initState() {
    super.initState();

    // 初始化淡出動畫
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _startFadeOutAndNavigate() async {
    await _fadeController.forward();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _textAnimationFinished
            ? FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'CalH2O',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFB74D),
                  ),
                ),
              )
            : AnimatedTextKit(
                animatedTexts: [
                  TyperAnimatedText(
                    'CalH2O',
                    textStyle: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFB74D),
                    ),
                    speed: const Duration(milliseconds: 100),
                  ),
                ],
                isRepeatingAnimation: false,
                onFinished: () {
                  setState(() => _textAnimationFinished = true);
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _startFadeOutAndNavigate();
                  });
                },
              ),
      ),
    );
  }
}
