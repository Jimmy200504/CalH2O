import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calh2o/pages/main_page.dart';
import 'package:calh2o/pages/startup_page/profile_setup_page.dart';
import 'package:calh2o/widgets/login_button.dart';
import 'package:calh2o/widgets/keyboard_aware_layout.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String _account = '';
  String _password = '';
  bool _loading = false;
  String getTodayStr() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    // 啟動淡入
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _loading = true);

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_account)
              .get();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('account', _account);

      final todayStr = getTodayStr(); // 取得今天的字串

      if (userDoc.exists) {
        final data = userDoc.data()!;
        if (data['password'] == _password) {
          int comboCount = (data['comboCount'] ?? 0) as int;
          String? lastOpened = data['lastOpened'];

          // 如果今天還沒登入過，combo + 1
          if (lastOpened != todayStr) {
            comboCount += 1;
            await FirebaseFirestore.instance
                .collection('users')
                .doc(_account)
                .update({'comboCount': comboCount, 'lastOpened': todayStr});
          }

          await prefs.setBool('isLoggedIn', true);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainPage()),
          );
        } else {
          _showMessage('Incorrect password');
        }
      } else {
        await FirebaseFirestore.instance.collection('users').doc(_account).set({
          'password': _password,
          'comboCount': 0,
          'lastOpened': todayStr,
        });

        _showMessage('Account created. Please complete your profile.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileSetupPage()),
        );
      }
    } catch (e) {
      _showMessage('Login failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // 統一輸入框樣式
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.black, width: 2), // 品牌色
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: KeyboardAwareLayout(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Spacer(),
                    const Text(
                      'Login to CalH2O',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      decoration: _inputDecoration('Username'),
                      onSaved: (value) => _account = value!.trim(),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Enter username'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: _inputDecoration('Password'),
                      obscureText: true,
                      onSaved: (value) => _password = value!.trim(),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Enter password'
                                  : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child:
                          _loading
                              ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFFB74D), // 這裡用品牌色
                                ),
                              )
                              : LoginButton(
                                text: 'Login',
                                onPressed: _handleLogin,
                                width: double.infinity,
                                height: 56,
                              ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
