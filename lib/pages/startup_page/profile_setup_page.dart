import 'package:calh2o/pages/startup_page/personal_info_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _gender = 'Men';
  String _birthday = '';
  final TextEditingController _birthdayController = TextEditingController();

  final List<String> _genderOptions = ['Men', 'Women', 'Other'];

  @override
  void dispose() {
    _birthdayController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    DateTime initial;
    try {
      initial = DateTime.parse(_birthdayController.text);
    } catch (_) {
      initial = now;
    }
    final dt = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (dt != null) {
      setState(() {
        _birthday =
            '${dt.year.toString().padLeft(4, '0')}'
            '${dt.month.toString().padLeft(2, '0')}'
            '${dt.day.toString().padLeft(2, '0')}';
        _birthdayController.text = _birthday;
      });
    }
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _name);
    await prefs.setString('gender', _gender);
    await prefs.setString('birthday', _birthday);
    final account = prefs.getString('account');
    if (account == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(account).set({
        'name': _name,
        'gender': _gender,
        'birthday': _birthday,
      }, SetOptions(merge: true));

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PersonalInfoPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('資料儲存失敗：$e')));
    }
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.blue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text(""),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset('assets/minion.png', height: 120),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Fill up your\nprofile',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: SingleChildScrollView(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildLabel('Name'),
                          TextFormField(
                            decoration: _inputDecoration('Name'),
                            validator:
                                (val) =>
                                    val == null || val.isEmpty
                                        ? 'Please enter your name'
                                        : null,
                            onSaved: (val) => _name = val!.trim(),
                          ),
                          const SizedBox(height: 16),

                          buildLabel('Gender'),
                          DropdownButtonFormField<String>(
                            value: _gender,
                            decoration: _inputDecoration(''),
                            items:
                                _genderOptions
                                    .map(
                                      (g) => DropdownMenuItem(
                                        value: g,
                                        child: Text(g),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => setState(() => _gender = v!),
                          ),
                          const SizedBox(height: 16),

                          buildLabel('Birthday'),
                          // 只可點 Icon 叫出 Picker，文字框唯讀
                          TextFormField(
                            controller: _birthdayController,
                            readOnly: true,
                            decoration: _inputDecoration('YYYYMMDD').copyWith(
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: _pickBirthday,
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please select your birthday';
                              }
                              if (val.length != 8) {
                                return '請輸入 8 位數 (YYYYMMDD)';
                              }
                              return null;
                            },
                            onSaved:
                                (_) => _birthday = _birthdayController.text,
                          ),
                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: _saveAndContinue,
                              child: const Text(
                                'Continue',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
