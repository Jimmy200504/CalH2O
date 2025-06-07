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
                                (value) =>
                                    value == null || value.isEmpty
                                        ? 'Please enter your name'
                                        : null,
                            onSaved: (value) => _name = value!,
                          ),
                          const SizedBox(height: 16),

                          buildLabel('Gender'),
                          DropdownButtonFormField<String>(
                            value: _gender,
                            decoration: _inputDecoration(''),
                            items:
                                _genderOptions.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _gender = newValue!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          buildLabel('Birthday'),
                          TextFormField(
                            controller: _birthdayController,
                            decoration: _inputDecoration('YYYYMMDD'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(8),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your birthday';
                              }
                              if (value.length != 8) {
                                return 'Please enter 8 digits (YYYYMMDD)';
                              }
                              return null;
                            },
                            onSaved: (value) => _birthday = value!,
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
                              onPressed: () async {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();

                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setString('name', _name);
                                  await prefs.setString('gender', _gender);
                                  await prefs.setString('birthday', _birthday);

                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(_name)
                                        .set({
                                          'name': _name,
                                          'gender': _gender,
                                          'birthday': _birthday,
                                        }, SetOptions(merge: true));

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                const PersonalInfoPage(),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('資料儲存失敗：$e')),
                                    );
                                  }
                                }
                              },
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
}
