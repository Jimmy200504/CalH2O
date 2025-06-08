import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calh2o/pages/main_page.dart';
import 'package:calh2o/pages/startup_page/profile_setup_page.dart'; // 輸入個人資料頁面

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _account = '';
  String _password = '';
  bool _loading = false;

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

      if (userDoc.exists) {
        final data = userDoc.data()!;
        if (data['password'] == _password) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Spacer(),
                const Text(
                  'Login to CalH2O',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  autofillHints: null,
                  enableSuggestions: false,
                  autocorrect: false,
                  onSaved: (value) => _account = value!.trim(),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Enter username'
                              : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  autofillHints: null,
                  enableSuggestions: false,
                  autocorrect: false,
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
                  child:
                      _loading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}